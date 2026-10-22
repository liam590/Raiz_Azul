class Alerta {
  final String nivel; // 'alerta', 'info', 'ok'
  final String titulo;
  final String descripcion;
  final dynamic parcelaId;
  final String? parcelaNombre;
  final String? cultivo;

  Alerta({
    required this.nivel,
    required this.titulo,
    required this.descripcion,
    this.parcelaId,
    this.parcelaNombre,
    this.cultivo,
  });

  factory Alerta.fromJson(Map<String, dynamic> json) {
    return Alerta(
      nivel: json['nivel'] ?? 'info',
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      parcelaId: json['parcelaId'],
      parcelaNombre: json['parcelaNombre'],
      cultivo: json['cultivo'],
    );
  }
}
