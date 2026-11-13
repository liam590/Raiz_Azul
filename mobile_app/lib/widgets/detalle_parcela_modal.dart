import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/agronomia_service.dart';
import '../core/offline_api_service.dart';
import '../core/theme.dart';
import '../models/parcela.dart';
import '../models/plan_manejo.dart';
import '../models/registro.dart';
import '../models/registro_preset.dart';
import 'registro_modal.dart';

class DetalleParcelaModal extends StatefulWidget {
  final Parcela parcela;
  final VoidCallback onDataChanged;

  const DetalleParcelaModal({
    super.key,
    required this.parcela,
    required this.onDataChanged,
  });

  @override
  State<DetalleParcelaModal> createState() => _DetalleParcelaModalState();
}

class _DetalleParcelaModalState extends State<DetalleParcelaModal> {
  final OfflineApiService _api = OfflineApiService();
  bool _cargando = true;
  List<Registro> _registros = [];
  bool _confirmandoEliminar = false;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    List<Registro> list = [];
    try {
      list = await _api.fetchRegistros(idParcela: widget.parcela.id);
    } catch (_) {
      // Si falla la BD local o la red, mostramos el detalle sin historial
      // en lugar de dejar el spinner encendido para siempre.
    }

    if (!mounted) return;
    setState(() {
      _registros = list;
      _cargando = false;
    });
  }

  Future<void> _registrar(RegistroPreset preset) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RegistroModal(
        initialParcelaId: widget.parcela.id,
        initialParcelaNombre: '${widget.parcela.nombre} · ${widget.parcela.cultivo}',
        initialIdFinca: int.tryParse(widget.parcela.idFinca.toString()),
        initialTipo: preset.tipo,
        initialDetalle: preset.detalle,
        initialValor: preset.valor,
        initialNota: preset.nota,
        initialMetodoRiego: preset.metodoRiego,
        lockParcela: preset.lockParcela,
        onRegistroGuardado: widget.onDataChanged,
      ),
    );

    if (!mounted) return;
    // El detalle sigue abierto: refrescamos historial y plan en el acto,
    // sin ocultar el plan mientras llega la respuesta.
    await _cargarHistorial();
  }

  Future<void> _eliminarParcela() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final ok = await _api.eliminarParcela(widget.parcela.id);
      if (!mounted) return;
      if (ok) {
        navigator.pop();
        widget.onDataChanged();
        messenger.showSnackBar(
          const SnackBar(content: Text('Parcela eliminada')),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.alerta,
            content: Text('No se pudo eliminar la parcela: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.parcela;
    final fCosecha = p.fechaEstimadaCosecha.isNotEmpty
        ? DateFormat('d MMM', 'es').format(
            DateTime.tryParse(p.fechaEstimadaCosecha) ?? DateTime.now(),
          )
        : '';

    final recomendaciones = _cargando
        ? p.recomendaciones
        : AgronomiaService.recomendacionesDe(p, _registros);
    final plan = _cargando
        ? const <PlanManejoItem>[]
        : AgronomiaService.calcularPlan(p, _registros);
    final litros = AgronomiaService.litrosSugeridos(p);
    final abonoPendiente = _primerPendiente(plan, 'insumo');

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.nombre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text('${p.finca} · ${p.zona} · ${p.area} mz', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                  ],
                ),
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 12),

          // Cultivo y Cosecha estimada
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.broteSoft, borderRadius: BorderRadius.circular(99)),
                child: Text(p.cultivo, style: const TextStyle(color: AppColors.brote, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              Text('Cosecha estimada: $fCosecha', style: const TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),

          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (p.porcentajeCiclo / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.broteSoft,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brote),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(p.etapaActual, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
              Text('Día ${p.diasDesdeSiembra} de ${p.cicloDias}', style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
            ],
          ),

          const SizedBox(height: 18),

          // Acciones rápidas de registro
          const Text('¿Qué pasó en esta parcela?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink)),
          const SizedBox(height: 8),
          Row(
            children: [
              _accionRapida(
                'Regó',
                Icons.water_drop,
                AppColors.azul,
                () => _registrar(RegistroPreset(
                  tipo: 'riego',
                  valor: litros,
                  metodoRiego: 'Goteo',
                )),
              ),
              _accionRapida(
                'Abonó',
                Icons.eco,
                AppColors.brote,
                () => _registrar(RegistroPreset(
                  tipo: 'insumo',
                  detalle: abonoPendiente?.detalle,
                )),
              ),
              _accionRapida(
                'Labor',
                Icons.build,
                AppColors.tierra,
                () => _registrar(const RegistroPreset(tipo: 'labor')),
              ),
              _accionRapida(
                'Llovió',
                Icons.cloud,
                AppColors.lluvia,
                () => _registrar(const RegistroPreset(tipo: 'lluvia')),
              ),
              _accionRapida(
                'Cosechó',
                Icons.agriculture,
                AppColors.alerta,
                () => _registrar(const RegistroPreset(tipo: 'labor', detalle: 'Cosecha')),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Plan del ciclo
          if (!_cargando) ...[
            const Text('Plan del ciclo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink)),
            const SizedBox(height: 8),
            ...plan.map(_planTile),
            const SizedBox(height: 6),
          ],

          // Recomendaciones
          if (recomendaciones.isNotEmpty) ...[
            const Text('Recomendaciones', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink)),
            const SizedBox(height: 8),
            ...recomendaciones.map((r) {
              final esAlerta = r.nivel == 'alerta';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: esAlerta ? AppColors.alertaSoft : AppColors.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: esAlerta ? AppColors.alerta.withValues(alpha: 0.3) : AppColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.titulo, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: esAlerta ? AppColors.alerta : AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(r.descripcion, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                    if (r.accion != null) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _registrar(RegistroPreset.fromAccion(r.accion!)),
                          icon: const Icon(Icons.add, size: 16),
                          label: Text(r.accion!.etiqueta ?? 'Anotar'),
                          style: TextButton.styleFrom(
                            foregroundColor: esAlerta ? AppColors.alerta : AppColors.azul,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
          ],

          // Registros recientes
          const Text('Últimos registros', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink)),
          const SizedBox(height: 8),
          if (_cargando)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          else if (_registros.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(12)),
              child: const Text('Sin registros todavía.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
            )
          else
            ..._registros.take(5).map((r) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line, width: 0.5))),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: r.tipo == 'riego'
                              ? AppColors.azul
                              : (r.tipo == 'lluvia' ? AppColors.lluvia : (r.tipo == 'insumo' ? AppColors.brote : AppColors.tierra)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.textoPrincipal, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                            Text('${r.fecha} · ${r.autor}', style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),

          const SizedBox(height: 20),

          // Eliminar
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: _confirmandoEliminar ? Colors.white : AppColors.alerta,
              backgroundColor: _confirmandoEliminar ? AppColors.alerta : Colors.transparent,
              side: const BorderSide(color: AppColors.alerta),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () {
              if (_confirmandoEliminar) {
                _eliminarParcela();
              } else {
                setState(() => _confirmandoEliminar = true);
              }
            },
            child: Text(_confirmandoEliminar ? 'Tocar otra vez para confirmar eliminación' : 'Eliminar parcela'),
          ),
        ],
      ),
    );
  }

  PlanManejoItem? _primerPendiente(List<PlanManejoItem> plan, String tipo) {
    for (final item in plan) {
      if (item.tipo == tipo && !item.hecho && !item.pasado) return item;
    }
    return null;
  }

  Widget _accionRapida(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              border: Border.all(color: color.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _planTile(PlanManejoItem item) {
    final color = _colorPlan(item.tipo);
    final icon = item.detalle == 'Cosecha' ? Icons.agriculture : _iconPlan(item.tipo);

    final String badge;
    if (item.hecho) {
      badge = 'Hecho';
    } else if (item.pasado) {
      badge = 'Ventana pasada';
    } else if (item.toca) {
      badge = 'Toca';
    } else {
      badge = 'Programado';
    }

    final badgeColor = item.hecho
        ? AppColors.brote
        : (item.toca ? color : AppColors.muted);
    final badgeBg = item.hecho
        ? AppColors.broteSoft
        : (item.toca ? color.withValues(alpha: 0.12) : AppColors.surface2);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.hecho ? AppColors.surface2 : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.toca ? color.withValues(alpha: 0.5) : AppColors.line,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.titulo,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: item.hecho ? AppColors.muted : AppColors.ink,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(item.subtitulo, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
              ],
            ),
          ),
          if (!item.hecho) ...[
            const SizedBox(width: 6),
            TextButton(
              onPressed: () => _registrar(RegistroPreset(
                tipo: item.tipo,
                detalle: item.detalle,
                valor: item.valor,
                metodoRiego: item.metodoRiego,
              )),
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Anotar', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  Color _colorPlan(String tipo) {
    switch (tipo) {
      case 'riego':
        return AppColors.azul;
      case 'lluvia':
        return AppColors.lluvia;
      case 'insumo':
        return AppColors.brote;
      default:
        return AppColors.tierra;
    }
  }

  IconData _iconPlan(String tipo) {
    switch (tipo) {
      case 'riego':
        return Icons.water_drop;
      case 'lluvia':
        return Icons.cloud;
      case 'insumo':
        return Icons.eco;
      default:
        return Icons.build;
    }
  }
}
