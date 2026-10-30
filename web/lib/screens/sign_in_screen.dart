import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/google_auth_client.dart';
import '../state/app_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/theme_mode_toggle.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final authenticated = await ref.read(authControllerProvider).signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
    if (authenticated && mounted) {
      context.go('/panel');
    }
  }

  Future<void> _signInWithGoogle() async {
    final authResult = await GoogleAuthClient.signIn();
    if (authResult.wasCancelled) return;
    if (authResult.errorMessage != null) {
      ref.read(authControllerProvider).setMessage(authResult.errorMessage!);
      return;
    }
    final ok = await ref.read(authControllerProvider).signInWithGoogle(idToken: authResult.idToken!);
    if (ok && mounted) {
      context.go('/panel');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final wide = MediaQuery.sizeOf(context).width >= 980;

    final formCard = ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkSurface : Colors.white).withValues(alpha: isDark ? 0.85 : 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
            boxShadow: SaasDecoration.elevatedShadow(isDark),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header del formulario
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TRAXIA',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            letterSpacing: -0.5,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Logística Inteligente de Carga',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'Bienvenido de vuelta',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ingresa tus credenciales para acceder a tu consola operativa.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),

                // Campo Correo
                Text(
                  'Correo electrónico',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  enabled: !auth.isSubmitting,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.username, AutofillHints.email],
                  decoration: const InputDecoration(
                    hintText: 'ejemplo@empresa.com',
                    prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty || !email.contains('@') || email.length > 254) {
                      return 'Escribe un correo válido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Campo Contraseña
                Text(
                  'Contraseña',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  enabled: !auth.isSubmitting,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
                  ),
                  validator: (value) {
                    final password = value ?? '';
                    if (password.isEmpty) {
                      return 'Escribe tu contraseña.';
                    }
                    if (utf8.encode(password).length > 72) {
                      return 'La contraseña supera el límite permitido.';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),

                if (auth.message != null) ...[
                  const SizedBox(height: 20),
                  _MessageBanner(message: auth.message!),
                ],

                const SizedBox(height: 28),

                // Botón Iniciar Sesión con estilo SaaS moderno
                FilledButton(
                  onPressed: auth.isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: auth.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Iniciar sesión'),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'O CONTINÚA CON',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),

                // Botón Google Sign-In estilizado
                OutlinedButton(
                  onPressed: auth.isSubmitting ? null : _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: isDark ? const Color(0xFF162035) : Colors.white,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _GoogleLogo(),
                      SizedBox(width: 12),
                      Text(
                        'Google Workspace',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿Aún no tienes cuenta?',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      onPressed: () => context.go('/crear-cuenta'),
                      child: const Text('Crear una cuenta'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          // Fondo decorativo con gradiente moderno y luces sutiles
          Positioned.fill(
            child: Container(
              color: isDark ? AppColors.darkBg : AppColors.lightBg,
            ),
          ),
          Positioned(
            top: -150,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 550,
              height: 550,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: isDark ? 0.10 : 0.07),
              ),
            ),
          ),

          // Selector de tema flotante arriba a la derecha
          const Positioned(
            top: 24,
            right: 24,
            child: ThemeModeToggle(),
          ),

          // Contenido principal responsive
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: wide
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 48),
                            child: _BrandHeroPanel(isDark: isDark),
                          ),
                        ),
                        formCard,
                      ],
                    )
                  : formCard,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandHeroPanel extends StatelessWidget {
  const _BrandHeroPanel({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'Plataforma SaaS de Transporte y Fletes',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Conectamos generadores de carga, conductores y empresas legalizadoras.',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            height: 1.2,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Calculadora de costos operativos en tiempo real, monitoreo de fletes colombianos, ofertas transparentes y seguimiento del viaje.',
          style: TextStyle(
            fontSize: 15.5,
            height: 1.6,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 36),
        _FeatureBadge(
          icon: Icons.calculate_rounded,
          title: 'Calculadora de Costos y Peajes',
          subtitle: 'Cálculo de ACPM (\$10.500 COP), peajes y desgaste por ruta en tiempo real.',
          isDark: isDark,
        ),
        const SizedBox(height: 18),
        _FeatureBadge(
          icon: Icons.shield_rounded,
          title: 'Seguridad y Cumplimiento',
          subtitle: 'Validación de manifiestos, legalizaciones y firmas electrónicas.',
          isDark: isDark,
        ),
      ],
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  const _FeatureBadge({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            boxShadow: SaasDecoration.softShadow(isDark),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);
    final paint = Paint()..isAntiAlias = true;

    // Azul
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -0.785,
      1.57,
      true,
      paint,
    );

    // Verde
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      0.785,
      1.57,
      true,
      paint,
    );

    // Amarillo
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      2.356,
      1.57,
      true,
      paint,
    );

    // Rojo
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      3.927,
      1.57,
      true,
      paint,
    );

    // Centro blanco
    paint.color = Colors.white;
    canvas.drawCircle(center, r * 0.58, paint);

    // Barra horizontal de la G
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(center.dx - 1, center.dy - r * 0.22, r * 1.05, r * 0.44),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
