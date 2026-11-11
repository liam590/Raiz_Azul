import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/offline_api_service.dart';
import '../models/parcela.dart';
import '../models/registro.dart';

class DetalleParcelaModal extends StatefulWidget {
  final Parcela parcela;
  final VoidCallback onDataChanged;
  final Function(dynamic parcelaId) onRegistrarTap;

  const DetalleParcelaModal({
    super.key,
    required this.parcela,
    required this.onDataChanged,
    required this.onRegistrarTap,
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
    final list = await _api.fetchRegistros(idParcela: widget.parcela.id);
    if (mounted) {
      setState(() {
        _registros = list;
        _cargando = false;
      });
    }
  }

  Future<void> _eliminarParcela() async {
    final ok = await _api.eliminarParcela(widget.parcela.id);
    if (mounted) {
      if (ok) {
        Navigator.pop(context);
        widget.onDataChanged();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parcela eliminada')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.parcela;
    final fCosecha = p.fechaEstimadaCosecha.isNotEmpty
        ? DateFormat('d MMM', 'es').format(DateTime.tryParse(p.fechaEstimadaCosecha) ?? DateTime.now())
        : '';

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

          const SizedBox(height: 16),

          // Recomendaciones
          if (p.recomendaciones.isNotEmpty) ...[
            const Text('Recomendaciones', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink)),
            const SizedBox(height: 8),
            ...p.recomendaciones.map((r) {
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

          // Botones de Acción
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onRegistrarTap(p.id);
            },
            child: const Text('Registrar en esta parcela'),
          ),
          const SizedBox(height: 10),

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
}
