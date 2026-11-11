import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';
import '../models/registro.dart';

class ExportService {
  static final ExportService _instance = ExportService._();
  factory ExportService() => _instance;
  ExportService._();

  Future<void> exportReportToPdf({
    required Map<String, dynamic> reporte,
    required List<dynamic> parcelasData, // List<Map> from report with computed fields
    required List<Registro> registros,
    String? filename,
  }) async {
    final pdf = pw.Document();
    final fmtEntero = NumberFormat.decimalPattern('es');
    final fmtDec = NumberFormat('#,##0.0', 'es');
    final fmtFecha = DateFormat('dd/MM/yyyy', 'es');

    final double totalAgua = (reporte['totalAguaRiego'] ?? 0.0).toDouble();
    final double lluviaPromedio = (reporte['lluviaPromedioMm'] ?? 0.0).toDouble();
    final double ahorroL = (reporte['ahorroPotencialLitros'] ?? 0.0).toDouble();
    final fechaGeneracion = DateTime.now();

    // Add page
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => _buildHeader(fechaGeneracion),
        footer: _buildFooter,
        build: (context) => [
          _buildTitle(),
          pw.SizedBox(height: 16),
          _buildResumen(totalAgua, lluviaPromedio, ahorroL, fmtEntero, fmtDec),
          pw.SizedBox(height: 20),
          _buildParcelasTable(parcelasData, fmtEntero, fmtDec),
          pw.SizedBox(height: 20),
          _buildRegistrosTable(registros, fmtEntero, fmtDec, fmtFecha),
        ],
      ),
    );

    await _saveAndOpenFile(
      bytes: await pdf.save(),
      filename: filename ?? 'reporte_raiz_azul_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
      extension: 'pdf',
    );
  }

  Future<void> exportReportToExcel({
    required Map<String, dynamic> reporte,
    required List<dynamic> parcelasData, // List<Map> from report with computed fields
    required List<Registro> registros,
    String? filename,
  }) async {
    final excel = Excel.createExcel();
    final fmtEntero = NumberFormat.decimalPattern('es');
    final fmtDec = NumberFormat('#,##0.0', 'es');
    final fmtFecha = DateFormat('dd/MM/yyyy', 'es');

    final double totalAgua = (reporte['totalAguaRiego'] ?? 0.0).toDouble();
    final double lluviaPromedio = (reporte['lluviaPromedioMm'] ?? 0.0).toDouble();
    final double ahorroL = (reporte['ahorroPotencialLitros'] ?? 0.0).toDouble();

    // Sheet 1: Resumen
    Sheet resumenSheet = excel['Resumen'];
    resumenSheet.appendRow([
      TextCellValue('Raíz Azul - Reporte de Uso Eficiente'),
      TextCellValue(''),
      TextCellValue('Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
    ]);
    resumenSheet.appendRow([]);
    resumenSheet.appendRow([
      TextCellValue('Métrica'),
      TextCellValue('Valor'),
    ]);
    resumenSheet.appendRow([
      TextCellValue('Agua de riego total'),
      TextCellValue('${fmtEntero.format(totalAgua.toInt())} L'),
    ]);
    resumenSheet.appendRow([
      TextCellValue('Lluvia promedio'),
      TextCellValue('${fmtDec.format(lluviaPromedio)} mm'),
    ]);
    resumenSheet.appendRow([
      TextCellValue('Ahorro potencial'),
      TextCellValue('${fmtEntero.format(ahorroL.toInt())} L'),
    ]);

    // Sheet 2: Parcelas
    Sheet parcelasSheet = excel['Parcelas'];
    parcelasSheet.appendRow([
      TextCellValue('Parcela'),
      TextCellValue('Finca'),
      TextCellValue('Cultivo'),
      TextCellValue('Área (mz)'),
      TextCellValue('Siembra'),
      TextCellValue('Riegos'),
      TextCellValue('Agua Riego (L)'),
      TextCellValue('Lluvia (mm)'),
      TextCellValue('Insumos (lb)'),
      TextCellValue('Labores'),
      TextCellValue('L/mz'),
    ]);

    for (final p in parcelasData) {
      parcelasSheet.appendRow([
        TextCellValue(p['nombre'] ?? ''),
        TextCellValue(p['finca'] ?? ''),
        TextCellValue(p['cultivo'] ?? ''),
        TextCellValue((p['areaManzanas'] ?? p['area'] ?? 0.0).toStringAsFixed(1)),
        TextCellValue(p['fechaSiembra'] ?? ''),
        TextCellValue((p['numRiegos'] ?? 0).toString()),
        TextCellValue(fmtEntero.format((p['litrosRiego'] ?? 0).toInt())),
        TextCellValue(fmtDec.format(p['lluviaAcumuladaMm'] ?? 0)),
        TextCellValue(fmtEntero.format((p['insumosLb'] ?? 0).toInt())),
        TextCellValue((p['totalLabores'] ?? 0).toString()),
        TextCellValue(fmtEntero.format((p['litrosPorManzana'] ?? 0).toInt())),
      ]);
    }

    // Sheet 3: Registros
    Sheet registrosSheet = excel['Registros'];
    registrosSheet.appendRow([
      TextCellValue('Fecha'),
      TextCellValue('Parcela'),
      TextCellValue('Tipo'),
      TextCellValue('Valor'),
      TextCellValue('Detalle'),
      TextCellValue('Nota'),
      TextCellValue('Autor'),
    ]);

    for (final r in registros) {
      String valorStr;
      if (r.tipo == 'riego') {
        valorStr = '${fmtEntero.format(r.valor.toInt())} L';
      } else if (r.tipo == 'lluvia') {
        valorStr = '${fmtDec.format(r.valor)} mm';
      } else if (r.tipo == 'insumo') {
        valorStr = '${fmtDec.format(r.valor)} lb';
      } else {
        valorStr = r.detalle.isNotEmpty ? r.detalle : 'Labor';
      }

      registrosSheet.appendRow([
        TextCellValue(fmtFecha.format(DateTime.tryParse(r.fecha) ?? DateTime.now())),
        TextCellValue(r.destino),
        TextCellValue(r.tipo),
        TextCellValue(valorStr),
        TextCellValue(r.detalle.isNotEmpty ? r.detalle : (r.tipo == 'labor' ? 'Labor' : '-')),
        TextCellValue(r.nota),
        TextCellValue(r.autor),
      ]);
    }

    // Style headers
    _styleHeaderRow(resumenSheet, 1);
    _styleHeaderRow(parcelasSheet, 0);
    _styleHeaderRow(registrosSheet, 0);

    // Set column widths
    for (var i = 0; i < 11; i++) {
      parcelasSheet.setColumnWidth(i, 18);
    }
    for (var i = 0; i < 7; i++) {
      registrosSheet.setColumnWidth(i, 18);
    }

    final bytes = excel.encode();
    if (bytes == null) throw Exception('Error generando Excel');

    await _saveAndOpenFile(
      bytes: bytes,
      filename: filename ?? 'reporte_raiz_azul_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx',
      extension: 'xlsx',
    );
  }

  void _styleHeaderRow(Sheet sheet, int rowIndex) {
    final row = sheet.rows[rowIndex];
    for (final cell in row) {
      cell?.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1463A5'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );
    }
  }

  pw.Widget _buildHeader(DateTime fecha) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Raíz Azul',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF1463A5),
                ),
              ),
              pw.Text(
                'Uso eficiente del agua y manejo responsable de cultivos',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.Text(
            'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(fecha)}',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Raíz Azul - Universidad Nacional Héroes San José de las Mulas',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTitle() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Reporte de Uso Eficiente del Agua',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Desde la siembra hasta la fecha actual',
          style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
        ),
      ],
    );
  }

  pw.Widget _buildResumen(
    double totalAgua,
    double lluviaPromedio,
    double ahorroL,
    NumberFormat fmtEntero,
    NumberFormat fmtDec,
  ) {
    return pw.Row(
      children: [
        _buildKpiCard('Agua de riego total', '${fmtEntero.format(totalAgua.toInt())} L', PdfColor.fromInt(0xFF1463A5)),
        pw.SizedBox(width: 12),
        _buildKpiCard('Lluvia promedio', '${fmtDec.format(lluviaPromedio)} mm', PdfColor.fromInt(0xFF14808F)),
        pw.SizedBox(width: 12),
        _buildKpiCard('Ahorro potencial', '${fmtEntero.format(ahorroL.toInt())} L', PdfColor.fromInt(0xFF2F7F45)),
      ],
    );
  }

  pw.Widget _buildKpiCard(String title, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: color, width: 1.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildParcelasTable(List<dynamic> parcelasData, NumberFormat fmtEntero, NumberFormat fmtDec) {
    if (parcelasData.isEmpty) {
      return pw.Text('No hay parcelas registradas', style: pw.TextStyle(color: PdfColors.grey600));
    }

    final headers = ['Parcela', 'Finca', 'Cultivo', 'Área (mz)', 'Siembra', 'Riegos', 'Riego (L)', 'Lluvia (mm)', 'Insumos (lb)', 'Labores', 'L/mz'];
    final rows = <List<String>>[];

    for (final p in parcelasData) {
      rows.add([
        p['nombre'] ?? '',
        p['finca'] ?? '',
        p['cultivo'] ?? '',
        (p['areaManzanas'] ?? p['area'] ?? 0.0).toStringAsFixed(1),
        p['fechaSiembra'] ?? '',
        (p['numRiegos'] ?? 0).toString(),
        fmtEntero.format((p['litrosRiego'] ?? 0).toInt()),
        fmtDec.format(p['lluviaAcumuladaMm'] ?? 0),
        fmtEntero.format((p['insumosLb'] ?? 0).toInt()),
        (p['totalLabores'] ?? 0).toString(),
        fmtEntero.format((p['litrosPorManzana'] ?? 0).toInt()),
      ]);
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(1.2),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(0.7),
        4: const pw.FlexColumnWidth(1),
        5: const pw.FlexColumnWidth(0.6),
        6: const pw.FlexColumnWidth(0.8),
        7: const pw.FlexColumnWidth(0.7),
        8: const pw.FlexColumnWidth(0.7),
        9: const pw.FlexColumnWidth(0.6),
        10: const pw.FlexColumnWidth(0.7),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1463A5)),
          children: headers.map((h) => pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(h, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
          )).toList(),
        ),
        ...rows.map((row) => pw.TableRow(
          children: row.map((c) => pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(c, style: pw.TextStyle(fontSize: 8, color: PdfColors.black)),
          )).toList(),
        )),
      ],
    );
  }

  pw.Widget _buildRegistrosTable(List<Registro> registros, NumberFormat fmtEntero, NumberFormat fmtDec, DateFormat fmtFecha) {
    if (registros.isEmpty) {
      return pw.Text('No hay registros en el período', style: pw.TextStyle(color: PdfColors.grey600));
    }

    // Limit to last 50 registros for PDF
    final displayRegistros = registros.take(50).toList();

    final headers = ['Fecha', 'Parcela', 'Tipo', 'Valor', 'Detalle', 'Autor'];
    final rows = <List<String>>[];

    for (final r in displayRegistros) {
      String valorStr;
      if (r.tipo == 'riego') {
        valorStr = '${fmtEntero.format(r.valor.toInt())} L';
      } else if (r.tipo == 'lluvia') {
        valorStr = '${fmtDec.format(r.valor)} mm';
      } else if (r.tipo == 'insumo') {
        valorStr = '${fmtDec.format(r.valor)} lb';
      } else {
        valorStr = r.detalle.isNotEmpty ? r.detalle : 'Labor';
      }

      rows.add([
        fmtFecha.format(DateTime.tryParse(r.fecha) ?? DateTime.now()),
        r.destino,
        r.tipo.toUpperCase(),
        valorStr,
        r.detalle.isNotEmpty ? r.detalle : (r.tipo == 'labor' ? 'Labor' : '-'),
        r.autor,
      ]);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Últimos ${displayRegistros.length} registros de campo',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
            1: const pw.FlexColumnWidth(1.2),
            2: const pw.FlexColumnWidth(0.8),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1.5),
            5: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1463A5)),
              children: headers.map((h) => pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(h, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              )).toList(),
            ),
            ...rows.map((row) => pw.TableRow(
              children: row.map((c) => pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(c, style: pw.TextStyle(fontSize: 8, color: PdfColors.black)),
              )).toList(),
            )),
          ],
        ),
        if (registros.length > 50)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 8),
            child: pw.Text(
              'Mostrando 50 de ${registros.length} registros. Exporta a Excel para ver todos.',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
            ),
          ),
      ],
    );
  }

  Future<void> _saveAndOpenFile({
    required List<int> bytes,
    required String filename,
    required String extension,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    
    await OpenFilex.open(file.path);
  }
}