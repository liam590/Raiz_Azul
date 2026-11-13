import 'alerta.dart';

/// Valores iniciales con los que se abre el formulario de registro cuando el
/// usuario toca una acción del plan de manejo de una parcela.
class RegistroPreset {
  /// 'riego', 'lluvia', 'insumo' o 'labor'
  final String tipo;
  final String? detalle;
  final double? valor;
  final String? nota;
  final String? metodoRiego;

  /// Cuando se llega desde el detalle de una parcela ya está elegida, así que
  /// el formulario no permite cambiarla.
  final bool lockParcela;

  const RegistroPreset({
    required this.tipo,
    this.detalle,
    this.valor,
    this.nota,
    this.metodoRiego,
    this.lockParcela = true,
  });

  factory RegistroPreset.fromAccion(AccionSugerida accion) {
    return RegistroPreset(
      tipo: accion.tipo,
      detalle: accion.detalle,
      valor: accion.valor,
      nota: accion.nota,
      metodoRiego: accion.tipo == 'riego' ? 'Goteo' : null,
    );
  }
}
