import 'package:sqflite/sqflite.dart';
import 'api_service.dart';
import 'local_database.dart';
import 'agronomia_service.dart';
import '../models/parcela.dart';
import '../models/registro.dart';
import '../models/alerta.dart';
import '../models/evento.dart';

class OfflineApiService {
  final ApiService _api = ApiService();
  final LocalDatabase _localDb = LocalDatabase();
  
  OfflineApiService._();
  static final OfflineApiService _instance = OfflineApiService._();
  factory OfflineApiService() => _instance;
  
  // ==================== DASHBOARD ====================
  
  Future<Map<String, dynamic>> fetchDashboard() async {
    // Try online first
    try {
      final result = await _api.fetchDashboard();
      if (result['driver'] != 'desconectado') {
        return result;
      }
    } catch (_) {}
    
    // Fallback to local
    return _buildLocalDashboard();
  }
  
  Future<Map<String, dynamic>> _buildLocalDashboard() async {
    final parcelas = await _localDb.getParcelas();
    final registros = await _localDb.getRegistros();
    
    // Calculate stats from local data
    int totalParcelas = parcelas.length;
    double litros7Dias = 0;
    int totalAlertas = 0;
    double ahorroAgua = 0;
    List<Alerta> alertas = [];
    List<Registro> actividad = registros.take(7).toList();
    
    final ahora = DateTime.now();
    final hace7Dias = ahora.subtract(const Duration(days: 7));
    
    // Litros regados en últimos 7 días
    for (final r in registros) {
      final fecha = DateTime.tryParse(r.fecha);
      if (r.tipo == 'riego' && fecha != null && fecha.isAfter(hace7Dias) && fecha.isBefore(ahora)) {
        litros7Dias += r.valor;
      }
    }
    
    // Calcular alertas y ahorro usando lógica agronómica local
    for (final p in parcelas) {
      final recs = AgronomiaService.calcularRecomendaciones(p, registros);
      for (final rec in recs) {
        if (rec['nivel'] != 'ok') {
          alertas.add(Alerta.fromMap({
            ...rec,
            'parcelaId': p.id,
            'parcelaNombre': p.nombre,
            'cultivo': p.cultivo,
          }));
          totalAlertas++;
        }
      }
    }
    
    // Riegos potencialmente evitables (riego dentro de 2 días después de lluvia >= 20mm)
    final lluviasFuertes = registros.where((r) => r.tipo == 'lluvia' && r.valor >= 20).toList();
    for (final r in registros) {
      if (r.tipo == 'riego') {
        final fRiego = DateTime.tryParse(r.fecha);
        if (fRiego == null) continue;
        
        for (final ll in lluviasFuertes) {
          final fLluvia = DateTime.tryParse(ll.fecha);
          if (fLluvia == null) continue;
          
          final match = (r.parcelaId == ll.parcelaId) || 
                       (r.idFinca == ll.idFinca && r.idFinca != null);
          
          if (match) {
            final diff = fRiego.difference(fLluvia).inDays;
            if (diff >= 0 && diff <= 2) {
              ahorroAgua += r.valor;
              break;
            }
          }
        }
      }
    }
    
    // Ordenar alertas por prioridad
    final prioridad = {'alerta': 0, 'info': 1, 'ok': 2};
    alertas.sort((a, b) => (prioridad[a.nivel] ?? 3).compareTo(prioridad[b.nivel] ?? 3));
    
    return {
      'totalParcelas': totalParcelas,
      'litrosRegados7Dias': litros7Dias,
      'totalAlertas': totalAlertas,
      'ahorroPotencialLitros': ahorroAgua,
      'alertas': alertas,
      'actividadReciente': actividad,
      'isSqlServer': false,
      'driver': 'local_sqlite',
    };
  }
  
  // ==================== PARCELAS ====================
  
  Future<List<Parcela>> fetchParcelas({int? idFinca}) async {
    // Try online first
    try {
      final serverParcelas = await _api.fetchParcelas();
      if (serverParcelas.isNotEmpty) {
        // Merge with local (local takes precedence for pending changes)
        await _mergeParcelas(serverParcelas);
      }
    } catch (_) {}
    
    // Return local
    return _localDb.getParcelas(idFinca: idFinca);
  }
  
  Future<void> _mergeParcelas(List<Parcela> serverParcelas) async {
    for (final sp in serverParcelas) {
      final local = await _localDb.getParcela(sp.id as int);
      if (local == null || local.syncStatus == 0) {
        // No local version or local is synced - update from server
        await _localDb.database.then((db) => db.insert(
          LocalDatabase.tableParcelas,
          {
            'id': sp.id,
            'id_finca': sp.idFinca,
            'nombre': sp.nombre,
            'finca': sp.finca,
            'zona': sp.zona,
            'cultivo': sp.cultivo,
            'area': sp.area,
            'siembra': sp.siembra,
            'cosechada': sp.cosechada ? 1 : 0,
            'ciclo_dias': sp.cicloDias,
            'dias_desde_siembra': sp.diasDesdeSiembra,
            'fecha_estimada_cosecha': sp.fechaEstimadaCosecha,
            'porcentaje_ciclo': sp.porcentajeCiclo,
            'etapa_actual': sp.etapaActual,
            'sync_status': 0,
            'server_id': sp.id,
            'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        ));
      }
    }
  }
  
  Future<({bool success, String message})> crearParcela({
    required String nombre,
    required String finca,
    required String zona,
    required String cultivo,
    required double area,
    required String siembra,
  }) async {
    // Try online
    try {
      final result = await _api.crearParcela(
        nombre: nombre, finca: finca, zona: zona,
        cultivo: cultivo, area: area, siembra: siembra,
      );
      if (result.success) {
        return result;
      }
    } catch (_) {}
    
    // Offline - save to local DB
    final newId = await _localDb.insertParcela({
      'nombre': nombre,
      'id_finca': 1, // TODO: resolve finca name to ID
      'finca': finca,
      'zona': zona,
      'cultivo': cultivo,
      'area': area,
      'siembra': siembra,
      'cosechada': 0,
      'sync_status': 1, // pending_create
    });
    
    return (success: true, message: 'Parcela guardada localmente (se sincronizará al conectar). ID local: $newId');
  }
  
  Future<bool> eliminarParcela(dynamic id) async {
    try {
      await _api.eliminarParcela(id);
    } catch (_) {}
    
    // Always delete locally (soft delete for sync)
    await _localDb.deleteParcela(id as int);
    return true;
  }
  
  // ==================== REGISTROS ====================
  
  Future<List<Registro>> fetchRegistros({dynamic idParcela}) async {
    try {
      final serverRegistros = await _api.fetchRegistros(idParcela: idParcela);
      if (serverRegistros.isNotEmpty) {
        await _mergeRegistros(serverRegistros);
      }
    } catch (_) {}
    
    return _localDb.getRegistros(
      idParcela: idParcela is int ? idParcela : null,
    );
  }
  
  Future<void> _mergeRegistros(List<Registro> serverRegistros) async {
    final db = await _localDb.database;

    for (final sr in serverRegistros) {
      final datos = {
        'id_finca': sr.idFinca,
        'id_parcela': sr.parcelaId,
        'tipo': sr.tipo,
        'fecha': sr.fecha,
        'valor': sr.valor,
        'detalle': sr.detalle,
        'nota': sr.nota,
        'metodo_riego': sr.metodoRiego,
        'duracion_minutos': sr.duracionMinutos,
        'grupo_riego': sr.grupoRiego,
        'autor': sr.autor,
        'destino': sr.destino,
        'sync_status': 0,
        'server_id': sr.id,
        'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };

      // Buscar por server_id para no pisar registros locales pendientes
      // que todavía no tienen ID del servidor.
      final existentes = await db.query(
        LocalDatabase.tableRegistros,
        columns: ['id'],
        where: 'server_id = ?',
        whereArgs: [sr.id],
      );

      if (existentes.isNotEmpty) {
        await db.update(
          LocalDatabase.tableRegistros,
          datos,
          where: 'id = ?',
          whereArgs: [existentes.first['id']],
        );
      } else {
        await db.insert(LocalDatabase.tableRegistros, datos);
      }
    }
  }
  
  Future<({bool success, String message})> crearRegistro({
    dynamic idParcela,
    dynamic idFinca = 1,
    required String tipo,
    required String fecha,
    required double valor,
    String detalle = '',
    String nota = '',
    required String autor,
    List<String>? fechas,
    String? metodoRiego,
    int? duracionMinutos,
    String? grupoRiego,
  }) async {
    final listaFechas = <String>{
      ...(fechas == null || fechas.isEmpty ? [fecha] : fechas),
    }.toList()
      ..sort();

    // Try online
    try {
      final result = await _api.crearRegistro(
        idParcela: idParcela,
        idFinca: idFinca,
        tipo: tipo,
        fecha: listaFechas.first,
        valor: valor,
        detalle: detalle,
        nota: nota,
        autor: autor,
        fechas: listaFechas,
        metodoRiego: metodoRiego,
        duracionMinutos: duracionMinutos,
        grupoRiego: grupoRiego,
      );
      if (result.success) {
        return result;
      }
    } catch (_) {}
    
    // Offline - save to local DB
    for (final f in listaFechas) {
      await _localDb.insertRegistro({
        'id_parcela': idParcela,
        'id_finca': idFinca,
        'tipo': tipo,
        'fecha': f,
        'valor': valor,
        'detalle': detalle,
        'nota': nota,
        'metodo_riego': metodoRiego,
        'duracion_minutos': duracionMinutos,
        'grupo_riego': grupoRiego,
        'autor': autor,
        'destino': 'Parcela', // Will be resolved later
        'sync_status': 1,
      });
    }
    
    final mensaje = listaFechas.length > 1
        ? 'Se guardaron ${listaFechas.length} registros localmente (se sincronizarán al conectar)'
        : 'Registro guardado localmente (se sincronizará al conectar)';
    return (success: true, message: mensaje);
  }
  
  Future<bool> eliminarRegistro(dynamic id) async {
    try {
      await _api.eliminarRegistro(id);
    } catch (_) {}
    
    await _localDb.deleteRegistro(id as int);
    return true;
  }
  
  // ==================== CATALOGOS ====================
  
  Future<Map<String, dynamic>> fetchCatalogos() async {
    try {
      return await _api.fetchCatalogos();
    } catch (_) {}
    
    // Return cached/empty
    return {
      'cultivos': [
        {'id': 1, 'nombre': 'Tomate'},
        {'id': 2, 'nombre': 'Chile'},
        {'id': 3, 'nombre': 'Repollo'},
        {'id': 4, 'nombre': 'Maíz'},
        {'id': 5, 'nombre': 'Frijol'},
      ],
      'zonas': [
        {'id': 1, 'nombre': 'Matagalpa'},
        {'id': 2, 'nombre': 'Jinotega'},
        {'id': 3, 'nombre': 'Chontales'},
      ],
      'fincas': [
        {'id': 1, 'nombre': 'La Esperanza'},
        {'id': 2, 'nombre': 'El Mirador'},
      ],
    };
  }
  
  // ==================== CALENDARIO ====================
  
  Future<List<EventoCalendario>> fetchCalendario() async {
    try {
      return await _api.fetchCalendario();
    } catch (_) {}
    return [];
  }
  
  // ==================== REPORTES ====================
  
  Future<Map<String, dynamic>> fetchReportes() async {
    try {
      final result = await _api.fetchReportes();
      if (result.isNotEmpty) {
        return result;
      }
    } catch (_) {}
    // Fallback to local calculation
    return _buildLocalReportes();
  }
  
  Future<Map<String, dynamic>> _buildLocalReportes() async {
    final parcelas = await _localDb.getParcelas();
    final registros = await _localDb.getRegistros();
    
    final List<Map<String, dynamic>> reporteParcelas = [];
    double totalAguaRiego = 0;
    double totalLluviaAcum = 0;
    
    for (final p in parcelas) {
      final pid = p.id;
      final finca = p.finca;
      final area = p.area;
      final siembra = p.siembra;
      final cultivo = p.cultivo;
      
      // Registros correspondientes al ciclo (desde siembra)
      int riegos = 0;
      double litros = 0;
      double insumos = 0;
      int labores = 0;
      
      for (final r in registros) {
        if (r.parcelaId == pid && DateTime.tryParse(r.fecha)?.isAfter(DateTime.tryParse(siembra) ?? DateTime.now()) == true) {
          if (r.tipo == 'riego') {
            riegos++;
            litros += r.valor;
          } else if (r.tipo == 'insumo') {
            insumos += r.valor;
          } else if (r.tipo == 'labor') {
            labores++;
          }
        }
      }
      
      // Lluvias de la parcela o de la finca general
      double lluviaMm = 0;
      for (final r in registros) {
        if (r.tipo == 'lluvia' && 
            DateTime.tryParse(r.fecha)?.isAfter(DateTime.tryParse(siembra) ?? DateTime.now()) == true &&
            (r.parcelaId == pid || r.destino.contains(finca))) {
          lluviaMm += r.valor;
        }
      }
      
      final litrosPorMz = area > 0 ? (litros / area) : 0;
      totalAguaRiego += litros;
      totalLluviaAcum += lluviaMm;
      
      reporteParcelas.add({
        'id': pid,
        'nombre': p.nombre,
        'cultivo': cultivo,
        'finca': finca,
        'zona': p.zona,
        'areaManzanas': area,
        'fechaSiembra': siembra,
        'numRiegos': riegos,
        'litrosRiego': litros,
        'litrosPorManzana': litrosPorMz,
        'lluviaAcumuladaMm': lluviaMm,
        'insumosLb': insumos,
        'totalLabores': labores,
      });
    }
    
    // Ordenar parcelas por consumo de agua por manzana descendente
    reporteParcelas.sort((a, b) => (b['litrosPorManzana'] as double).compareTo(a['litrosPorManzana'] as double));
    
    // Calcular ahorro potencial (riego evitable)
    final dashboard = await fetchDashboard();
    final ahorro = dashboard['ahorroPotencialLitros'] ?? 0;
    final promedioLluvia = parcelas.isNotEmpty ? totalLluviaAcum / parcelas.length : 0;
    
    return {
      'totalAguaRiego': totalAguaRiego,
      'lluviaPromedioMm': promedioLluvia,
      'ahorroPotencialLitros': ahorro,
      'parcelas': reporteParcelas,
    };
  }
  
  // ==================== CONNECTION CHECK ====================
  
  Future<bool> checkConnection() async {
    return _api.checkConnection();
  }
}