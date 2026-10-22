import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/api_service.dart';

class NuevaParcelaModal extends StatefulWidget {
  final VoidCallback onParcelaCreada;

  const NuevaParcelaModal({super.key, required this.onParcelaCreada});

  @override
  State<NuevaParcelaModal> createState() => _NuevaParcelaModalState();
}

class _NuevaParcelaModalState extends State<NuevaParcelaModal> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();

  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _fincaCtrl = TextEditingController(text: 'La Esperanza');
  final TextEditingController _areaCtrl = TextEditingController(text: '1.5');
  
  String _zona = 'Matagalpa';
  String _cultivo = 'Tomate';
  DateTime _fechaSiembra = DateTime.now();
  bool _guardando = false;

  final List<String> _zonas = ['Matagalpa', 'Jinotega', 'Chontales', 'Boaco', 'Estelí', 'Nueva Segovia', 'Otra'];
  final List<String> _cultivos = ['Tomate', 'Chile', 'Repollo', 'Maíz', 'Frijol'];

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    final area = double.tryParse(_areaCtrl.text.trim()) ?? 1.0;
    final fechaStr = DateFormat('yyyy-MM-dd').format(_fechaSiembra);

    final resultado = await _api.crearParcela(
      nombre: _nombreCtrl.text.trim(),
      finca: _fincaCtrl.text.trim(),
      zona: _zona,
      cultivo: _cultivo,
      area: area,
      siembra: fechaStr,
    );

    if (mounted) {
      setState(() => _guardando = false);
      if (resultado.success) {
        Navigator.pop(context);
        widget.onParcelaCreada();
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
                  const Text('Nueva Parcela', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.ink)),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Nombre de la parcela
              TextFormField(
                controller: _nombreCtrl,
                decoration: InputDecoration(
                  labelText: 'NOMBRE DE LA PARCELA',
                  hintText: 'Ej. Lote Alto',
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe el nombre de la parcela' : null,
              ),
              const SizedBox(height: 12),

              // Finca y Zona
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fincaCtrl,
                      decoration: InputDecoration(
                        labelText: 'FINCA',
                        filled: true,
                        fillColor: AppColors.surface2,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Indica la finca' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _zona,
                      decoration: InputDecoration(
                        labelText: 'ZONA',
                        filled: true,
                        fillColor: AppColors.surface2,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)),
                      ),
                      items: _zonas.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                      onChanged: (v) => setState(() => _zona = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Cultivo y Área
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _cultivo,
                      decoration: InputDecoration(
                        labelText: 'CULTIVO',
                        filled: true,
                        fillColor: AppColors.surface2,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)),
                      ),
                      items: _cultivos.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _cultivo = v!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _areaCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'ÁREA (MZ)',
                        filled: true,
                        fillColor: AppColors.surface2,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)),
                      ),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Mayor a 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Fecha de Siembra
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  final pick = await showDatePicker(
                    context: context,
                    initialDate: _fechaSiembra,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (pick != null) setState(() => _fechaSiembra = pick);
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
                          const Text('FECHA DE SIEMBRA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.muted)),
                          const SizedBox(height: 2),
                          Text(DateFormat('dd/MM/yyyy').format(_fechaSiembra), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Icon(Icons.calendar_today, color: AppColors.azul, size: 20),
                    ],
                  ),
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
                      : const Text('Crear parcela'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
