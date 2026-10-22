import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';
import '../models/parcela.dart';
import '../models/registro.dart';
import '../models/alerta.dart';
import '../models/evento.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String get _baseUrl => AppConstants.baseUrl;

  // 1. Dashboard
  Future<Map<String, dynamic>> fetchDashboard() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/dashboard.php'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final data = decoded['data'] ?? {};
        
        List<Alerta> alertas = (data['alertas'] as List? ?? [])
            .map((a) => Alerta.fromJson(a))
            .toList();

        List<Registro> actividad = (data['actividadReciente'] as List? ?? [])
            .map((r) => Registro.fromJson(r))
            .toList();

        return {
          'totalParcelas': data['totalParcelas'] ?? 0,
          'litrosRegados7Dias': (data['litrosRegados7Dias'] ?? 0).toDouble(),
          'totalAlertas': data['totalAlertas'] ?? 0,
          'ahorroPotencialLitros': (data['ahorroPotencialLitros'] ?? 0).toDouble(),
          'alertas': alertas,
          'actividadReciente': actividad,
          'isSqlServer': data['isSqlServer'] ?? false,
          'driver': data['driver'] ?? 'unknown',
        };
      }
    } catch (e) {
      // Manejo de error de red
    }
    return {
      'totalParcelas': 0,
      'litrosRegados7Dias': 0.0,
      'totalAlertas': 0,
      'ahorroPotencialLitros': 0.0,
      'alertas': <Alerta>[],
      'actividadReciente': <Registro>[],
      'isSqlServer': false,
      'driver': 'desconectado',
    };
  }

  // 2. Parcelas
  Future<List<Parcela>> fetchParcelas() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/parcelas.php'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final list = decoded['data'] as List? ?? [];
        return list.map((p) => Parcela.fromJson(p)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> checkConnection() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/status.php')).timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
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
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/parcelas.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nombre': nombre,
          'finca': finca,
          'zona': zona,
          'cultivo': cultivo,
          'area': area,
          'siembra': siembra,
        }),
      ).timeout(const Duration(seconds: 5));

      final decoded = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return (success: true, message: decoded['message']?.toString() ?? 'Parcela creada exitosamente');
      } else {
        return (success: false, message: decoded['message']?.toString() ?? 'Error del servidor (${response.statusCode})');
      }
    } catch (e) {
      return (
        success: false,
        message: 'No se pudo conectar al servidor ($_baseUrl). Verifica que el backend PHP esté corriendo.'
      );
    }
  }

  Future<bool> eliminarParcela(dynamic id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/parcelas.php?id=$id')).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 3. Registros de Campo
  Future<List<Registro>> fetchRegistros({dynamic idParcela}) async {
    try {
      String url = '$_baseUrl/registros.php';
      if (idParcela != null) url += '?idParcela=$idParcela';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final list = decoded['data'] as List? ?? [];
        return list.map((r) => Registro.fromJson(r)).toList();
      }
    } catch (_) {}
    return [];
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
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/registros.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'parcelaId': idParcela,
          'idFinca': idFinca,
          'tipo': tipo,
          'fecha': fecha,
          'valor': valor,
          'detalle': detalle,
          'nota': nota,
          'autor': autor,
        }),
      ).timeout(const Duration(seconds: 5));

      final decoded = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return (success: true, message: decoded['message']?.toString() ?? 'Registro guardado exitosamente');
      } else {
        return (success: false, message: decoded['message']?.toString() ?? 'Error del servidor (${response.statusCode})');
      }
    } catch (e) {
      return (
        success: false,
        message: 'No se pudo conectar al servidor ($_baseUrl). Verifica que el backend PHP esté corriendo.'
      );
    }
  }

  Future<bool> eliminarRegistro(dynamic id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/registros.php?id=$id'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 4. Calendario
  Future<List<EventoCalendario>> fetchCalendario() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/calendario.php'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final list = decoded['data'] as List? ?? [];
        return list.map((e) => EventoCalendario.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  // 5. Reportes
  Future<Map<String, dynamic>> fetchReportes() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/reportes.php'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return decoded['data'] ?? {};
      }
    } catch (_) {}
    return {};
  }

  // 6. Catálogos
  Future<Map<String, dynamic>> fetchCatalogos() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/catalogos.php'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return decoded['data'] ?? {};
      }
    } catch (_) {}
    return {};
  }
}
