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
  final String metodoRiego;
  final int? duracionMinutos;
  final String? grupoRiego;
  
  // Local DB fields
  final int? syncStatus;
  final int? serverId;

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
    this.metodoRiego = '',
    this.duracionMinutos,
    this.grupoRiego,
    this.syncStatus,
    this.serverId,
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
      metodoRiego: json['MetodoRiego'] ?? json['metodoRiego'] ?? '',
      duracionMinutos: _parseInt(json['DuracionMinutos'] ?? json['duracionMinutos']),
      grupoRiego: json['GrupoRiego'] ?? json['grupoRiego'],
      syncStatus: json['sync_status'],
      serverId: json['server_id'],
    );
  }
  
  factory Registro.fromLocalMap(Map<String, dynamic> map) {
    return Registro(
      id: map['id'],
      idFinca: map['id_finca'] ?? 1,
      parcelaId: map['id_parcela'],
      tipo: map['tipo'] ?? 'labor',
      fecha: map['fecha'] ?? '',
      valor: (map['valor'] ?? 0.0).toDouble(),
      detalle: map['detalle'] ?? '',
      nota: map['nota'] ?? '',
      autor: map['autor'] ?? 'Productor',
      destino: map['destino'] ?? 'Parcela',
      metodoRiego: map['metodo_riego'] ?? '',
      duracionMinutos: _parseInt(map['duracion_minutos']),
      grupoRiego: map['grupo_riego'],
      syncStatus: map['sync_status'],
      serverId: map['server_id'],
    );
  }
  
  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'id_finca': idFinca,
      'id_parcela': parcelaId,
      'tipo': tipo,
      'fecha': fecha,
      'valor': valor,
      'detalle': detalle,
      'nota': nota,
      'autor': autor,
      'destino': destino,
      'metodo_riego': metodoRiego,
      'duracion_minutos': duracionMinutos,
      'grupo_riego': grupoRiego,
      'sync_status': syncStatus ?? 0,
      'server_id': serverId,
    };
  }
  
  Map<String, dynamic> toServerMap() {
    final pid = (parcelaId is String && (parcelaId as String).startsWith('finca:'))
        ? null
        : parcelaId;

    return {
      'idFinca': idFinca,
      'parcelaId': pid,
      'tipo': _mapTipoToCode(tipo),
      'fecha': fecha,
      'valor': valor,
      'detalle': detalle,
      'nota': nota,
      'autor': autor,
      'metodoRiego': metodoRiego.isNotEmpty ? metodoRiego : null,
      'duracionMinutos': duracionMinutos,
      'grupoRiego': grupoRiego,
    };
  }
  
  String _mapTipoToCode(String tipo) {
    switch (tipo) {
      case 'riego': return 'riego';
      case 'lluvia': return 'lluvia';
      case 'insumo': return 'insumo';
      case 'labor': return 'labor';
      default: return 'labor';
    }
  }

  String get textoPrincipal {
    if (tipo == 'riego') {
      final partes = ['Riego', '${valor.toInt()} L'];
      if (metodoRiego.isNotEmpty) partes.add(metodoRiego);
      if (duracionMinutos != null && duracionMinutos! > 0) {
        partes.add('$duracionMinutos min');
      }
      return partes.join(' · ');
    }
    if (tipo == 'lluvia') return 'Lluvia · ${valor.toStringAsFixed(1)} mm';
    if (tipo == 'insumo') return '${detalle.isNotEmpty ? detalle : "Insumo"} · ${valor.toStringAsFixed(1)} lb';
    return detalle.isNotEmpty ? detalle : 'Labor';
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}