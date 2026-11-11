import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../core/local_database.dart';
import '../core/constants.dart';
import '../core/secure_storage.dart';

class SyncService extends ChangeNotifier {
  static const _maxRetries = 3;
  
  final LocalDatabase _localDb = LocalDatabase();
  bool _isSyncing = false;
  int _pendingCount = 0;
  String? _lastError;
  DateTime? _lastSyncTime;
  bool _lastSyncSuccess = false;
  
  bool get isSyncing => _isSyncing;
  int get pendingCount => _pendingCount;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get lastSyncSuccess => _lastSyncSuccess;
  
  SyncService() {
    _loadPendingCount();
  }
  
  Future<void> _loadPendingCount() async {
    _pendingCount = await _localDb.getPendingCount();
  }
  
  Future<void> syncNow({bool force = false}) async {
    if (_isSyncing && !force) return;
    
    final token = await SecureStorage.getAccessToken();
    if (token == null) {
      _lastError = 'No hay sesión activa';
      notifyListeners();
      return;
    }
    
    _isSyncing = true;
    _lastError = null;
    notifyListeners();
    
    try {
      final pending = await _localDb.getPendingSync();
      _pendingCount = pending.length;
      
      if (pending.isEmpty) {
        _lastSyncTime = DateTime.now();
        _lastSyncSuccess = true;
        _isSyncing = false;
        return;
      }
      
      for (final item in pending) {
        if (!_isSyncing) break; // Allow cancellation
        
        try {
          await _processSyncItem(item, token);
        } catch (e) {
          await _localDb.markSyncFailed(item['id'] as int);
          _lastError = 'Error sincronizando: $e';
        }
      }
      
      _pendingCount = await _localDb.getPendingCount();
      _lastSyncTime = DateTime.now();
      _lastSyncSuccess = _pendingCount == 0;
    } catch (e) {
      _lastError = 'Error de sincronización: $e';
      _lastSyncSuccess = false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
  
  Future<void> _processSyncItem(Map<String, dynamic> item, String token) async {
    final queueId = item['id'] as int;
    final tableName = item['table_name'] as String;
    final operation = item['operation'] as String;
    final localId = item['local_id'] as int;
    final serverId = item['server_id'] as int?;
    final payloadStr = item['payload'] as String;
    final retryCount = item['retry_count'] as int? ?? 0;
    
    if (retryCount >= _maxRetries) {
      await _localDb.removeFromSyncQueue(queueId);
      return;
    }
    
    // Parse payload - stored as toString(), need to parse
    // For simplicity, we'll reconstruct from local DB
    Map<String, dynamic> payload;
    if (tableName == 'parcelas') {
      final parcela = await _localDb.getParcela(localId);
      if (parcela == null) {
        await _localDb.removeFromSyncQueue(queueId);
        return;
      }
      payload = parcela.toServerMap();
    } else if (tableName == 'registros') {
      final registro = await _localDb.getRegistro(localId);
      if (registro == null) {
        await _localDb.removeFromSyncQueue(queueId);
        return;
      }
      payload = registro.toServerMap();
    } else {
      payload = _parsePayload(payloadStr);
    }
    
    final uri = _buildUri(tableName, operation, serverId);
    final response = await _makeRequest(uri, operation, payload, token);
    
    if (response.success) {
      await _handleSyncSuccess(queueId, tableName, localId, operation, response.data);
    } else {
      throw Exception(response.message);
    }
  }
  
  Map<String, dynamic> _parsePayload(String str) {
    try {
      final decoded = jsonDecode(str);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }
  
  Uri _buildUri(String tableName, String operation, int? serverId) {
    final endpoint = '${AppConstants.baseUrl}/$tableName';
    if ((operation == 'delete' || operation == 'update') && serverId != null) {
      return Uri.parse('$endpoint?id=$serverId');
    }
    return Uri.parse(endpoint);
  }
  
  Future<_SyncResponse> _makeRequest(
    Uri uri,
    String operation,
    Map<String, dynamic> payload,
    String token,
  ) async {
    http.Response response;
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    
    switch (operation) {
      case 'create':
        response = await http.post(uri, headers: headers, body: jsonEncode(payload))
            .timeout(const Duration(seconds: 30));
        break;
      case 'update':
        response = await http.put(uri, headers: headers, body: jsonEncode(payload))
            .timeout(const Duration(seconds: 30));
        break;
      case 'delete':
        response = await http.delete(uri, headers: headers)
            .timeout(const Duration(seconds: 30));
        break;
      default:
        return _SyncResponse(success: false, message: 'Operación inválida');
    }
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body);
      return _SyncResponse(success: true, data: body);
    } else {
      final body = jsonDecode(response.body);
      return _SyncResponse(success: false, message: body['message'] ?? 'Error HTTP ${response.statusCode}');
    }
  }
  
  Future<void> _handleSyncSuccess(
    int queueId,
    String tableName,
    int localId,
    String operation,
    dynamic serverResponse,
  ) async {
    if (operation == 'delete') {
      // Hard delete from local DB
      await _localDb.database.then((db) => db.delete(tableName, where: 'id = ?', whereArgs: [localId]));
      await _localDb.removeFromSyncQueue(queueId);
    } else {
      // Update with server ID and mark synced
      final serverId = serverResponse['id'] ?? serverResponse['data']?['id'];
      if (serverId != null) {
        await _localDb.updateRecordAfterSync(tableName, localId, serverId, 0);
      }
      await _localDb.removeFromSyncQueue(queueId);
    }
  }
  
  void cancelSync() {
    _isSyncing = false;
  }
  
  Future<void> retryFailed() async {
    await syncNow(force: true);
  }
}

class _SyncResponse {
  final bool success;
  final String? message;
  final dynamic data;
  
  _SyncResponse({required this.success, this.message, this.data});
}