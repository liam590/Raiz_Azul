class Registro {
  final dynamic id;
  final dynamic idFinca;
  final dynamic parcelaId;
  final String tipo; // 'riego', 'lluvia', 'insumo', 'labor'
  final String fecha;
  final double valor;
  final String detalle;
  final String nota;
  final String autor;
  final String destino;

  Registro({
    required this.id,
    required this.idFinca,
    this.parcelaId,
    required this.tipo,
    required this.fecha,
    required this.valor,
    required this.detalle,
    required this.nota,
    required this.autor,
    required this.destino,
  });

  factory Registro.fromJson(Map<String, dynamic> json) {
    return Registro(
      id: json['IdRegistro'] ?? json['id'],
      idFinca: json['IdFinca'] ?? json['idFinca'] ?? 1,
      parcelaId: json['IdParcela'] ?? json['parcelaId'],
      tipo: json['TipoCodigo'] ?? json['tipo'] ?? 'labor',
      fecha: json['Fecha'] ?? json['fecha'] ?? '',
      valor: (json['Valor'] ?? json['valor'] ?? 0.0).toDouble(),
      detalle: json['Detalle'] ?? json['detalle'] ?? '',
      nota: json['Nota'] ?? json['nota'] ?? '',
      autor: json['NombreAutor'] ?? json['autor'] ?? 'Productor',
      destino: json['Destino'] ?? json['destino'] ?? 'Parcela',
    );
  }

  String get textoPrincipal {
    if (tipo == 'riego') return 'Riego · ${valor.toInt()} L';
    if (tipo == 'lluvia') return 'Lluvia · ${valor.toStringAsFixed(1)} mm';
    if (tipo == 'insumo') return '${detalle.isNotEmpty ? detalle : "Insumo"} · ${valor.toStringAsFixed(1)} lb';
    return detalle.isNotEmpty ? detalle : 'Labor';
  }
}
