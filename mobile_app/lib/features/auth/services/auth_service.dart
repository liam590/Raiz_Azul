import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';
import '../../../core/secure_storage.dart';
import '../models/user_model.dart';

class AuthService {
  String get _baseUrl => AppConstants.baseUrl;

  Future<AuthResult> login({
    required String identificador,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/auth/login.php');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identificador': identificador,
          'password': password,
          'remember': rememberMe,
        }),
      ).timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body);

      if ((response.statusCode == 200) && body['success'] == true) {
        final data = body['data'];
        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];
        final user = UserModel.fromJson(data['user']);
        final remember = data['remember'] ?? rememberMe;

        await SecureStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: remember ? refreshToken : null,
        );
        await SecureStorage.saveUser(jsonEncode(user.toJson()));

        return AuthResult(success: true, user: user, rememberMe: remember);
      }

      return AuthResult(success: false, message: body['message'] ?? 'Usuario o contraseña incorrectos');
    } catch (e) {
      return AuthResult(success: false, message: 'No se pudo conectar al servidor. Verifica que el backend esté corriendo.');
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final token = await SecureStorage.getAccessToken();
    if (token == null || token.isEmpty) return null;

    try {
      final uri = Uri.parse('$_baseUrl/auth/me.php');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null && body['data']['user'] != null) {
          final user = UserModel.fromJson(body['data']['user']);
          await SecureStorage.saveUser(jsonEncode(user.toJson()));
          return user;
        }
      }
    } catch (_) {}

    final userJson = await SecureStorage.getUser();
    if (userJson != null && userJson.isNotEmpty) {
      try {
        return UserModel.fromJson(jsonDecode(userJson));
      } catch (_) {}
    }

    return null;
  }

  Future<void> logout() async {
    final refreshToken = await SecureStorage.getRefreshToken();
    try {
      final uri = Uri.parse('$_baseUrl/auth/logout.php');
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}
    await SecureStorage.clearAll();
  }

  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await SecureStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        return AuthResult(success: false, message: 'No hay sesión activa');
      }

      final uri = Uri.parse('$_baseUrl/auth/change_password.php');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        // Password changed successfully, logout to force re-login
        await logout();
        return AuthResult(success: true, message: 'Contraseña cambiada. Inicia sesión nuevamente.');
      }

      return AuthResult(success: false, message: body['message'] ?? 'Error al cambiar contraseña');
    } catch (e) {
      return AuthResult(success: false, message: 'No se pudo conectar al servidor');
    }
  }
}

class AuthResult {
  final bool success;
  final String? message;
  final UserModel? user;
  final bool rememberMe;

  AuthResult({
    required this.success,
    this.message,
    this.user,
    this.rememberMe = false,
  });
}