import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/constants.dart';

class PerfilModal extends StatefulWidget {
  final VoidCallback onPerfilGuardado;

  const PerfilModal({super.key, required this.onPerfilGuardado});

  @override
  State<PerfilModal> createState() => _PerfilModalState();
}

class _PerfilModalState extends State<PerfilModal> {
  late TextEditingController _nombreCtrl;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: AppConstants.userName);
  }

  void _guardar() {
    final nuevo = _nombreCtrl.text.trim();
    if (nuevo.isNotEmpty) {
      AppConstants.userName = nuevo;
      widget.onPerfilGuardado();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado')),
      );
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mi Perfil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.ink)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _nombreCtrl,
            decoration: InputDecoration(
              labelText: 'TU NOMBRE',
              hintText: 'Ej. Iris o Cristin',
              filled: true,
              fillColor: AppColors.surface2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'El nombre aparece en cada registro que hagas, para que el equipo sepa quién anotó qué.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _guardar,
              child: const Text('Guardar'),
            ),
          ),
        ],
      ),
    );
  }
}
