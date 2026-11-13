/// Acción de registro que sugiere una recomendación agronómica.
class AccionSugerida {
  /// 'riego', 'lluvia', 'insumo' o 'labor'
  final String tipo;
  final String? detalle;
  final double? valor;
  final String? nota;
  final String? etiqueta;

  const AccionSugerida({
    required this.tipo,
    this.detalle,
    this.valor,
    this.nota,
    this.etiqueta,
  });

  factory AccionSugerida.fromJson(Map<String, dynamic> json) {
    return AccionSugerida(
      tipo: json['tipo'] ?? 'labor',
      detalle: json['detalle'],
      valor: (json['valor'] as num?)?.toDouble(),
      nota: json['nota'],
      etiqueta: json['etiqueta'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo,
      'detalle': detalle,
      'valor': valor,
      'nota': nota,
      'etiqueta': etiqueta,
    };
  }
}

class Alerta {
  final String nivel; // 'alerta', 'info', 'ok'
  final String titulo;
  final String descripcion;
  final dynamic parcelaId;
  final String? parcelaNombre;
  final String? cultivo;
  final AccionSugerida? accion;

  Alerta({
    required this.nivel,
    required this.titulo,
    required this.descripcion,
    this.parcelaId,
    this.parcelaNombre,
    this.cultivo,
    this.accion,
  });

  factory Alerta.fromJson(Map<String, dynamic> json) {
    return Alerta(
      nivel: json['nivel'] ?? 'info',
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      parcelaId: json['parcelaId'],
      parcelaNombre: json['parcelaNombre'],
      cultivo: json['cultivo'],
      accion: _parseAccion(json['accion']),
    );
  }

  factory Alerta.fromMap(Map<String, dynamic> map) {
    return Alerta(
      nivel: map['nivel'] ?? 'info',
      titulo: map['titulo'] ?? '',
      descripcion: map['descripcion'] ?? '',
      parcelaId: map['parcelaId'],
      parcelaNombre: map['parcelaNombre'],
      cultivo: map['cultivo'],
      accion: _parseAccion(map['accion']),
    );
  }

  static AccionSugerida? _parseAccion(dynamic value) {
    if (value is Map) {
      return AccionSugerida.fromJson(Map<String, dynamic>.from(value));
    }
    return null;
  }
}
