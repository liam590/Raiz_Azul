import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import '../features/auth/providers/auth_provider.dart';
import 'inicio_screen.dart';
import 'parcelas_screen.dart';
import 'calendario_screen.dart';
import 'reportes_screen.dart';
import '../widgets/registro_modal.dart';
import '../widgets/nueva_parcela_modal.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentTab = 0; // 0: Inicio, 1: Parcelas, 2: Calendario, 3: Reportes
  bool _conectado = true;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _verificarConexion();
  }

  Future<void> _verificarConexion() async {
    final ok = await _api.checkConnection();
    if (mounted) {
      setState(() => _conectado = ok);
    }
  }

  void _abrirRegistro({dynamic parcelaId, String? fecha}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RegistroModal(
        initialParcelaId: parcelaId,
        initialFecha: fecha,
        onRegistroGuardado: () {
          _verificarConexion();
          setState(() {});
        },
      ),
    );
  }

  void _abrirNuevaParcela() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NuevaParcelaModal(
        onParcelaCreada: () {
          _verificarConexion();
          setState(() {});
        },
      ),
    );
  }

  void _abrirPerfil() {
    context.push('/profile');
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final String initial = (user?.nombreCompleto.trim().isNotEmpty ?? false)
        ? user!.nombreCompleto.trim()[0].toUpperCase()
        : 'P';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            // Logo Gota Raíz Azul
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.azul,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.water_drop, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              'Raíz Azul',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.ink),
            ),
          ],
        ),
        actions: [
          // Chip de Conexión Dinámico
          InkWell(
            borderRadius: BorderRadius.circular(99),
            onTap: () {
              _verificarConexion();
              if (!_conectado) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Servidor Backend Desconectado'),
                    content: const Text(
                      'No se puede comunicar con la API PHP en http://localhost:8000.\n\n'
                      'Para iniciar el servidor backend:\n'
                      '1. Ejecuta el archivo iniciar_servidor.bat en la carpeta del proyecto, o\n'
                      '2. Abre una terminal y corre:\n'
                      '   cd backend\n'
                      '   php -S 0.0.0.0:8000 router.php',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _verificarConexion();
                        },
                        child: const Text('Reintentar conexión'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _conectado ? AppColors.brote : AppColors.alerta,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _conectado ? 'En línea' : 'Sin conexión',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _conectado ? AppColors.brote : AppColors.alerta,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Avatar de Perfil
          InkWell(
            borderRadius: BorderRadius.circular(99),
            onTap: _abrirPerfil,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.azulSoft,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.azul, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentTab,
        children: [
          InicioScreen(
            onNuevaParcelaTap: _abrirNuevaParcela,
            onParcelaTap: (pid) => _abrirRegistro(parcelaId: pid),
          ),
          ParcelasScreen(
            onRegistrarTap: (pid) => _abrirRegistro(parcelaId: pid),
          ),
          CalendarioScreen(
            onRegistrarDiaTap: (fecha) => _abrirRegistro(fecha: fecha),
          ),
          const ReportesScreen(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        elevation: 4,
        backgroundColor: AppColors.azul,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () => _abrirRegistro(),
        child: const Icon(Icons.add, size: 30),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        color: AppColors.surface,
        elevation: 10,
        height: 65,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navButton(0, Icons.home_outlined, Icons.home, 'Inicio'),
            _navButton(1, Icons.grid_view, Icons.grid_view_rounded, 'Parcelas'),
            const SizedBox(width: 48), // Espacio para el FAB central
            _navButton(2, Icons.calendar_today_outlined, Icons.calendar_today, 'Calendario'),
            _navButton(3, Icons.bar_chart_outlined, Icons.bar_chart, 'Reportes'),
          ],
        ),
      ),
    );
  }

  Widget _navButton(int index, IconData iconOutlined, IconData iconFilled, String label) {
    final bool activo = _currentTab == index;
    final Color color = activo ? AppColors.azul : AppColors.muted;

    return InkWell(
      onTap: () => setState(() => _currentTab = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(activo ? iconFilled : iconOutlined, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: activo ? FontWeight.bold : FontWeight.w500, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
