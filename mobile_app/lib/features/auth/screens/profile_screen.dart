import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import 'change_password_modal.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Mi Cuenta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User header card
              _buildUserHeader(user),
              const SizedBox(height: 16),

              // Account settings
              _buildSectionTitle('Cuenta'),
              _buildSettingsCard([
                _buildSettingTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Cambiar contraseña',
                  subtitle: 'Actualiza tu contraseña de acceso',
                  onTap: () => _showChangePasswordModal(context),
                ),
                _buildSettingTile(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Recordarme',
                  subtitle: 'Mantener sesión iniciada entre aperturas',
                  trailing: Switch(
                    value: authProvider.rememberMe,
                    onChanged: (value) => _toggleRememberMe(authProvider, value),
                    activeThumbColor: AppColors.azul,
                  ),
                  onTap: () => _toggleRememberMe(authProvider, !authProvider.rememberMe),
                ),
                _buildSettingTile(
                  icon: themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  title: 'Modo oscuro',
                  subtitle: themeProvider.isDarkMode
                      ? 'Desactivar tema oscuro'
                      : 'Activar tema oscuro',
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) => themeProvider.setThemeMode(
                      value ? ThemeMode.dark : ThemeMode.light,
                    ),
                    activeThumbColor: AppColors.azul,
                  ),
                  onTap: () => themeProvider.setThemeMode(
                    themeProvider.isDarkMode ? ThemeMode.light : ThemeMode.dark,
                  ),
                ),
              ]),
              const SizedBox(height: 16),

              // User info
              _buildSectionTitle('Información'),
              _buildInfoCard(user),
              const SizedBox(height: 24),

              // Danger zone
              _buildSectionTitle('Zona de peligro'),
              _buildSettingsCard([
                _buildDangerTile(
                  icon: Icons.logout_rounded,
                  title: 'Cerrar sesión',
                  subtitle: 'Salir de la cuenta en este dispositivo',
                  onTap: () => _handleLogout(authProvider),
                ),
              ]),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader(UserModel? user) {
    final initial = (user?.nombreCompleto.isNotEmpty ?? false)
        ? user!.nombreCompleto.trim()[0].toUpperCase()
        : 'U';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.nombreCompleto ?? 'Usuario',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${user?.username ?? ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.muted,
                    ),
                  ),
                  if (user?.correo != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      user!.correo!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.muted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.line),
      ),
      child: Column(
        children: children
            .expand((widget) => [widget, const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.line)])
            .take(children.length * 2 - 1)
            .toList(),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.azulSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.azul, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildDangerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.red.shade600, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.red.shade300, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(UserModel? user) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow('Rol', user?.rol ?? 'Productor', Icons.badge_rounded),
            const Divider(height: 1, color: AppColors.line),
            _buildInfoRow('Finca ID', user?.idFinca?.toString() ?? '—', Icons.agriculture_rounded),
            const Divider(height: 1, color: AppColors.line),
            _buildInfoRow('Usuario ID', user?.id.toString() ?? '—', Icons.fingerprint_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.muted, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChangePasswordModal(),
    );
  }

  Future<void> _toggleRememberMe(AuthProvider authProvider, bool value) async {
    setState(() => _isLoading = true);
    try {
      await authProvider.setRememberMe(value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? 'Sesión persistente activada' : 'Sesión persistente desactivada'),
            backgroundColor: AppColors.brote,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout(AuthProvider authProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await authProvider.logout();
      if (mounted) context.go('/login');
    }
  }
}