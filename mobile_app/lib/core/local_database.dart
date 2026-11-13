import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/parcela.dart';
import '../models/registro.dart';
import 'agronomia_service.dart';

class LocalDatabase {
  static const _dbName = 'raiz_azul.db';
  static const _dbVersion = 3;
  static Database? _database;
  static Future<Database>? _opening;
  
  // Table names
  static const String tableParcelas = 'parcelas';
  static const String tableRegistros = 'registros';
  static const String tableSyncQueue = 'sync_queue';
  static const String tableFincas = 'fincas';
  static const String tableCultivos = 'cultivos';
  static const String tableZonas = 'zonas';
  
  // Singleton
  static final LocalDatabase _instance = LocalDatabase._internal();
  factory LocalDatabase() => _instance;
  LocalDatabase._internal();
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    return _opening ??= _openDatabase();
  }

  Future<Database> _openDatabase() async {
    try {
      final db = await _initDb();
      _database = db;
      return db;
    } finally {
      // Permite reintentar si la apertura falló.
      _opening = null;
    }
  }
  
  Future<Database> _initDb() async {
    try {
      final dbPath = await _databaseDirectory();
      final path = join(dbPath, _dbName);
      
      return await openDatabase(
        path,
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e, stack) {
      debugPrint('LocalDatabase: no se pudo abrir la base local: $e\n$stack');
      rethrow;
    }
  }

  Future<String> _databaseDirectory() async {
    // En escritorio conviene una ruta estable de la app (AppData en Windows)
    // en lugar del directorio de trabajo desde donde se ejecute el binario.
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux)) {
      final dir = await getApplicationSupportDirectory();
      return dir.path;
    }
    return getDatabasesPath();
  }
  
  Future<void> _onCreate(Database db, int version) async {
    // Fincas
    await db.execute('''
      CREATE TABLE $tableFincas (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        zona TEXT,
        sync_status INTEGER DEFAULT 0, -- 0=synced, 1=pending, 2=conflict
        updated_at INTEGER DEFAULT (strftime('%s', 'now'))
      )
    ''');
    
    // Cultivos
    await db.execute('''
      CREATE TABLE $tableCultivos (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        dias_ciclo INTEGER,
        sync_status INTEGER DEFAULT 0
      )
    ''');
    
    // Zonas
    await db.execute('''
      CREATE TABLE $tableZonas (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        sync_status INTEGER DEFAULT 0
      )
    ''');
    
    // Parcelas
    await db.execute('''
      CREATE TABLE $tableParcelas (
        id INTEGER PRIMARY KEY,
        id_finca INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        finca TEXT,
        zona TEXT,
        cultivo TEXT,
        area REAL NOT NULL,
        siembra TEXT NOT NULL,
        cosechada INTEGER DEFAULT 0,
        id_cultivo INTEGER,
        id_zona INTEGER,
        sync_status INTEGER DEFAULT 0, -- 0=synced, 1=pending_create, 2=pending_update, 3=pending_delete
        server_id INTEGER, -- ID from server after sync
        updated_at INTEGER DEFAULT (strftime('%s', 'now')),
        FOREIGN KEY (id_finca) REFERENCES $tableFincas (id)
      )
    ''');
    
    // Registros
    await db.execute('''
      CREATE TABLE $tableRegistros (
        id INTEGER PRIMARY KEY,
        id_parcela INTEGER,
        id_finca INTEGER NOT NULL,
        tipo TEXT NOT NULL, -- 'riego', 'lluvia', 'insumo', 'labor'
        fecha TEXT NOT NULL,
        valor REAL NOT NULL,
        detalle TEXT,
        nota TEXT,
        metodo_riego TEXT,
        duracion_minutos INTEGER,
        grupo_riego TEXT,
        autor TEXT,
        destino TEXT,
        sync_status INTEGER DEFAULT 0, -- 0=synced, 1=pending_create, 2=pending_update, 3=pending_delete
        server_id INTEGER,
        updated_at INTEGER DEFAULT (strftime('%s', 'now')),
        FOREIGN KEY (id_parcela) REFERENCES $tableParcelas (id),
        FOREIGN KEY (id_finca) REFERENCES $tableFincas (id)
      )
    ''');
    
    // Sync Queue - operations pending to sync
    await db.execute('''
      CREATE TABLE $tableSyncQueue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL, -- 'parcelas', 'registros', 'fincas'
        operation TEXT NOT NULL, -- 'create', 'update', 'delete'
        local_id INTEGER NOT NULL, -- Local record ID
        server_id INTEGER, -- Server record ID (if exists)
        payload TEXT NOT NULL, -- JSON of the data
        priority INTEGER DEFAULT 1, -- 1=high, 2=normal, 3=low
        retry_count INTEGER DEFAULT 0,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        last_attempt_at INTEGER
      )
    ''');
    
    // Indexes for performance
    await db.execute('CREATE INDEX idx_parcelas_sync ON $tableParcelas(sync_status)');
    await db.execute('CREATE INDEX idx_registros_sync ON $tableRegistros(sync_status)');
    await db.execute('CREATE INDEX idx_sync_queue_status ON $tableSyncQueue(priority, created_at)');
    
    // Seed initial catalogs
    await _seedCatalogs(db);
  }
  
  Future<void> _seedCatalogs(Database db) async {
    // Cultivos
    final cultivos = [
      {'id': 1, 'nombre': 'Tomate', 'dias_ciclo': 120},
      {'id': 2, 'nombre': 'Chile', 'dias_ciclo': 150},
      {'id': 3, 'nombre': 'Repollo', 'dias_ciclo': 90},
      {'id': 4, 'nombre': 'Maíz', 'dias_ciclo': 120},
      {'id': 5, 'nombre': 'Frijol', 'dias_ciclo': 90},
    ];
    
    for (final c in cultivos) {
      await db.insert(tableCultivos, c, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    
    // Zonas
    final zonas = [
      {'id': 1, 'nombre': 'Matagalpa'},
      {'id': 2, 'nombre': 'Jinotega'},
      {'id': 3, 'nombre': 'Chontales'},
    ];
    
    for (final z in zonas) {
      await db.insert(tableZonas, z, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    
    // Fincas de ejemplo
    final fincas = [
      {'id': 1, 'nombre': 'La Esperanza', 'zona': 'Matagalpa'},
      {'id': 2, 'nombre': 'El Mirador', 'zona': 'Jinotega'},
    ];
    
    for (final f in fincas) {
      await db.insert(tableFincas, f, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _addColumnIfMissing(db, tableRegistros, 'metodo_riego', 'TEXT');
      await _addColumnIfMissing(db, tableRegistros, 'duracion_minutos', 'INTEGER');
      await _addColumnIfMissing(db, tableRegistros, 'grupo_riego', 'TEXT');
    }
    if (oldVersion < 3) {
      // El servidor envía `destino` (Parcela/Finca) en los registros.
      await _addColumnIfMissing(db, tableRegistros, 'destino', 'TEXT');
    }
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String type,
  ) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final exists = info.any((c) => c['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }
  
  // ==================== PARCELAS ====================
  
  Future<int> insertParcela(Map<String, dynamic> parcela) async {
    final db = await database;
    final id = await db.insert(tableParcelas, {
      ...parcela,
      'sync_status': 1, // pending_create
      'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
    await _addToSyncQueue(tableParcelas, 'create', id, parcela);
    return id;
  }
  
  Future<int> updateParcela(int id, Map<String, dynamic> parcela) async {
    final db = await database;
    final result = await db.update(
      tableParcelas,
      {
        ...parcela,
        'sync_status': 2, // pending_update
        'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result > 0) {
      await _addToSyncQueue(tableParcelas, 'update', id, {...parcela, 'id': id});
    }
    return result;
  }
  
  Future<int> deleteParcela(int id) async {
    final db = await database;
    // Get server_id before deleting
    final parcela = await db.query(
      tableParcelas,
      columns: ['server_id'],
      where: 'id = ?',
      whereArgs: [id],
    );
    
    final serverId = parcela.isNotEmpty ? parcela.first['server_id'] as int? : null;
    
    // Soft delete - mark as pending_delete
    final result = await db.update(
      tableParcelas,
      {
        'sync_status': 3, // pending_delete
        'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (result > 0) {
      await _addToSyncQueue(tableParcelas, 'delete', id, {'id': id, 'server_id': serverId});
    }
    return result;
  }
  
  /// Completa los campos derivados (ciclo, día, etapa, cosecha estimada) que
  /// no se guardan en la tabla local, para que el modo offline los muestre
  /// siempre actualizados.
  Map<String, dynamic> _withEtapa(Map<String, dynamic> map) {
    try {
      final etapa = AgronomiaService.calcularEtapa(
        (map['cultivo'] as String?) ?? 'Maíz',
        (map['siembra'] as String?) ?? '',
      );
      map['ciclo_dias'] = etapa['ciclo'];
      map['dias_desde_siembra'] = etapa['dias'];
      map['fecha_estimada_cosecha'] = etapa['fechaCosechaEstimada'];
      map['porcentaje_ciclo'] = (etapa['pct'] as num) * 100;
      map['etapa_actual'] = etapa['etapa'];
    } catch (_) {
      // Si el cultivo o la fecha vienen raros, se usan los valores por defecto.
    }
    return map;
  }

  Future<List<Parcela>> getParcelas({int? idFinca}) async {
    final db = await database;
    final where = idFinca != null ? 'id_finca = ?' : null;
    final whereArgs = idFinca != null ? [idFinca] : null;
    
    final maps = await db.query(
      tableParcelas,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'nombre ASC',
    );
    
    return maps
        .map((m) => Parcela.fromLocalMap(_withEtapa(Map<String, dynamic>.from(m))))
        .toList();
  }
  
  Future<Parcela?> getParcela(int id) async {
    final db = await database;
    final maps = await db.query(
      tableParcelas,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Parcela.fromLocalMap(_withEtapa(Map<String, dynamic>.from(maps.first)));
  }
  
  // ==================== REGISTROS ====================
  
  Future<int> insertRegistro(Map<String, dynamic> registro) async {
    final db = await database;
    final id = await db.insert(tableRegistros, {
      ...registro,
      'sync_status': 1, // pending_create
      'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
    await _addToSyncQueue(tableRegistros, 'create', id, registro);
    return id;
  }
  
  Future<int> updateRegistro(int id, Map<String, dynamic> registro) async {
    final db = await database;
    final result = await db.update(
      tableRegistros,
      {
        ...registro,
        'sync_status': 2, // pending_update
        'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result > 0) {
      await _addToSyncQueue(tableRegistros, 'update', id, {...registro, 'id': id});
    }
    return result;
  }
  
  Future<int> deleteRegistro(int id) async {
    final db = await database;
    final registro = await db.query(
      tableRegistros,
      columns: ['server_id'],
      where: 'id = ?',
      whereArgs: [id],
    );
    
    final serverId = registro.isNotEmpty ? registro.first['server_id'] as int? : null;
    
    final result = await db.update(
      tableRegistros,
      {
        'sync_status': 3, // pending_delete
        'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (result > 0) {
      await _addToSyncQueue(tableRegistros, 'delete', id, {'id': id, 'server_id': serverId});
    }
    return result;
  }
  
  Future<List<Registro>> getRegistros({int? idParcela, int? idFinca}) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;
    
    if (idParcela != null && idFinca != null) {
      where = 'id_parcela = ? AND id_finca = ?';
      whereArgs = [idParcela, idFinca];
    } else if (idParcela != null) {
      where = 'id_parcela = ?';
      whereArgs = [idParcela];
    } else if (idFinca != null) {
      where = 'id_finca = ?';
      whereArgs = [idFinca];
    }
    
    final maps = await db.query(
      tableRegistros,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'fecha DESC, id DESC',
    );
    
    return maps.map((m) => Registro.fromLocalMap(m)).toList();
  }

  Future<Registro?> getRegistro(int id) async {
    final db = await database;
    final maps = await db.query(
      tableRegistros,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Registro.fromLocalMap(maps.first);
  }
  
  // ==================== SYNC QUEUE ====================
  
  Future<void> _addToSyncQueue(
    String tableName,
    String operation,
    int localId,
    Map<String, dynamic> payload,
  ) async {
    final db = await database;
    
    // Don't queue delete operations for records that were never synced
    if (operation == 'delete') {
      final existing = await db.query(
        tableName,
        columns: ['server_id'],
        where: 'id = ?',
        whereArgs: [localId],
      );
      if (existing.isNotEmpty && (existing.first['server_id'] as int?) == null) {
        // Never synced, just hard delete
        await db.delete(tableName, where: 'id = ?', whereArgs: [localId]);
        return;
      }
    }
    
    await db.insert(tableSyncQueue, {
      'table_name': tableName,
      'operation': operation,
      'local_id': localId,
      'server_id': payload['server_id'],
      'payload': jsonEncode(payload),
      'priority': operation == 'create' ? 1 : 2,
    });
  }
  
  Future<List<Map<String, dynamic>>> getPendingSync() async {
    final db = await database;
    return await db.query(
      tableSyncQueue,
      orderBy: 'priority ASC, created_at ASC',
    );
  }
  
  Future<void> markSyncSuccess(int queueId, int serverId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Update the queue item
      await txn.delete(tableSyncQueue, where: 'id = ?', whereArgs: [queueId]);
      
      // Update the record's sync_status and server_id
      // This will be handled by the sync service after getting server response
    });
  }
  
  Future<void> markSyncFailed(int queueId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE $tableSyncQueue SET retry_count = retry_count + 1, last_attempt_at = ? WHERE id = ?',
      [DateTime.now().millisecondsSinceEpoch ~/ 1000, queueId],
    );
  }
  
  Future<void> removeFromSyncQueue(int queueId) async {
    final db = await database;
    await db.delete(tableSyncQueue, where: 'id = ?', whereArgs: [queueId]);
  }
  
  Future<int> getPendingCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableSyncQueue');
    return Sqflite.firstIntValue(result) ?? 0;
  }
  
  // ==================== SYNC HELPERS ====================
  
  Future<void> updateRecordAfterSync(
    String tableName,
    int localId,
    int serverId,
    int syncStatus,
  ) async {
    final db = await database;
    await db.update(
      tableName,
      {
        'server_id': serverId,
        'sync_status': syncStatus, // 0 = synced
        'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
  }
  
  Future<void> clearSyncedRecords() async {
    final db = await database;
    await db.delete(tableParcelas, where: 'sync_status = 0');
    await db.delete(tableRegistros, where: 'sync_status = 0');
  }
  
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Abre (o crea) la base local de forma controlada.
  /// Devuelve `false` si SQLite no está disponible en la plataforma.
  Future<bool> initialize() async {
    try {
      await database;
      return true;
    } catch (_) {
      return false;
    }
  }
}