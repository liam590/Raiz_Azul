import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/api_service.dart';
import '../models/alerta.dart';
import '../models/registro.dart';

class InicioScreen extends StatefulWidget {
  final VoidCallback onNuevaParcelaTap;
  final Function(dynamic parcelaId) onParcelaTap;

  const InicioScreen({
    super.key,
    required this.onNuevaParcelaTap,
    required this.onParcelaTap,
  });

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  final ApiService _api = ApiService();
  bool _cargando = true;
  Map<String, dynamic> _dashboard = {};

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    final data = await _api.fetchDashboard();
    if (mounted) {
      setState(() {
        _dashboard = data;
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

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: AppColors.azul));
    }

    final int totalParcelas = _dashboard['totalParcelas'] ?? 0;
    final double litros7 = _dashboard['litrosRegados7Dias'] ?? 0.0;
    final int totalAlertas = _dashboard['totalAlertas'] ?? 0;
    final double ahorroL = _dashboard['ahorroPotencialLitros'] ?? 0.0;
    final List<Alerta> alertas = _dashboard['alertas'] ?? [];
    final List<Registro> actividad = _dashboard['actividadReciente'] ?? [];

    final now = DateTime.now();
    final fechaHoy = DateFormat("EEEE d 'de' MMMM", 'es').format(now);
    final fechaCap = fechaHoy.isNotEmpty ? fechaHoy[0].toUpperCase() + fechaHoy.substring(1) : '';

    return RefreshIndicator(
      color: AppColors.azul,
      onRefresh: _cargarDatos,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        children: [
          // Tarjeta Principal "Hoy"
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.azul,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.azul.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fechaCap,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Text(
                  'Hola, ${AppConstants.userName}. ${totalParcelas > 0 ? (totalAlertas > 0 ? "$totalAlertas ${totalAlertas == 1 ? 'aviso necesita' : 'avisos necesitan'} atención hoy" : "Ninguna parcela necesita atención hoy") : "Empieza registrando una parcela"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _kpiItem('$totalParcelas', 'parcelas'),
                    const SizedBox(width: 24),
                    _kpiItem(NumberFormat.decimalPattern('es').format(litros7.toInt()), 'L regados en 7 días'),
                    const SizedBox(width: 24),
                    _kpiItem('$totalAlertas', 'avisos activos'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tarjeta de Oportunidad de Ahorro (si existe)
          if (ahorroL > 0)
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Riego posiblemente evitable', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${NumberFormat.decimalPattern('es').format(ahorroL.toInt())} L',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.lluvia,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'regados tras lluvia de 20 mm o más.',
                            style: TextStyle(color: AppColors.muted, fontSize: 13),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Sección de Recomendaciones Agronómicas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recomendaciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink)),
              if (alertas.isNotEmpty)
                Text('${alertas.length} activas', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),

          if (alertas.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppColors.brote, size: 40),
                    const SizedBox(height: 8),
                    const Text('Todo al día', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      totalParcelas > 0
                          ? 'Las recomendaciones aparecen cuando toca regar, fertilizar o cosechar.'
                          : 'Crea una parcela en la pestaña Parcelas para recibir recomendaciones.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            ...alertas.take(5).map((alerta) => _buildAlertaCard(alerta)),

          const SizedBox(height: 6),
          const Text(
            'Son sugerencias orientativas. La decisión final es del productor o del técnico.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),

          const SizedBox(height: 20),

          // Sección de Actividad del Equipo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Actividad del equipo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink)),
              Text(
                _dashboard['isSqlServer'] == true ? 'SQL Server' : 'Modo Local',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _dashboard['isSqlServer'] == true ? AppColors.brote : AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (actividad.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: const [
                    Icon(Icons.notes, color: AppColors.muted, size: 40),
                    SizedBox(height: 8),
                    Text('Sin registros recientes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 4),
                    Text(
                      'Toca el botón central "Registrar" para anotar un riego, lluvia, labor o insumo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  children: actividad.map((reg) => _buildActividadItem(reg)).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _kpiItem(String valor, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(valor, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildAlertaCard(Alerta alerta) {
    final bool esAlerta = alerta.nivel == 'alerta';
    final Color colorNivel = esAlerta ? AppColors.alerta : (alerta.nivel == 'ok' ? AppColors.brote : AppColors.azul);
    final Color colorBg = esAlerta ? AppColors.alertaSoft : (alerta.nivel == 'ok' ? AppColors.broteSoft : AppColors.azulSoft);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (alerta.parcelaId != null) widget.onParcelaTap(alerta.parcelaId);
        },
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
                      '${alerta.parcelaNombre ?? "Parcela"} · ${alerta.cultivo ?? ""}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12.5, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: colorBg, borderRadius: BorderRadius.circular(99)),
                    child: Text(
                      esAlerta ? 'Atención' : (alerta.nivel == 'ok' ? 'Al día' : 'Información'),
                      style: TextStyle(color: colorNivel, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 6),
              Text(
                alerta.titulo,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
              const SizedBox(height: 3),
              Text(
                alerta.descripcion,
                style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActividadItem(Registro reg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line, width: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _colorDot(reg.tipo),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reg.textoPrincipal, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  '${reg.destino} · ${reg.fecha} · ${reg.autor}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
