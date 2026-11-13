/// Un renglón del plan de manejo del ciclo: riego, fertilización o cosecha.
class PlanManejoItem {
  /// 'riego', 'lluvia', 'insumo' o 'labor'
  final String tipo;
  final String titulo;

  /// Detalle que se preselecciona en el formulario (insumo o labor).
  final String detalle;
  final String subtitulo;

  /// 'hecho', 'toca', 'programado' o 'pasado'
  final String estado;
  final double? valor;
  final String? nota;
  final String? metodoRiego;

  const PlanManejoItem({
    required this.tipo,
    required this.titulo,
    required this.detalle,
    required this.subtitulo,
    required this.estado,
    this.valor,
    this.nota,
    this.metodoRiego,
  });

  bool get hecho => estado == 'hecho';
  bool get toca => estado == 'toca';
  bool get pasado => estado == 'pasado';
}
