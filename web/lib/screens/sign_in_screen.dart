import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/google_auth_client.dart';
import '../auth/local_storage_stub.dart'
    if (dart.library.js_interop) '../auth/local_storage_web.dart';
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
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() {
    try {
      final savedEmail = getSavedValue('traxia_last_email');
      final savedPass = getSavedValue('traxia_last_pass');
      final rememberFlag = getSavedValue('traxia_remember_me');

      if (savedEmail != null && savedEmail.isNotEmpty) {
        _emailController.text = savedEmail;
      }
      if (savedPass != null && savedPass.isNotEmpty) {
        _passwordController.text = savedPass;
      }
      if (rememberFlag != null) {
        _rememberMe = rememberFlag == 'true';
      }
    } catch (_) {}
  }

  void _fillAccount(String email, String password) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
    });
  }

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

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_rememberMe) {
      saveValue('traxia_last_email', email);
      saveValue('traxia_last_pass', password);
      saveValue('traxia_remember_me', 'true');
    } else {
      saveValue('traxia_last_email', '');
      saveValue('traxia_last_pass', '');
      saveValue('traxia_remember_me', 'false');
    }

    final authenticated = await ref.read(authControllerProvider).signIn(
          email: email,
          password: password,
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
              children: [
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
                      child: const Icon(
                        Icons.local_shipping_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TRAXIA',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Logistica Inteligente de Carga',
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
                const SizedBox(height: 28),
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
                const SizedBox(height: 20),

                // Accesos rapidos para pruebas (Conductor y Empresa)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF162035) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bolt_rounded, size: 16, color: Colors.amber.shade700),
                          const SizedBox(width: 6),
                          const Text(
                            'Cuentas rapidas de prueba (1 Clic):',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _fillAccount('conductor.bogota@traxia.local', 'SecurePassword2026*'),
                              icon: const Icon(Icons.drive_eta_rounded, size: 14),
                              label: const Text('Conductor', style: TextStyle(fontSize: 11.5)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _fillAccount('empresa.colombia@traxia.local', 'SecurePassword2026*'),
                              icon: const Icon(Icons.business_rounded, size: 14),
                              label: const Text('Empresa', style: TextStyle(fontSize: 11.5)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.5)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Campo Correo
                Text(
                  'Correo electronico',
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
                      return 'Escribe un correo valido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Campo Contrasena
                Text(
                  'Contrasena',
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
                    hintText: '•••••••••••••',
                    prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
                  ),
                  validator: (value) {
                    final password = value ?? '';
                    if (password.isEmpty) {
                      return 'Escribe tu contrasena.';
                    }
                    if (utf8.encode(password).length > 72) {
                      return 'La contrasena supera el limite permitido.';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),

                const SizedBox(height: 10),

                // Checkbox: Mantener sesion iniciada y recordar credenciales
                InkWell(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) => setState(() => _rememberMe = val ?? true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Mantener sesion iniciada y recordar credenciales',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (auth.message != null) ...[
                  const SizedBox(height: 16),
                  _MessageBanner(message: auth.message!),
                ],

                const SizedBox(height: 22),

                // Boton Iniciar Sesion con estilo SaaS moderno
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
                            Text('Iniciar sesion'),
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
                        'O CONTINUA CON',
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

                // Boton Google Sign-In estilizado
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
                      'Aun no tienes cuenta?',
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

          const Positioned(
            top: 24,
            right: 24,
            child: ThemeModeToggle(),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: wide
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: const _BrandingSection(),
                        ),
                        const SizedBox(width: 60),
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

class _BrandingSection extends StatelessWidget {
  const _BrandingSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              Icon(Icons.verified_rounded, size: 14, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'LOGISTICA B2B COLOMBIA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Conectamos generadores de carga con transportistas certificados.',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Plataforma integral con calculo predictivo de costos operativos (Gemelo Digital), trazabilidad satelital en vivo con OpenStreetMap y contratos inteligentes con validez juridica.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 32),
        const _FeatureCheckItem(
          icon: Icons.speed_rounded,
          title: 'Gemelo Digital y Simulacion de Rutas',
          subtitle: 'Calculo exacto de peajes, consumo de ACPM y costo por kilometro segun el Ministerio de Transporte.',
        ),
        const SizedBox(height: 18),
        const _FeatureCheckItem(
          icon: Icons.shield_rounded,
          title: 'Seguridad y Verificacion RUNT',
          subtitle: 'Control riguroso de antecedentes, matricula de vehiculos y polizas de transporte vigentes.',
        ),
        const SizedBox(height: 18),
        const _FeatureCheckItem(
          icon: Icons.receipt_long_rounded,
          title: 'Legalizacion y Actas Digitales',
          subtitle: 'Generacion instantanea de cumplidos de entrega conforme al Articulo 981 del Codigo de Comercio.',
        ),
      ],
    );
  }
}

class _FeatureCheckItem extends StatelessWidget {
  const _FeatureCheckItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  height: 1.35,
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
    final isDuplicate = message.contains('ya está registrado') || message.contains('ya existe');
    final isError = !isDuplicate;

    final bg = isError ? AppColors.errorContainer : AppColors.warningContainer;
    final border = isError ? AppColors.error : AppColors.warning;
    final iconColor = isError ? AppColors.error : AppColors.warning;
    final icon = isError ? Icons.error_outline_rounded : Icons.info_outline_rounded;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: iconColor,
                fontWeight: FontWeight.w500,
                height: 1.35,
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
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    final bluePaint = Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill;
    final redPaint = Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.fill;
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.fill;
    final greenPaint = Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, bluePaint);
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -0.785, 1.57, true, redPaint);
    canvas.drawArc(rect, 0.785, 1.57, true, yellowPaint);
    canvas.drawArc(rect, 2.356, 1.57, true, greenPaint);

    final whiteCenterPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.55, whiteCenterPaint);

    final blueBarPaint = Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill;
    final barRect = Rect.fromLTWH(center.dx, center.dy - radius * 0.22, radius * 0.9, radius * 0.44);
    canvas.drawRect(barRect, blueBarPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}