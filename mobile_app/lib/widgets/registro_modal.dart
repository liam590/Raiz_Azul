import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/offline_api_service.dart';
import '../models/parcela.dart';
import '../features/auth/providers/auth_provider.dart';

class RegistroModal extends StatefulWidget {
  final dynamic initialParcelaId;
  final String? initialFecha;
  final VoidCallback onRegistroGuardado;

  const RegistroModal({
    super.key,
    this.initialParcelaId,
    this.initialFecha,
    required this.onRegistroGuardado,
  });

  @override
  State<RegistroModal> createState() => _RegistroModalState();
}

class _RegistroModalState extends State<RegistroModal> {
  final _formKey = GlobalKey<FormState>();
  final OfflineApiService _api = OfflineApiService();

  String _tipo = 'riego'; // 'riego', 'lluvia', 'labor', 'insumo'
  dynamic _parcelaSeleccionada;
  DateTime _fecha = DateTime.now();
  List<DateTime> _fechasRiego = [];
  String _metodoRiego = 'Goteo';
  
  final TextEditingController _valorCtrl = TextEditingController();
  final TextEditingController _duracionCtrl = TextEditingController();
  final TextEditingController _detalleCtrl = TextEditingController();
  final TextEditingController _notaCtrl = TextEditingController();

  bool _cargandoParcelas = true;
  bool _guardando = false;
  List<Parcela> _parcelas = [];

  final List<String> _insumos = ['Urea 46%', 'Fórmula 12-30-10', 'Fórmula 15-15-15', 'Abono orgánico', 'Fungicida', 'Insecticida'];
  final List<String> _labores = ['Deshierbe', 'Aporque', 'Poda', 'Control de plagas', 'Control de enfermedades', 'Cosecha', 'Otra'];
  final List<String> _metodosRiego = ['Goteo', 'Aspersión', 'Gravedad', 'Manual', 'Otro'];

  @override
  void initState() {
    super.initState();
    if (widget.initialFecha != null) {
      _fecha = DateTime.tryParse(widget.initialFecha!) ?? DateTime.now();
    }
    _fechasRiego = [_fecha];
    _cargarParcelas();
  }

  @override
  void dispose() {
    _valorCtrl.dispose();
    _duracionCtrl.dispose();
    _detalleCtrl.dispose();
    _notaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarParcelas() async {
    final list = await _api.fetchParcelas();
    if (mounted) {
      setState(() {
        _parcelas = list;
        _cargandoParcelas = false;
        final inicialExiste = widget.initialParcelaId != null &&
            _parcelas.any((p) => p.id == widget.initialParcelaId);
        if (inicialExiste) {
          _parcelaSeleccionada = widget.initialParcelaId;
        } else if (_parcelas.isNotEmpty) {
          _parcelaSeleccionada = _parcelas.first.id;
        }
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_tipo == 'riego' && _fechasRiego.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.alerta,
          content: Text('Agrega al menos un día de riego'),
        ),
      );
      return;
    }

    setState(() => _guardando = true);
    final valor = double.tryParse(_valorCtrl.text.trim()) ?? 0.0;
    final fechas = _tipo == 'riego'
        ? _fechasRiego.map((d) => DateFormat('yyyy-MM-dd').format(d)).toList()
        : [DateFormat('yyyy-MM-dd').format(_fecha)];
    final duracion = int.tryParse(_duracionCtrl.text.trim());

    final resultado = await _api.crearRegistro(
      idParcela: _parcelaSeleccionada,
      idFinca: _idFincaSeleccionada(),
      tipo: _tipo,
      fecha: fechas.first,
      fechas: fechas,
      valor: _tipo == 'labor' ? 0.0 : valor,
      detalle: _detalleCtrl.text.trim(),
      nota: _notaCtrl.text.trim(),
      autor: context.read<AuthProvider>().user?.nombreCompleto ?? 'Usuario',
      metodoRiego: _tipo == 'riego' ? _metodoRiego : null,
      duracionMinutos: _tipo == 'riego' ? duracion : null,
      grupoRiego: (_tipo == 'riego' && fechas.length > 1)
          ? DateTime.now().microsecondsSinceEpoch.toString()
          : null,
    );

    if (mounted) {
      setState(() => _guardando = false);
      if (resultado.success) {
        Navigator.pop(context);
        widget.onRegistroGuardado();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.brote,
            content: Text(resultado.message),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.alerta,
            content: Text(resultado.message),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoParcelas) {
      return Container(
        height: 250,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(child: CircularProgressIndicator(color: AppColors.azul)),
      );
    }

    if (_parcelas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Primero crea una parcela', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Los registros se anotan sobre una parcela existente.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Nuevo Registro', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.ink)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 12),

              // Segmented Tabs de Tipo
              Row(
                children: [
                  _tipoBtn('riego', 'Riego', Icons.water_drop),
                  const SizedBox(width: 6),
                  _tipoBtn('lluvia', 'Lluvia', Icons.cloud),
                  const SizedBox(width: 6),
                  _tipoBtn('labor', 'Labor', Icons.build),
                  const SizedBox(width: 6),
                  _tipoBtn('insumo', 'Insumo', Icons.eco),
                ],
              ),
              const SizedBox(height: 14),

              // Selector de Parcela o Finca
              DropdownButtonFormField<dynamic>(
                key: ValueKey('parcela_$_tipo'),
                initialValue: _parcelaSeleccionada,
                decoration: InputDecoration(
                  labelText: 'PARCELA',
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)),
                ),
                items: [
                  ..._parcelas.map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text('${p.nombre} · ${p.cultivo}', overflow: TextOverflow.ellipsis),
                      )),
                  if (_tipo == 'lluvia')
                    ...{for (var p in _parcelas) p.finca}.map((finca) => DropdownMenuItem(
                          value: 'finca:$finca',
                          child: Text('Toda la finca $finca', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.lluvia)),
                        )),
                ],
                onChanged: (v) => setState(() => _parcelaSeleccionada = v),
              ),
              const SizedBox(height: 12),

              // Selector de fecha única o fechas múltiples para riego
              if (_tipo == 'riego') _buildFechasRiego() else _buildFechaUnica(),
              const SizedBox(height: 12),

              // Campos Dinámicos según Tipo
              if (_tipo == 'riego') ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        initialValue: _metodoRiego,
                        decoration: InputDecoration(
                          labelText: 'MÉTODO DE RIEGO',
                          filled: true,
                          fillColor: AppColors.surface2,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)),
                        ),
                        items: _metodosRiego.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                        onChanged: (v) => setState(() => _metodoRiego = v ?? 'Goteo'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _duracionCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'MINUTOS/DÍA',
                          hintText: 'Ej. 45',
                          filled: true,
                          fillColor: AppColors.surface2,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)),
                        ),
                        validator: (v) {
                          final texto = (v ?? '').trim();
                          if (texto.isEmpty) return null;
                          final n = int.tryParse(texto);
                          return (n == null || n <= 0) ? 'Mayor a 0' : null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _valorCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'AGUA POR DÍA (LITROS)',
                    hintText: 'Ej. 4500',
                    filled: true,
                    fillColor: AppColors.surface2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)),
                  ),
                  validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Indica los litros regados' : null,
                ),
                if (_fechasRiego.length > 1) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Se guardará el mismo volumen y duración en cada día seleccionado.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.muted),
                  ),
                ],
              ]
              else if (_tipo == 'lluvia')
                TextFormField(
                  controller: _valorCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'LLUVIA CAÍDA (MM)',
                    hintText: 'Ej. 18.5',
                    filled: true,
                    fillColor: AppColors.surface2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)),
                  ),
                  validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Indica los mm de lluvia' : null,
                )
              else if (_tipo == 'insumo')
                Column(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'INSUMO',
                        filled: true,
                        fillColor: AppColors.surface2,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)),
                      ),
                      items: _insumos.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
                      onChanged: (v) => _detalleCtrl.text = v ?? '',
                      validator: (v) => (v == null || v.isEmpty) ? 'Selecciona un insumo' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _valorCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'CANTIDAD (LIBRAS)',
                        hintText: 'Ej. 80',
                        filled: true,
                        fillColor: AppColors.surface2,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)),
                      ),
                      validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Indica las libras aplicadas' : null,
                    ),
                  ],
                )
              else
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'LABOR REALIZADA',
                    filled: true,
                    fillColor: AppColors.surface2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)),
                  ),
                  items: _labores.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                  onChanged: (v) => _detalleCtrl.text = v ?? '',
                  validator: (v) => (v == null || v.isEmpty) ? 'Selecciona una labor' : null,
                ),

              const SizedBox(height: 12),

              // Nota opcional
              TextFormField(
                controller: _notaCtrl,
                decoration: InputDecoration(
                  labelText: 'NOTA (OPCIONAL)',
                  hintText: _tipo == 'riego'
                      ? 'Ej. riego por la mañana'
                      : 'Ej. observaciones del registro',
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)),
                ),
              ),

              const SizedBox(height: 20),

              // Botón Guardar
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Guardar registro'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFechasRiego() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'DÍAS DE RIEGO',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.muted),
                ),
              ),
              TextButton.icon(
                onPressed: _agregarFechaRiego,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Agregar día', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.azul,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _fechasRiego.map((d) {
              final bool esUnica = _fechasRiego.length == 1;
              return Container(
                padding: const EdgeInsets.only(left: 10, right: 4, top: 2, bottom: 2),
                decoration: BoxDecoration(
                  color: AppColors.azulSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.azul.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _editarFechaRiego(d),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(d),
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.azulDeep),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: esUnica ? null : () => _quitarFecha(d),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: esUnica ? AppColors.muted.withValues(alpha: 0.4) : AppColors.azulDeep,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          const Text(
            'Puedes registrar el mismo riego en varios días.',
            style: TextStyle(fontSize: 11.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildFechaUnica() {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final pick = await showDatePicker(
          context: context,
          initialDate: _fecha,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (pick != null) setState(() => _fecha = pick);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('FECHA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.muted)),
                const SizedBox(height: 2),
                Text(DateFormat('dd/MM/yyyy').format(_fecha), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            const Icon(Icons.calendar_today, color: AppColors.azul, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _agregarFechaRiego() async {
    final ahora = DateTime.now();
    final pick = await showDatePicker(
      context: context,
      initialDate: _fecha.isAfter(ahora) ? ahora : _fecha,
      firstDate: DateTime(2020),
      lastDate: ahora,
      helpText: 'Selecciona un día de riego',
    );
    if (pick == null) return;

    setState(() {
      if (!_fechasRiego.any((d) => _sameDay(d, pick))) {
        _fechasRiego.add(pick);
        _fechasRiego.sort((a, b) => a.compareTo(b));
      }
    });
  }

  Future<void> _editarFechaRiego(DateTime original) async {
    final ahora = DateTime.now();
    final pick = await showDatePicker(
      context: context,
      initialDate: original.isAfter(ahora) ? ahora : original,
      firstDate: DateTime(2020),
      lastDate: ahora,
      helpText: 'Cambiar día de riego',
    );
    if (pick == null) return;

    setState(() {
      final idx = _fechasRiego.indexWhere((d) => _sameDay(d, original));
      if (idx == -1) return;

      final yaExiste = _fechasRiego.any(
        (d) => _sameDay(d, pick) && !_sameDay(d, original),
      );
      if (yaExiste) return;

      _fechasRiego[idx] = pick;
      _fechasRiego.sort((a, b) => a.compareTo(b));
    });
  }

  void _quitarFecha(DateTime fecha) {
    if (_fechasRiego.length <= 1) return;
    setState(() => _fechasRiego.removeWhere((d) => _sameDay(d, fecha)));
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  int _idFincaSeleccionada() {
    final sel = _parcelaSeleccionada;

    if (sel is String && sel.startsWith('finca:')) {
      final nombre = sel.substring('finca:'.length);
      final match = _parcelas.where((p) => p.finca == nombre);
      if (match.isNotEmpty) {
        return int.tryParse(match.first.idFinca.toString()) ?? 1;
      }
    }

    final parcela = _parcelas.where((p) => p.id == sel);
    if (parcela.isNotEmpty) {
      return int.tryParse(parcela.first.idFinca.toString()) ?? 1;
    }
    return 1;
  }

  Widget _tipoBtn(String tipoId, String label, IconData icon) {
    final bool activo = _tipo == tipoId;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() {
            _tipo = tipoId;
            _valorCtrl.clear();
            _duracionCtrl.clear();
            _detalleCtrl.clear();

            if (tipoId == 'riego' && _fechasRiego.isEmpty) {
              _fechasRiego = [_fecha];
            }

            // "Toda la finca" solo aplica a lluvia; al cambiar de tipo
            // volvemos a una parcela válida para el selector.
            if (tipoId != 'lluvia' &&
                _parcelaSeleccionada is String &&
                (_parcelaSeleccionada as String).startsWith('finca:')) {
              _parcelaSeleccionada = _parcelas.isNotEmpty ? _parcelas.first.id : null;
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: activo ? AppColors.azulSoft : AppColors.surface2,
            border: Border.all(color: activo ? AppColors.azul : AppColors.line),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: activo ? AppColors.azul : AppColors.muted),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: activo ? AppColors.azul : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
