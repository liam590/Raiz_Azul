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
    );
  }
}
