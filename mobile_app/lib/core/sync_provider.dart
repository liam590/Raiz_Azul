import 'package:flutter/material.dart';
import '../core/local_database.dart';
import '../core/connectivity_service.dart';
import '../core/sync_service.dart';

class SyncProvider extends ChangeNotifier {
  final LocalDatabase _localDb = LocalDatabase();
  final ConnectivityService _connectivity = ConnectivityService();
  final SyncService _syncService = SyncService();
  
  // State
  bool _isOnline = false;
  bool _isSyncing = false;
  int _pendingCount = 0;
  String? _lastError;
  DateTime? _lastSyncTime;
  bool _lastSyncSuccess = false;
  bool _autoSync = true;
  Duration _syncInterval = const Duration(minutes: 15);
  DateTime? _nextSyncTime;
  
  // Getters
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingCount => _pendingCount;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get lastSyncSuccess => _lastSyncSuccess;
  bool get autoSync => _autoSync;
  Duration get syncInterval => _syncInterval;
  DateTime? get nextSyncTime => _nextSyncTime;
  ConnectivityService get connectivity => _connectivity;
  SyncService get syncService => _syncService;
  
  SyncProvider() {
    _init();
  }
  
  Future<void> _init() async {
    _connectivity.addListener(_onConnectivityChanged);
    _syncService.addListener(_onSyncChanged);
    
    _isOnline = _connectivity.isOnline;
    await _refreshPendingCount();
    _scheduleNextSync();
  }
  
  void _onConnectivityChanged() {
    final wasOnline = _isOnline;
    _isOnline = _connectivity.isOnline;
    
    if (_isOnline && !wasOnline && _autoSync) {
      // Came back online - sync immediately
      syncNow();
    }
    
    notifyListeners();
  }
  
  void _onSyncChanged() {
    _isSyncing = _syncService.isSyncing;
    _pendingCount = _syncService.pendingCount;
    _lastError = _syncService.lastError;
    _lastSyncTime = _syncService.lastSyncTime;
    _lastSyncSuccess = _syncService.lastSyncSuccess;
    notifyListeners();
  }
  
  Future<void> _refreshPendingCount() async {
    try {
      _pendingCount = await _localDb.getPendingCount();
    } catch (_) {
      _pendingCount = 0;
    }
    notifyListeners();
  }
  
  Future<void> syncNow() async {
    if (!_isOnline) {
      _lastError = 'Sin conexión a internet';
      notifyListeners();
      return;
    }
    
    await _syncService.syncNow();
    await _refreshPendingCount();
    _scheduleNextSync();
  }
  
  Future<void> setAutoSync(bool enabled) async {
    _autoSync = enabled;
    if (enabled) {
      _scheduleNextSync();
    } else {
      _nextSyncTime = null;
    }
    notifyListeners();
  }
  
  Future<void> setSyncInterval(Duration interval) async {
    _syncInterval = interval;
    _scheduleNextSync();
    notifyListeners();
  }
  
  void _scheduleNextSync() {
    if (!_autoSync) {
      _nextSyncTime = null;
      return;
    }
    _nextSyncTime = DateTime.now().add(_syncInterval);
    notifyListeners();
  }
  
  @override
  void dispose() {
    _connectivity.removeListener(_onConnectivityChanged);
    _syncService.removeListener(_onSyncChanged);
    _connectivity.dispose();
    _localDb.close();
    super.dispose();
  }
}