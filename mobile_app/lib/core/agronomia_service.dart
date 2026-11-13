import '../models/alerta.dart';
import '../models/parcela.dart';
import '../models/plan_manejo.dart';
import '../models/registro.dart';

/// Servicio de lógica agronómica (port del PHP AgronomiaService)
/// Calcula etapas, recomendaciones de riego, fertilización, riesgos, etc.
class AgronomiaService {
  // Parámetros de cultivos: ciclo (días), frecuencia riego (días), consumo ref (L/mz), ventanas fertilización
  static final Map<String, Map<String, dynamic>> crops = {
    'Tomate': {
      'ciclo': 100,
      'riego': 3,
      'ref': 4500,
      'fert': [
        [15, '1.ª fertilización'],
        [35, '2.ª fertilización'],
        [55, '3.ª fertilización'],
      ],
    },
    'Chile': {
      'ciclo': 110,
      'riego': 3,
      'ref': 4000,
      'fert': [
        [15, '1.ª fertilización'],
        [40, '2.ª fertilización'],
      ],
    },
    'Repollo': {
      'ciclo': 90,
      'riego': 3,
      'ref': 4000,
      'fert': [
        [14, '1.ª fertilización'],
        [35, '2.ª fertilización'],
      ],
    },
    'Maíz': {
      'ciclo': 120,
      'riego': 6,
      'ref': 6000,
      'fert': [
        [15, '1.ª fertilización'],
        [35, '2.ª fertilización'],
      ],
    },
    'Frijol': {
      'ciclo': 75,
      'riego': 6,
      'ref': 4000,
      'fert': [
        [12, 'Fertilización de arranque'],
        [30, 'Refuerzo de fertilización'],
      ],
    },
  };

  static int diffDays(DateTime date1, DateTime date2) {
    return date1.difference(date2).inDays;
  }

  static DateTime addDays(DateTime date, int days) {
    return date.add(Duration(days: days));
  }

  static const List<String> _meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  /// Insumos que el formulario ya ofrece, ordenados por momento del ciclo.
  static const List<String> insumosSugeridos = [
    'Fórmula 12-30-10',
    'Urea 46%',
    'Fórmula 15-15-15',
  ];

  static String _fechaCorta(DateTime d) => '${d.day} ${_meses[d.month - 1]}';

  static String _conMiles(num n) {
    final s = n.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  static String _insumoSugerido(int indice) =>
      insumosSugeridos[indice % insumosSugeridos.length];

  /// Litros de referencia para un riego: consumo del cultivo (L/mz) × área.
  static double litrosSugeridos(Parcela parcela) {
    final c = crops[parcela.cultivo] ?? crops['Maíz']!;
    final ref = (c['ref'] as num).toDouble();
    final area = parcela.area > 0 ? parcela.area : 1.0;
    return (ref * area).roundToDouble();
  }

  /// Recomendaciones listas para pintar en el detalle de la parcela.
  static List<Alerta> recomendacionesDe(
    Parcela parcela,
    List<Registro> registros,
  ) {
    return calcularRecomendaciones(parcela, registros)
        .map((m) => Alerta.fromMap(m))
        .toList();
  }

  /// Plan de manejo del ciclo: riego, ventanas de fertilización y cosecha,
  /// con el estado de cada uno según los registros de la parcela.
  static List<PlanManejoItem> calcularPlan(
    Parcela parcela,
    List<Registro> registros,
  ) {
    final cultivo = parcela.cultivo;
    final c = crops[cultivo] ?? crops['Maíz']!;
    final hoy = DateTime.now();
    final siembra = DateTime.tryParse(parcela.siembra) ?? hoy;
    final dia = siembra.isAfter(hoy) ? 0 : diffDays(hoy, siembra);
    final ciclo = c['ciclo'] as int;
    final rest = ciclo - dia;
    final area = parcela.area > 0 ? parcela.area : 1.0;
    final litros = litrosSugeridos(parcela);
    final frecuencia = c['riego'] as int;

    final own = registros.where((r) => r.parcelaId == parcela.id).toList();
    final plan = <PlanManejoItem>[];

    // --- Riego
    final riegos = own.where((r) => r.tipo == 'riego').toList()
      ..sort((a, b) {
        final fa = DateTime.tryParse(a.fecha) ?? hoy;
        final fb = DateTime.tryParse(b.fecha) ?? hoy;
        return fb.compareTo(fa);
      });

    var desde = dia;
    var ultimoRiego = 'Sin riegos registrados';
    if (riegos.isNotEmpty) {
      final f = DateTime.tryParse(riegos.first.fecha);
      if (f != null) {
        desde = diffDays(hoy, f);
        ultimoRiego = desde == 0
            ? 'Regado hoy'
            : 'Último riego hace $desde ${desde == 1 ? 'día' : 'días'}';
      }
    }

    final tocaRiego = rest > 0 && desde >= frecuencia;
    plan.add(PlanManejoItem(
      tipo: 'riego',
      titulo: 'Riego',
      detalle: 'Riego',
      subtitulo: 'Cada $frecuencia días · ~${_conMiles(litros)} L · $ultimoRiego',
      estado: tocaRiego ? 'toca' : 'programado',
      valor: litros,
      metodoRiego: 'Goteo',
      nota: 'Referencia: ${c['ref']} L/mz × ${area.toStringAsFixed(area == area.roundToDouble() ? 0 : 1)} mz',
    ));

    // --- Ventanas de fertilización
    final ferts = c['fert'] as List;
    for (var i = 0; i < ferts.length; i++) {
      final d = ferts[i][0] as int;
      final nombre = ferts[i][1] as String;
      final fMin = addDays(siembra, d - 6);
      final fVentana = addDays(siembra, d);

      final aplicado = own.any((r) {
        if (r.tipo != 'insumo') return false;
        final f = DateTime.tryParse(r.fecha);
        return f != null && f.isAfter(fMin);
      });

      String estado;
      if (aplicado) {
        estado = 'hecho';
      } else if (dia > d + 10) {
        estado = 'pasado';
      } else if (dia >= d - 2) {
        estado = 'toca';
      } else {
        estado = 'programado';
      }

      plan.add(PlanManejoItem(
        tipo: 'insumo',
        titulo: nombre,
        detalle: _insumoSugerido(i),
        subtitulo: 'Día $d · ${_fechaCorta(fVentana)}',
        estado: estado,
        nota: 'La dosis debe definirse con un técnico o análisis de suelo.',
      ));
    }

    // --- Cosecha
    final cosechada = parcela.cosechada ||
        own.any((r) => r.tipo == 'labor' && r.detalle == 'Cosecha');
    final fCosecha = addDays(siembra, ciclo);

    plan.add(PlanManejoItem(
      tipo: 'labor',
      titulo: 'Cosecha',
      detalle: 'Cosecha',
      subtitulo: 'Día $ciclo · ${_fechaCorta(fCosecha)}',
      estado: cosechada ? 'hecho' : (rest <= 10 ? 'toca' : 'programado'),
    ));

    return plan;
  }

  /// Calcula la etapa fenológica actual de un cultivo
  static Map<String, dynamic> calcularEtapa(String cultivoNombre, String fechaSiembra) {
    final c = crops[cultivoNombre] ?? crops['Maíz']!;
    final hoy = DateTime.now();
    final siembra = DateTime.tryParse(fechaSiembra) ?? hoy;
    
    final dias = siembra.isAfter(hoy) ? 0 : diffDays(hoy, siembra);
    final pct = c['ciclo'] > 0 ? dias / c['ciclo'] : 0.0;
    final pctClamped = pct.clamp(0.0, 1.0);

    String etapa = 'Establecimiento';
    if (pctClamped >= 1.0) {
      etapa = 'Punto de cosecha';
    } else if (pctClamped >= 0.80) {
      etapa = 'Maduración';
    } else if (pctClamped >= 0.50) {
      etapa = 'Floración y llenado';
    } else if (pctClamped >= 0.15) {
      etapa = 'Desarrollo';
    }

    return {
      'pct': double.parse(pctClamped.toStringAsFixed(2)),
      'etapa': etapa,
      'dias': dias,
      'ciclo': c['ciclo'],
      'fechaCosechaEstimada': addDays(siembra, c['ciclo']).toIso8601String().split('T')[0],
    };
  }

  /// Calcula recomendaciones agronómicas para una parcela
  static List<Map<String, dynamic>> calcularRecomendaciones(Parcela parcela, List<Registro> registros) {
    final cultivo = parcela.cultivo;
    final siembra = parcela.siembra;
    final parcelaId = parcela.id;
    final fincaNombre = parcela.finca;

    final c = crops[cultivo] ?? crops['Maíz']!;
    final hoy = DateTime.now();
    final siembraDt = DateTime.tryParse(siembra) ?? hoy;
    final dia = siembraDt.isAfter(hoy) ? 0 : diffDays(hoy, siembraDt);
    final rest = c['ciclo'] - dia;

    // Filtrar registros propios de la parcela
    final own = registros.where((r) => r.parcelaId == parcelaId).toList();

    // Verificar si ya fue cosechada
    final esCosechada = parcela.cosechada || 
        own.any((r) => r.tipo == 'labor' && r.detalle == 'Cosecha');

    if (esCosechada) {
      return [
        {
          'nivel': 'ok',
          'titulo': 'Cosecha registrada',
          'descripcion': 'Revisar el reporte de consumo de este ciclo.',
        }
      ];
    }

    final out = <Map<String, dynamic>>[];

    // Lluvias de la parcela o de la finca general
    final lluvias = registros.where((r) => 
        r.tipo == 'lluvia' && 
        (r.parcelaId == parcelaId || r.destino.contains(fincaNombre))
    ).toList();

    double rainDays(int days) {
      double total = 0;
      for (final r in lluvias) {
        final f = DateTime.tryParse(r.fecha);
        if (f != null) {
          final d = diffDays(hoy, f);
          if (d >= 0 && d < days) {
            total += r.valor;
          }
        }
      }
      return total;
    }

    final r3 = rainDays(3);
    final r7 = rainDays(7);

    // Último riego
    final riegos = own.where((r) => r.tipo == 'riego').toList();
    riegos.sort((a, b) => DateTime.tryParse(b.fecha)!.compareTo(DateTime.tryParse(a.fecha)!));

    int desde = dia;
    if (riegos.isNotEmpty) {
      final fUlt = DateTime.tryParse(riegos.first.fecha)!;
      desde = diffDays(hoy, fUlt);
    }

    // Cosecha
    if (rest <= 0) {
      out.add({
        'nivel': 'alerta',
        'titulo': 'Cosecha estimada cumplida',
        'descripcion': 'El ciclo de ${cultivo.toLowerCase()} (${c['ciclo']} días) ya terminó. Confirmar el punto de cosecha en campo.',
        'accion': {
          'tipo': 'labor',
          'detalle': 'Cosecha',
          'etiqueta': 'Registrar cosecha',
        },
      });
    } else if (rest <= 10) {
      out.add({
        'nivel': 'info',
        'titulo': 'Cosecha estimada en $rest días',
        'descripcion': 'Reducir el riego según el cultivo y preparar la mano de obra.',
        'accion': {
          'tipo': 'labor',
          'detalle': 'Cosecha',
          'etiqueta': 'Registrar cosecha',
        },
      });
    }

    // Riesgo de escorrentía
    final insumosRecientes = own.where((r) {
      if (r.tipo != 'insumo') return false;
      final f = DateTime.tryParse(r.fecha);
      if (f == null) return false;
      final d = diffDays(hoy, f);
      return d >= 0 && d <= 3;
    }).toList();

    if (r3 >= 40 && insumosRecientes.isNotEmpty) {
      out.add({
        'nivel': 'alerta',
        'titulo': 'Riesgo de escorrentía',
        'descripcion': 'Se aplicó fertilizante y cayeron ${r3.toStringAsFixed(0)} mm en 3 días. Revisar zanjas y barreras para evitar pérdida de insumo hacia las fuentes de agua.',
      });
    }

    // Recomendación de Riego
    if (r3 >= 20) {
      out.add({
        'nivel': 'info',
        'titulo': 'Posponer el riego',
        'descripcion': 'Llovieron ${r3.toStringAsFixed(0)} mm en los últimos 3 días. Revisar el drenaje y la humedad antes de volver a regar.',
        'accion': {
          'tipo': 'lluvia',
          'etiqueta': 'Registrar lluvia',
        },
      });
    } else if (desde >= c['riego'] && rest > 0) {
      if (r7 >= 30) {
        out.add({
          'nivel': 'info',
          'titulo': 'Revisar humedad antes de regar',
          'descripcion': 'Han pasado $desde días del último riego, pero la lluvia acumulada en 7 días suma ${r7.toStringAsFixed(0)} mm. Comprobar el suelo antes de regar.',
          'accion': {
            'tipo': 'riego',
            'valor': litrosSugeridos(parcela),
            'nota': 'Referencia: ${c['ref']} L/mz',
            'etiqueta': 'Registrar riego',
          },
        });
      } else {
        out.add({
          'nivel': 'alerta',
          'titulo': 'Revisar el riego',
          'descripcion': 'Han pasado $desde días desde el último riego. Para ${cultivo.toLowerCase()} la referencia es cada ${c['riego']} días. Confirmar la humedad del suelo.',
          'accion': {
            'tipo': 'riego',
            'valor': litrosSugeridos(parcela),
            'nota': 'Referencia: ${c['ref']} L/mz',
            'etiqueta': 'Registrar riego',
          },
        });
      }
    }

    // Ventana de fertilización
    final ferts = c['fert'] as List;
    for (var i = 0; i < ferts.length; i++) {
      final d = ferts[i][0] as int;
      final nombreLab = ferts[i][1] as String;
      final fMin = addDays(siembraDt, d - 6);

      final insumoAplicado = own.any((r) {
        if (r.tipo != 'insumo') return false;
        final f = DateTime.tryParse(r.fecha);
        return f != null && f.isAfter(fMin);
      });

      if (dia >= (d - 2) && dia <= (d + 10) && !insumoAplicado) {
        if (dia >= d) {
          out.add({
            'nivel': 'alerta',
            'titulo': 'Toca: ${nombreLab[0].toLowerCase()}${nombreLab.substring(1)}',
            'descripcion': 'Van $dia días desde la siembra y no hay un insumo registrado en esta ventana. La dosis debe definirse con un técnico o análisis de suelo.',
            'accion': {
              'tipo': 'insumo',
              'detalle': _insumoSugerido(i),
              'etiqueta': 'Registrar insumo',
            },
          });
        } else {
          final diasFaltan = d - dia;
          out.add({
            'nivel': 'info',
            'titulo': 'Se acerca: ${nombreLab[0].toLowerCase()}${nombreLab.substring(1)}',
            'descripcion': 'Corresponde alrededor del día $d del cultivo, en $diasFaltan días.',
            'accion': {
              'tipo': 'insumo',
              'detalle': _insumoSugerido(i),
              'etiqueta': 'Registrar insumo',
            },
          });
        }
      }
    }

    if (out.isEmpty) {
      out.add({
        'nivel': 'ok',
        'titulo': 'Manejo al día',
        'descripcion': 'Sin alertas por ahora. Seguir registrando riegos, lluvias e insumos.',
      });
    }

    // Ordenar por prioridad (alerta primero, luego info, luego ok)
    final prioridad = {'alerta': 0, 'info': 1, 'ok': 2};
    out.sort((a, b) => (prioridad[a['nivel']] ?? 3).compareTo(prioridad[b['nivel']] ?? 3));

    return out;
  }
}