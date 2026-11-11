import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identificadorController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _dropAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _dropAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _identificadorController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.login(
      identificador: _identificadorController.text.trim(),
      password: _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (result.$1) {
      context.go('/dashboard');
    } else {
      setState(() {
        _errorMessage = result.$2 ?? 'Error al iniciar sesión';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Subtle background decoration
          ..._buildBackgroundElements(size),
          
          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Water drop icon - decorative only
                              ScaleTransition(
                                scale: _dropAnimation,
                                child: _buildWaterDropIcon(),
                              ),
                              const SizedBox(height: 16),
                              
                              // App name
                              Text(
                                'Raíz Azul',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.ink,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              
                              // Subtitle
                              Text(
                                'Uso eficiente del agua y manejo responsable de cultivos',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.muted,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 32),
                              
                              // Login card
                              _buildLoginCard(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBackgroundElements(Size size) {
    return [
      // Top-left glow
      Positioned(
        top: -80,
        left: -80,
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.azul.withValues(alpha: 0.08),
                AppColors.azul.withValues(alpha: 0.02),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      // Bottom-right glow
      Positioned(
        bottom: -100,
        right: -100,
        child: Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.lluvia.withValues(alpha: 0.06),
                AppColors.lluvia.withValues(alpha: 0.01),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      // Small floating bubbles
      ..._buildFloatingBubbles(size),
    ];
  }

  List<Widget> _buildFloatingBubbles(Size size) {
    final bubbles = <Widget>[];
    final positions = [
      Offset(size.width * 0.08, size.height * 0.18),
      Offset(size.width * 0.92, size.height * 0.22),
      Offset(size.width * 0.05, size.height * 0.75),
      Offset(size.width * 0.88, size.height * 0.82),
    ];

    for (int i = 0; i < positions.length; i++) {
      bubbles.add(
        _FloatingBubble(
          position: positions[i],
          size: 30.0 + (i * 10),
          color: [AppColors.azulSoft, AppColors.lluviaSoft, AppColors.broteSoft][i % 3],
          delay: Duration(milliseconds: i * 300),
        ),
      );
    }
    return bubbles;
  }

  Widget _buildWaterDropIcon() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.azul.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.lluvia.withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: const Icon(
        Icons.water_drop_rounded,
        size: 44,
        color: Colors.white,
      ),
    );
  }

  Widget _buildLoginCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.line, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Iniciar Sesión',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ingresa tus credenciales para continuar',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 28),
              
              // Username field
              _buildTextField(
                controller: _identificadorController,
                label: 'Usuario o correo electrónico',
                icon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa tu usuario o correo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              
              // Password field
              _buildTextField(
                controller: _passwordController,
                label: 'Contraseña',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleLogin(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.muted,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu contraseña';
                  }
                  return null;
                },
              ),
              
              // Remember me checkbox
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (value) => setState(() => _rememberMe = value ?? false),
                    activeColor: AppColors.azul,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recordarme',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.ink,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 28),
              
              // Login button
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azul,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    shadowColor: AppColors.azul.withValues(alpha: 0.3),
                  ).copyWith(
                    overlayColor: WidgetStateProperty.resolveWith<Color?>(
                      (states) {
                        if (states.contains(WidgetState.pressed)) {
                          return AppColors.azul.withValues(alpha: 0.8);
                        }
                        return null;
                      },
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _handleLogin,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'INICIAR SESIÓN',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Test credentials hint
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.azulSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.azul.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, color: AppColors.azul, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Usuario de prueba: ',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Crispin / crispin123',
                      style: TextStyle(
                        color: AppColors.azul,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      style: TextStyle(
        fontSize: 15,
        color: AppColors.ink,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppColors.muted,
          fontSize: 14,
        ),
        floatingLabelStyle: TextStyle(
          color: AppColors.azul,
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: AppColors.muted, size: 22),
        prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        suffixIcon: suffixIcon,
        suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        filled: true,
        fillColor: AppColors.surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.line, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.line, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.azul, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade600, width: 2),
        ),
        errorStyle: TextStyle(
          color: Colors.red.shade700,
          fontSize: 12,
        ),
      ),
      validator: validator,
    );
  }
}

// Simple floating bubble animation
class _FloatingBubble extends StatefulWidget {
  final Offset position;
  final double size;
  final Color color;
  final Duration delay;

  const _FloatingBubble({
    required this.position,
    required this.size,
    required this.color,
    required this.delay,
  });

  @override
  State<_FloatingBubble> createState() => _FloatingBubbleState();
}

class _FloatingBubbleState extends State<_FloatingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _translateY;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 4000 + widget.position.dx.toInt() * 5),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.25, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _translateY = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.position.dx - (widget.size * _scaleAnimation.value) / 2,
          top: widget.position.dy - (widget.size * _scaleAnimation.value) / 2 + _translateY.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: SizedBox(
              width: widget.size * _scaleAnimation.value,
              height: widget.size * _scaleAnimation.value,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.color.withValues(alpha: 0.6),
                      widget.color.withValues(alpha: 0.1),
                      widget.color.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}