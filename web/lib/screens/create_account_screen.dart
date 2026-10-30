import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../state/app_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/theme_mode_toggle.dart';

enum AccountProfile {
  shipper(
    'SHIPPER',
    'Empresa que solicita transporte',
    'Publica cargas, recibe ofertas y simula costos de flete en tiempo real.',
    Icons.inventory_2_outlined,
    Icons.inventory_2_rounded,
  ),
  driver(
    'DRIVER',
    'Conductor',
    'Encuentra rutas rentables, envía ofertas y gestiona entregas con GPS.',
    Icons.local_shipping_outlined,
    Icons.local_shipping_rounded,
  ),
  legalizer(
    'LEGALIZER',
    'Empresa legalizadora',
    'Valida manifiestos, legalizaciones y cumplimiento de normatividad.',
    Icons.fact_check_outlined,
    Icons.fact_check_rounded,
  );

  const AccountProfile(this.code, this.label, this.description, this.icon, this.activeIcon);

  final String code;
  final String label;
  final String description;
  final IconData icon;
  final IconData activeIcon;
}

/// Pantalla de creación de cuenta.
///
/// Si [googleIdToken] no es null, el usuario llegó desde un intento de login
/// con Google cuyo correo no estaba registrado. En ese caso se omiten los
/// campos de contraseña y se usa [AuthController.registerWithGoogle].
class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key, this.googleIdToken});

  /// ID Token de Google cuando el usuario viene del flujo de registro via Google.
  final String? googleIdToken;

  @override
  ConsumerState<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  AccountProfile? _selectedProfile;
  bool _testNoticeAccepted = false;
  bool _isSubmitting = false;
  String? _error;
  String? _registeredEmail;

  bool get _isGoogleFlow => widget.googleIdToken != null;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    final profile = _selectedProfile;
    if (profile == null || !_testNoticeAccepted) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      if (_isGoogleFlow) {
        // Registro con Google: no necesita contraseña, la cuenta queda activa inmediatamente
        final ok = await ref.read(authControllerProvider).registerWithGoogle(
              idToken: widget.googleIdToken!,
              profile: profile.code,
            );
        if (mounted) {
          if (ok) {
            context.go('/panel'); // sesión iniciada directamente
          } else {
            setState(() => _error = ref.read(authControllerProvider).message ??
                'No fue posible completar el registro con Google.');
          }
        }
      } else {
        // Registro tradicional con email y contraseña
        await ref.read(authApiProvider).register(
              displayName: _nameController.text,
              email: _emailController.text,
              password: _passwordController.text,
              profile: profile.code,
            );
        if (mounted) {
          setState(() => _registeredEmail = _emailController.text.trim());
        }
      }
    } on DioException catch (exception) {
      if (mounted) {
        setState(() => _error = ref.read(authApiProvider).messageFor(exception));
      }
    } on FormatException {
      if (mounted) {
        setState(() => _error = 'El servidor devolvió una respuesta no válida.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isGoogleFlow
            ? 'Elige tu perfil en TRAXIA'
            : 'Crear cuenta en TRAXIA'),
        actions: const [
          ThemeModeToggle(),
          SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: _registeredEmail != null
                ? _SuccessCard(email: _registeredEmail!, isDark: isDark)
                : _RegistrationForm(
                    formKey: _formKey,
                    nameController: _nameController,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    confirmationController: _confirmationController,
                    selectedProfile: _selectedProfile,
                    onProfileChanged: (p) => setState(() => _selectedProfile = p),
                    testNoticeAccepted: _testNoticeAccepted,
                    onNoticeChanged: (val) =>
                        setState(() => _testNoticeAccepted = val ?? false),
                    isSubmitting: _isSubmitting,
                    error: _error,
                    onSubmit: _submit,
                    isDark: isDark,
                    isGoogleFlow: _isGoogleFlow,
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Formulario de registro
// ─────────────────────────────────────────────────────────────────────────────

class _RegistrationForm extends StatelessWidget {
  const _RegistrationForm({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmationController,
    required this.selectedProfile,
    required this.onProfileChanged,
    required this.testNoticeAccepted,
    required this.onNoticeChanged,
    required this.isSubmitting,
    required this.error,
    required this.onSubmit,
    required this.isDark,
    required this.isGoogleFlow,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmationController;
  final AccountProfile? selectedProfile;
  final ValueChanged<AccountProfile> onProfileChanged;
  final bool testNoticeAccepted;
  final ValueChanged<bool?> onNoticeChanged;
  final bool isSubmitting;
  final String? error;
  final VoidCallback onSubmit;
  final bool isDark;
  final bool isGoogleFlow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: SaasDecoration.elevatedShadow(isDark),
      ),
      padding: const EdgeInsets.all(36),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner informativo para flujo Google
            if (isGoogleFlow) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.g_mobiledata_rounded, color: AppColors.primary, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Registro con Google',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Tu correo de Google está verificado. Solo elige tu perfil para activar la cuenta.',
                            style: TextStyle(fontSize: 12.5, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Título de selección de perfil
            Text(
              'Selecciona tu perfil de usuario',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Configuraremos tu consola y herramientas según el rol que desempeñas en la cadena de transporte.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),

            // Tarjetas de perfil SaaS
            ...AccountProfile.values.map((profile) {
              final isSelected = selectedProfile == profile;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: isSubmitting ? null : () => onProfileChanged(profile),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.06)
                          : (isDark ? const Color(0xFF162035) : AppColors.lightSurfaceSubtle),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        width: isSelected ? 1.8 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                          ),
                          child: Icon(
                            isSelected ? profile.activeIcon : profile.icon,
                            color: isSelected ? Colors.white : AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                profile.description,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              width: isSelected ? 6 : 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Campos de datos — se ocultan en flujo Google
            if (!isGoogleFlow) ...[
              Text(
                'Datos personales y de acceso',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 18),

              TextFormField(
                controller: nameController,
                enabled: !isSubmitting,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo o de contacto',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) {
                  final name = value?.trim() ?? '';
                  if (name.length < 2) {
                    return 'Escribe un nombre de al menos 2 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: emailController,
                enabled: !isSubmitting,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                maxLength: 254,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico corporativo o personal',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty || !email.contains('@') || email.length > 254) {
                    return 'Escribe un correo válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: passwordController,
                      enabled: !isSubmitting,
                      obscureText: true,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                      validator: (value) {
                        final password = value ?? '';
                        if (password.length < 16) {
                          return 'Mínimo 16 caracteres.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextFormField(
                      controller: confirmationController,
                      enabled: !isSubmitting,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar contraseña',
                        prefixIcon: Icon(Icons.check_circle_outline_rounded),
                      ),
                      validator: (value) {
                        if (value != passwordController.text) {
                          return 'Las contraseñas no coinciden.';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Checkbox de términos (siempre visible)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF162035) : AppColors.lightSurfaceSubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: CheckboxListTile(
                value: testNoticeAccepted,
                onChanged: isSubmitting ? null : onNoticeChanged,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  'Acepto los términos de servicio, políticas de datos y condiciones del entorno de transporte de TRAXIA.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ),

            if (error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        error!,
                        style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            FilledButton(
              onPressed:
                  (isSubmitting || selectedProfile == null || !testNoticeAccepted)
                      ? null
                      : onSubmit,
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isGoogleFlow
                      ? 'Activar cuenta con Google'
                      : 'Completar Registro'),
            ),

            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => context.go('/iniciar-sesion'),
                child: const Text('¿Ya tienes una cuenta? Iniciar sesión'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta de éxito (solo flujo email)
// ─────────────────────────────────────────────────────────────────────────────

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.email, required this.isDark});

  final String email;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: SaasDecoration.elevatedShadow(isDark),
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.successContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read_rounded,
                color: AppColors.success, size: 36),
          ),
          const SizedBox(height: 24),
          const Text(
            '¡Cuenta creada con éxito!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            'Hemos enviado un enlace de confirmación a $email. Revisa tu bandeja de entrada o abre tu servicio de correo para activar tu cuenta antes de que expire en 30 minutos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => context.go('/iniciar-sesion'),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('Ir al inicio de sesión'),
          ),
        ],
      ),
    );
  }
}
