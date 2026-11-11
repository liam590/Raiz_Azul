import '../models/registro.dart';
import '../models/parcela.dart';

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
      });
    } else if (rest <= 10) {
      out.add({
        'nivel': 'info',
        'titulo': 'Cosecha estimada en $rest días',
        'descripcion': 'Reducir el riego según el cultivo y preparar la mano de obra.',
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
      });
    } else if (desde >= c['riego'] && rest > 0) {
      if (r7 >= 30) {
        out.add({
          'nivel': 'info',
          'titulo': 'Revisar humedad antes de regar',
          'descripcion': 'Han pasado $desde días del último riego, pero la lluvia acumulada en 7 días suma ${r7.toStringAsFixed(0)} mm. Comprobar el suelo antes de regar.',
        });
      } else {
        out.add({
          'nivel': 'alerta',
          'titulo': 'Revisar el riego',
          'descripcion': 'Han pasado $desde días desde el último riego. Para ${cultivo.toLowerCase()} la referencia es cada ${c['riego']} días. Confirmar la humedad del suelo.',
        });
      }
    }

    // Ventana de fertilización
    for (final fert in c['fert']) {
      final d = fert[0] as int;
      final nombreLab = fert[1] as String;
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
          });
        } else {
          final diasFaltan = d - dia;
          out.add({
            'nivel': 'info',
            'titulo': 'Se acerca: ${nombreLab[0].toLowerCase()}${nombreLab.substring(1)}',
            'descripcion': 'Corresponde alrededor del día $d del cultivo, en $diasFaltan días.',
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