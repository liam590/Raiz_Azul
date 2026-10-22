import 'package:flutter/foundation.dart';

class AppConstants {
  // En emulador Android se usa 10.0.2.2 para conectar al localhost de Windows.
  // En Windows Desktop o Web se usa localhost.
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://localhost:8000/api';
  }

  static String userName = 'Liam'; // Nombre del integrante activo
}
