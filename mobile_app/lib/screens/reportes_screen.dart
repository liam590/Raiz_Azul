import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/offline_api_service.dart';
import '../core/export_service.dart';
import '../models/registro.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final OfflineApiService _api = OfflineApiService();
  final ExportService _export = ExportService();
  bool _cargando = true;
  bool _exportando = false;
  Map<String, dynamic> _reporte = {};
  List<Registro> _registros = [];

  @override
  void initState() {
    super.initState();
    _cargarReportes();
  }

  Future<void> _cargarReportes() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    try {
      final data = await _api.fetchReportes().timeout(const Duration(seconds: 10));
      await _api.fetchParcelas().timeout(const Duration(seconds: 10)); // Ensure catalogs are cached locally
      final registros = await _api.fetchRegistros().timeout(const Duration(seconds: 10));
      if (mounted) {
        setState(() {
          _reporte = data is Map<String, dynamic> ? data : {};
          _registros = registros;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _reporte = {};
          _registros = [];
          _cargando = false;
        });
      }
    }
  }

  Future<void> _exportarPdf() async {
    setState(() => _exportando = true);
    try {
      final parcelasData = _reporte['parcelas'] as List? ?? [];
      await _export.exportReportToPdf(
        reporte: _reporte,
        parcelasData: parcelasData,
        registros: _registros,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF exportado correctamente'), backgroundColor: AppColors.brote),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exportando PDF: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _exportarExcel() async {
    setState(() => _exportando = true);
    try {
      final parcelasData = _reporte['parcelas'] as List? ?? [];
      await _export.exportReportToExcel(
        reporte: _reporte,
        parcelasData: parcelasData,
        registros: _registros,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel exportado correctamente'), backgroundColor: AppColors.brote),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exportando Excel: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.azul)));
    }

    final Map<String, dynamic> reporte = _reporte is Map<String, dynamic> ? _reporte : {};
    final double totalAgua = (reporte['totalAguaRiego'] ?? 0.0).toDouble();
    final double lluviaPromedio = (reporte['lluviaPromedioMm'] ?? 0.0).toDouble();
    final double ahorroL = (reporte['ahorroPotencialLitros'] ?? 0.0).toDouble();
    final List parcelas = reporte['parcelas'] is List ? reporte['parcelas'] as List : [];

    double maxPorMz = 1.0;
    for (var p in parcelas) {
      final val = (p['litrosPorManzana'] ?? 0.0).toDouble();
      if (val > maxPorMz) maxPorMz = val;
    }

    final fmtEntero = NumberFormat.decimalPattern('es');
    final fmtDec = NumberFormat('#,##0.0', 'es');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        actions: [
          IconButton(
            tooltip: 'Exportar PDF',
            onPressed: _exportando ? null : _exportarPdf,
            icon: _exportando
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.picture_as_pdf_rounded),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Exportar Excel',
            onPressed: _exportando ? null : _exportarExcel,
            icon: _exportando
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.table_chart_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.azul,
        onRefresh: _cargarReportes,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
          children: [
            const Text('Uso de recursos desde la siembra hasta hoy, por parcela y ciclo.', style: TextStyle(color: AppColors.muted, fontSize: 13.5)),
            const SizedBox(height: 16),

            // Tiles Principales
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${fmtEntero.format(totalAgua.toInt())} L', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.ink)),
                          const SizedBox(height: 2),
                          const Text('Agua de riego total', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${fmtDec.format(lluviaPromedio)} mm', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.ink)),
                          const SizedBox(height: 2),
                          const Text('Lluvia promedio/parcela', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Gráfico Horizontal: Agua de riego por manzana
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Agua de riego por manzana', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink)),
                    const SizedBox(height: 14),
                    ...parcelas.map((p) {
                      final pNom = p['nombre'] ?? '';
                      final pLPorMz = (p['litrosPorManzana'] ?? 0.0).toDouble();
                      final ratio = (pLPorMz / maxPorMz).clamp(0.03, 1.0);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 85,
                              child: Text(pNom, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  minHeight: 14,
                                  backgroundColor: AppColors.azulSoft,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.azul),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 65,
                              child: Text('${fmtEntero.format(pLPorMz.toInt())} L', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 4),
                    const Text(
                      'Litros regados en el ciclo divididos entre el área de cada parcela (1 mz = 0.7 ha).',
                      style: TextStyle(color: AppColors.muted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Oportunidad de Ahorro
            if (ahorroL > 0)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Oportunidad de ahorro', style: TextStyle(fontSize: 13, color: AppColors.muted)),
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${fmtEntero.format(ahorroL.toInt())} L ',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink, fontSize: 16),
                            ),
                            const TextSpan(
                              text: 'se regaron el mismo día o hasta 2 días después de una lluvia de 20 mm o más. Es una estimación orientativa.',
                              style: TextStyle(fontSize: 13, color: AppColors.ink),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 14),

            // Fichas Desglosadas por Parcela
            ...parcelas.map((p) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(p['nombre'] ?? '', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: AppColors.broteSoft, borderRadius: BorderRadius.circular(99)),
                              child: Text(p['cultivo'] ?? '', style: const TextStyle(color: AppColors.brote, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        Text('${p['finca']} · Siembra ${p['fechaSiembra']}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                        const SizedBox(height: 10),
                        _statRow('Riegos', '${p['numRiegos']}'),
                        _statRow('Agua de riego', '${fmtEntero.format((p['litrosRiego'] ?? 0).toInt())} L'),
                        _statRow('Lluvia acumulada', '${fmtDec.format(p['lluviaAcumuladaMm'] ?? 0)} mm'),
                        _statRow('Insumos aplicados', '${fmtEntero.format((p['insumosLb'] ?? 0).toInt())} lb'),
                        _statRow('Labores realizadas', '${p['totalLabores']}'),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String valor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line, width: 0.5))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.ink)),
          Text(valor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.ink)),
        ],
      ),
    );
  }
}
