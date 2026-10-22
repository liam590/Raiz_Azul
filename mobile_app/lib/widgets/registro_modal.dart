import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/api_service.dart';
import '../models/parcela.dart';

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
  final ApiService _api = ApiService();

  String _tipo = 'riego'; // 'riego', 'lluvia', 'labor', 'insumo'
  dynamic _parcelaSeleccionada;
  DateTime _fecha = DateTime.now();
  
  final TextEditingController _valorCtrl = TextEditingController();
  final TextEditingController _detalleCtrl = TextEditingController();
  final TextEditingController _notaCtrl = TextEditingController();

  bool _cargandoParcelas = true;
  bool _guardando = false;
  List<Parcela> _parcelas = [];

  final List<String> _insumos = ['Urea 46%', 'Fórmula 12-30-10', 'Fórmula 15-15-15', 'Abono orgánico', 'Fungicida', 'Insecticida'];
  final List<String> _labores = ['Deshierbe', 'Aporque', 'Poda', 'Control de plagas', 'Control de enfermedades', 'Cosecha', 'Otra'];

  @override
  void initState() {
    super.initState();
    if (widget.initialFecha != null) {
      _fecha = DateTime.tryParse(widget.initialFecha!) ?? DateTime.now();
    }
    _cargarParcelas();
  }

  Future<void> _cargarParcelas() async {
    final list = await _api.fetchParcelas();
    if (mounted) {
      setState(() {
        _parcelas = list;
        _cargandoParcelas = false;
        if (widget.initialParcelaId != null) {
          _parcelaSeleccionada = widget.initialParcelaId;
        } else if (_parcelas.isNotEmpty) {
          _parcelaSeleccionada = _parcelas.first.id;
        }
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    final valor = double.tryParse(_valorCtrl.text.trim()) ?? 0.0;
    final fechaStr = DateFormat('yyyy-MM-dd').format(_fecha);

    final resultado = await _api.crearRegistro(
      idParcela: _parcelaSeleccionada,
      tipo: _tipo,
      fecha: fechaStr,
      valor: _tipo == 'labor' ? 0.0 : valor,
      detalle: _detalleCtrl.text.trim(),
      nota: _notaCtrl.text.trim(),
      autor: AppConstants.userName,
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

              // Selector de Fecha
              InkWell(
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
              ),
              const SizedBox(height: 12),

              // Campos Dinámicos según Tipo
              if (_tipo == 'riego')
                TextFormField(
                  controller: _valorCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'AGUA USADA (LITROS)',
                    hintText: 'Ej. 4500',
                    filled: true,
                    fillColor: AppColors.surface2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)),
                  ),
                  validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Indica los litros regados' : null,
                )
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
                  hintText: 'Ej. riego por goteo, 2 horas',
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

  Widget _tipoBtn(String tipoId, String label, IconData icon) {
    final bool activo = _tipo == tipoId;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() {
            _tipo = tipoId;
            _valorCtrl.clear();
            _detalleCtrl.clear();
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
