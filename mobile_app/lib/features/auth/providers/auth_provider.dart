import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../../../core/secure_storage.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  bool _rememberMe = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get rememberMe => _rememberMe;

  AuthProvider() {
    // Check if there's a valid refresh token (remember me was enabled)
    _checkRememberedSession();
  }

  Future<void> _checkRememberedSession() async {
    _isLoading = true;
    notifyListeners();

    final refreshToken = await SecureStorage.getRefreshToken();
    final userJson = await SecureStorage.getUser();

    if (refreshToken != null && refreshToken.isNotEmpty && userJson != null && userJson.isNotEmpty) {
      try {
        // Try to validate with backend
        final user = await _authService.getCurrentUser();
        if (user != null) {
          _user = user;
          _isAuthenticated = true;
          _rememberMe = true;
        } else {
          // Token expired or invalid, clear storage
          await SecureStorage.clearAll();
        }
      } catch (_) {
        await SecureStorage.clearAll();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    await _checkRememberedSession();
  }

  Future<(bool success, String? message)> login({
    required String identificador,
    required String password,
    bool rememberMe = false,
  }) async {
    final result = await _authService.login(
      identificador: identificador,
      password: password,
      rememberMe: rememberMe,
    );
    if (result.success && result.user != null) {
      _user = result.user;
      _isAuthenticated = true;
      _rememberMe = rememberMe;
      notifyListeners();
      return (true, null);
    }
    return (false, result.message);
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _isAuthenticated = false;
    _rememberMe = false;
    notifyListeners();
  }

  Future<void> setRememberMe(bool value) async {
    _rememberMe = value;
    if (!value) {
      // Disable remember me: clear refresh token but keep access token for current session
      await SecureStorage.clearRefreshToken();
    }
    notifyListeners();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await _authService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    if (!result.success) {
      throw Exception(result.message ?? 'Error al cambiar contraseña');
    }
  }
}