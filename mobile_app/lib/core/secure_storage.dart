import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  static const keyAccessToken = 'raiz_azul_access_token';
  static const keyRefreshToken = 'raiz_azul_refresh_token';
  static const keyUserJson = 'raiz_azul_user_json';

  static Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    await _storage.write(key: keyAccessToken, value: accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: keyRefreshToken, value: refreshToken);
    }
  }

  static Future<String?> getAccessToken() => _storage.read(key: keyAccessToken);
  static Future<String?> getRefreshToken() => _storage.read(key: keyRefreshToken);

  static Future<void> saveUser(String userJson) => _storage.write(key: keyUserJson, value: userJson);
  static Future<String?> getUser() => _storage.read(key: keyUserJson);

  static Future<void> clearAll() => _storage.deleteAll();

  static Future<void> clearRefreshToken() => _storage.delete(key: keyRefreshToken);
}
