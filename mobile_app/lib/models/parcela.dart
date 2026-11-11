import 'alerta.dart';

class Parcela {
  final dynamic id;
  final String nombre;
  final dynamic idFinca;
  final String finca;
  final String zona;
  final String cultivo;
  final double area;
  final String siembra;
  final bool cosechada;
  final int cicloDias;
  final int diasDesdeSiembra;
  final String fechaEstimadaCosecha;
  final double porcentajeCiclo;
  final String etapaActual;
  final List<Alerta> recomendaciones;
  
  // Local DB fields
  final int? syncStatus;
  final int? serverId;
  final int? idCultivo;
  final int? idZona;

  Parcela({
    required this.id,
    required this.nombre,
    required this.idFinca,
    required this.finca,
    required this.zona,
    required this.cultivo,
    required this.area,
    required this.siembra,
    required this.cosechada,
    required this.cicloDias,
    required this.diasDesdeSiembra,
    required this.fechaEstimadaCosecha,
    required this.porcentajeCiclo,
    required this.etapaActual,
    required this.recomendaciones,
    this.syncStatus,
    this.serverId,
    this.idCultivo,
    this.idZona,
  });

  factory Parcela.fromJson(Map<String, dynamic> json) {
    var recsJson = json['recomendaciones'] as List? ?? [];
    List<Alerta> recs = recsJson.map((r) => Alerta.fromJson(r)).toList();

    return Parcela(
      id: json['IdParcela'] ?? json['id'],
      nombre: json['NombreParcela'] ?? json['nombre'] ?? '',
      idFinca: json['IdFinca'] ?? json['idFinca'] ?? 1,
      finca: json['NombreFinca'] ?? json['finca'] ?? '',
      zona: json['NombreZona'] ?? json['zona'] ?? '',
      cultivo: json['NombreCultivo'] ?? json['cultivo'] ?? '',
      area: (json['AreaManzanas'] ?? json['area'] ?? 0.0).toDouble(),
      siembra: json['FechaSiembra'] ?? json['siembra'] ?? '',
      cosechada: json['Cosechada'] == true || json['Cosechada'] == 1 || json['cosechada'] == true,
      cicloDias: (json['CicloDias'] ?? 90).toInt(),
      diasDesdeSiembra: (json['DiasDesdeSiembra'] ?? 0).toInt(),
      fechaEstimadaCosecha: json['FechaEstimadaCosecha'] ?? '',
      porcentajeCiclo: (json['PorcentajeCiclo'] ?? 0.0).toDouble(),
      etapaActual: json['EtapaActual'] ?? 'Desarrollo',
      recomendaciones: recs,
      syncStatus: json['sync_status'],
      serverId: json['server_id'],
      idCultivo: json['id_cultivo'],
      idZona: json['id_zona'],
    );
  }
  
  factory Parcela.fromLocalMap(Map<String, dynamic> map) {
    return Parcela(
      id: map['id'],
      nombre: map['nombre'] ?? '',
      idFinca: map['id_finca'] ?? 1,
      finca: map['finca'] ?? '',
      zona: map['zona'] ?? '',
      cultivo: map['cultivo'] ?? '',
      area: (map['area'] ?? 0.0).toDouble(),
      siembra: map['siembra'] ?? '',
      cosechada: (map['cosechada'] ?? 0) == 1,
      cicloDias: map['ciclo_dias'] ?? 90,
      diasDesdeSiembra: map['dias_desde_siembra'] ?? 0,
      fechaEstimadaCosecha: map['fecha_estimada_cosecha'] ?? '',
      porcentajeCiclo: (map['porcentaje_ciclo'] ?? 0.0).toDouble(),
      etapaActual: map['etapa_actual'] ?? 'Desarrollo',
      recomendaciones: [],
      syncStatus: map['sync_status'],
      serverId: map['server_id'],
      idCultivo: map['id_cultivo'],
      idZona: map['id_zona'],
    );
  }
  
  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'id_finca': idFinca,
      'nombre': nombre,
      'finca': finca,
      'zona': zona,
      'cultivo': cultivo,
      'area': area,
      'siembra': siembra,
      'cosechada': cosechada ? 1 : 0,
      'ciclo_dias': cicloDias,
      'dias_desde_siembra': diasDesdeSiembra,
      'fecha_estimada_cosecha': fechaEstimadaCosecha,
      'porcentaje_ciclo': porcentajeCiclo,
      'etapa_actual': etapaActual,
      'sync_status': syncStatus ?? 0,
      'server_id': serverId,
      'id_cultivo': idCultivo,
      'id_zona': idZona,
    };
  }
  
  Map<String, dynamic> toServerMap() {
    return {
      'nombre': nombre,
      'finca': finca,
      'zona': zona,
      'cultivo': cultivo,
      'area': area,
      'siembra': siembra,
    };
  }
}
