import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  List<ConnectivityResult> _currentResults = [ConnectivityResult.none];
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  bool _isOnline = false;
  bool _wasOnline = false;
  DateTime? _lastOnlineTime;
  
  bool get isOnline => _isOnline;
  bool get wasOnline => _wasOnline;
  DateTime? get lastOnlineTime => _lastOnlineTime;
  List<ConnectivityResult> get currentResults => _currentResults;
  
  ConnectivityService() {
    _init();
  }
  
  Future<void> _init() async {
    _currentResults = await _connectivity.checkConnectivity();
    _updateOnlineStatus(_currentResults);
    
    _subscription = _connectivity.onConnectivityChanged.listen(_updateOnlineStatus);
  }
  
  void _updateOnlineStatus(List<ConnectivityResult> results) {
    _currentResults = results;
    final wasOnline = _isOnline;
    _isOnline = _hasInternetAccess(results);
    
    if (_isOnline && !wasOnline) {
      _wasOnline = true;
      _lastOnlineTime = DateTime.now();
    }
    
    notifyListeners();
  }
  
  bool _hasInternetAccess(List<ConnectivityResult> results) {
    // Check if any connection type provides internet
    return results.any((result) => 
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.ethernet ||
      (kIsWeb && result == ConnectivityResult.none) // Web assumes online
    );
  }
  
  Future<bool> checkConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateOnlineStatus(results);
      return _isOnline;
    } catch (_) {
      return false;
    }
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}