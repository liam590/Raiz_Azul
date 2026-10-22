class EventoCalendario {
  final String fecha;
  final String tipo; // 'riego', 'lluvia', 'insumo', 'labor', 'siembra', 'cosecha'
  final dynamic parcelaId;
  final String titulo;
  final bool real;
  final String? autor;

  EventoCalendario({
    required this.fecha,
    required this.tipo,
    this.parcelaId,
    required this.titulo,
    required this.real,
    this.autor,
  });

  factory EventoCalendario.fromJson(Map<String, dynamic> json) {
    return EventoCalendario(
      fecha: json['fecha'] ?? '',
      tipo: json['tipo'] ?? 'labor',
      parcelaId: json['parcelaId'],
      titulo: json['titulo'] ?? '',
      real: json['real'] == true,
      autor: json['autor'],
    );
  }
}
