import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import '../models/evento.dart';

class CalendarioScreen extends StatefulWidget {
  final Function(String fecha) onRegistrarDiaTap;

  const CalendarioScreen({super.key, required this.onRegistrarDiaTap});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  final ApiService _api = ApiService();
  bool _cargando = true;
  List<EventoCalendario> _eventos = [];

  DateTime _mesActual = DateTime.now();
  DateTime _diaSeleccionado = DateTime.now();

  @override
  void initState() {
    super.initState();
    _cargarEventos();
  }

  Future<void> _cargarEventos() async {
    setState(() => _cargando = true);
    final list = await _api.fetchCalendario();
    if (mounted) {
      setState(() {
        _eventos = list;
        _cargando = false;
      });
    }
  }

  Color _colorDot(String tipo) {
    switch (tipo) {
      case 'riego': return AppColors.azul;
      case 'lluvia': return AppColors.lluvia;
      case 'insumo': return AppColors.brote;
      case 'labor': return AppColors.tierra;
      default: return AppColors.alerta;
    }
  }

  void _cambiarMes(int delta) {
    setState(() {
      _mesActual = DateTime(_mesActual.year, _mesActual.month + delta, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mesStr = DateFormat("MMMM yyyy", 'es').format(_mesActual);
    final mesCap = mesStr.isNotEmpty ? mesStr[0].toUpperCase() + mesStr.substring(1) : '';

    final fechaSelStr = DateFormat('yyyy-MM-dd').format(_diaSeleccionado);
    final eventosDelDia = _eventos.where((e) => e.fecha == fechaSelStr).toList();
    eventosDelDia.sort((a, b) => (b.real ? 1 : 0).compareTo(a.real ? 1 : 0));

    final diaLabel = DateFormat("EEEE d 'de' MMMM", 'es').format(_diaSeleccionado);
    final diaLabelCap = diaLabel.isNotEmpty ? diaLabel[0].toUpperCase() + diaLabel.substring(1) : '';

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.azul,
        onRefresh: _cargarEventos,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
          children: [
            const Text('Calendario', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.ink)),
            const SizedBox(height: 12),

            // Navegación de Mes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _cambiarMes(-1),
                  icon: const Icon(Icons.chevron_left),
                  style: IconButton.styleFrom(backgroundColor: AppColors.surface),
                ),
                Text(mesCap, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink)),
                IconButton(
                  onPressed: () => _cambiarMes(1),
                  icon: const Icon(Icons.chevron_right),
                  style: IconButton.styleFrom(backgroundColor: AppColors.surface),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Encabezados Días de Semana
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                  .map((w) => SizedBox(
                        width: 36,
                        child: Text(w, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.muted, fontSize: 12)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 6),

            // Cuadrícula de 42 días
            _buildMatrizCalendario(),
            const SizedBox(height: 14),

            // Leyenda
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _leyendaItem(AppColors.azul, 'Riego'),
                _leyendaItem(AppColors.lluvia, 'Lluvia'),
                _leyendaItem(AppColors.brote, 'Insumo'),
                _leyendaItem(AppColors.tierra, 'Labor'),
                _leyendaItem(AppColors.alerta, 'Siembra / Cosecha'),
              ],
            ),
            const SizedBox(height: 20),

            // Detalle del Día Seleccionado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(diaLabelCap, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink)),
                ),
                TextButton(
                  onPressed: () => widget.onRegistrarDiaTap(fechaSelStr),
                  child: const Text('Registrar este día', style: TextStyle(color: AppColors.azul, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_cargando)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (eventosDelDia.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text('Sin eventos este día.', style: TextStyle(color: AppColors.muted, fontSize: 13.5)),
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Column(
                    children: eventosDelDia.map((e) => _buildEventoItem(e)).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatrizCalendario() {
    final firstDayMonth = DateTime(_mesActual.year, _mesActual.month, 1);
    final weekdayOffset = (firstDayMonth.weekday - 1) % 7; // Lunes = 0
    final startDate = firstDayMonth.subtract(Duration(days: weekdayOffset));

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final selStr = DateFormat('yyyy-MM-dd').format(_diaSeleccionado);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 42,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemBuilder: (context, index) {
        final cellDate = startDate.add(Duration(days: index));
        final cellDateStr = DateFormat('yyyy-MM-dd').format(cellDate);
        final esMesActual = cellDate.month == _mesActual.month;
        final esHoy = cellDateStr == todayStr;
        final esSeleccionado = cellDateStr == selStr;

        final evs = _eventos.where((e) => e.fecha == cellDateStr).toList();
        final tipos = evs.map((e) => e.tipo).toSet().toList();

        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() {
              _diaSeleccionado = cellDate;
              if (cellDate.month != _mesActual.month) {
                _mesActual = DateTime(cellDate.year, cellDate.month, 1);
              }
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: esSeleccionado ? AppColors.azul : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: esHoy && !esSeleccionado ? Border.all(color: AppColors.azul, width: 1.5) : Border.all(color: Colors.transparent),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${cellDate.day}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: esSeleccionado ? Colors.white : (esMesActual ? AppColors.ink : AppColors.muted.withValues(alpha: 0.5)),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: tipos.take(3).map((t) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: esSeleccionado ? Colors.white : _colorDot(t),
                        shape: BoxShape.circle,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _leyendaItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ],
    );
  }

  Widget _buildEventoItem(EventoCalendario e) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line, width: 0.5))),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: e.real ? _colorDot(e.tipo) : Colors.transparent,
              border: Border.all(color: _colorDot(e.tipo), width: e.real ? 0 : 2),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(e.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                ),
                if (!e.real)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Estimado', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.muted)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
