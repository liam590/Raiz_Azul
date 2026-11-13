import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import '../models/parcela.dart';
import '../widgets/nueva_parcela_modal.dart';
import '../widgets/detalle_parcela_modal.dart';

class ParcelasScreen extends StatefulWidget {
  const ParcelasScreen({super.key});

  @override
  State<ParcelasScreen> createState() => _ParcelasScreenState();
}

class _ParcelasScreenState extends State<ParcelasScreen> {
  final ApiService _api = ApiService();
  bool _cargando = true;
  List<Parcela> _parcelas = [];

  @override
  void initState() {
    super.initState();
    _cargarParcelas();
  }

  Future<void> _cargarParcelas() async {
    if (mounted) setState(() => _cargando = true);

    List<Parcela> list = _parcelas;
    try {
      list = await _api.fetchParcelas();
    } catch (_) {
      // Se conserva la lista anterior si la recarga falla.
    }

    if (!mounted) return;
    setState(() {
      _parcelas = list;
      _cargando = false;
    });
  }

  void _abrirNuevaParcela() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NuevaParcelaModal(onParcelaCreada: _cargarParcelas),
    );
  }

  void _abrirDetalle(Parcela parcela) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DetalleParcelaModal(
        parcela: parcela,
        onDataChanged: _cargarParcelas,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.azul,
        onRefresh: _cargarParcelas,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Parcelas', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.ink)),
                ElevatedButton.icon(
                  onPressed: _abrirNuevaParcela,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nueva parcela'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (_cargando)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppColors.azul)))
            else if (_parcelas.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(Icons.grass, size: 48, color: AppColors.muted),
                      const SizedBox(height: 12),
                      const Text('Sin parcelas todavía', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      const SizedBox(height: 4),
                      const Text('Crea tu primera parcela con su cultivo y fecha de siembra.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _abrirNuevaParcela, child: const Text('Crear parcela')),
                    ],
                  ),
                ),
              )
            else
              ..._parcelas.map((p) => _buildParcelaCard(p)),
          ],
        ),
      ),
    );
  }

  Widget _buildParcelaCard(Parcela p) {
    final int alertasCount = p.recomendaciones.where((r) => r.nivel == 'alerta').length;
    final fCosecha = p.fechaEstimadaCosecha.isNotEmpty
        ? DateFormat('d MMM', 'es').format(DateTime.tryParse(p.fechaEstimadaCosecha) ?? DateTime.now())
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _abrirDetalle(p),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      p.nombre,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (p.cosechada)
                    _pill('Cosechada', AppColors.brote, AppColors.broteSoft)
                  else if (alertasCount > 0)
                    _pill('$alertasCount ${alertasCount == 1 ? "aviso" : "avisos"}', AppColors.alerta, AppColors.alertaSoft)
                  else if (p.recomendaciones.any((r) => r.nivel == 'info'))
                    _pill('Información', AppColors.azul, AppColors.azulSoft)
                  else
                    _pill('Al día', AppColors.brote, AppColors.broteSoft),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.broteSoft, borderRadius: BorderRadius.circular(99)),
                    child: Text(p.cultivo, style: const TextStyle(color: AppColors.brote, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${p.finca} · ${p.zona} · ${p.area} mz',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Barra de avance del ciclo
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (p.porcentajeCiclo / 100).clamp(0.0, 1.0),
                  minHeight: 7,
                  backgroundColor: AppColors.broteSoft,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brote),
                ),
              ),
              const SizedBox(height: 6),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${p.etapaActual} · día ${p.diasDesdeSiembra} de ${p.cicloDias}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  Text('Cosecha $fCosecha', style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String texto, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(99)),
      child: Text(texto, style: TextStyle(color: textColor, fontSize: 11.5, fontWeight: FontWeight.bold)),
    );
  }
}
