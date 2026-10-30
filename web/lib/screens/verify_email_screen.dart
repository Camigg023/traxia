import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/app_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/theme_mode_toggle.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({required this.token, super.key});

  final String? token;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isSubmitting = false;
  String? _message;
  String? _error;

  Future<void> _verify() async {
    final token = widget.token;
    if (_isSubmitting || token == null || token.isEmpty) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final message = await ref.read(authApiProvider).verifyEmail(token);
      if (mounted) {
        setState(() => _message = message);
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
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasToken = widget.token != null && widget.token!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación de Cuenta'),
        actions: const [ThemeModeToggle(), SizedBox(width: 16)],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                boxShadow: SaasDecoration.elevatedShadow(isDark),
              ),
              padding: const EdgeInsets.all(36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _message != null
                            ? AppColors.successContainer
                            : AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _message == null
                            ? Icons.mark_email_read_rounded
                            : Icons.verified_rounded,
                        size: 32,
                        color: _message != null ? AppColors.success : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _message ??
                        (hasToken
                            ? 'Confirma tu dirección de correo'
                            : 'Falta el token de verificación'),
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _message != null
                        ? 'Tu cuenta ha sido validada y está lista para operar en TRAXIA.'
                        : hasToken
                            ? 'Haz clic en el botón inferior para validar tu cuenta y comenzar a publicar u ofertar fletes.'
                            : 'No encontramos el código de verificación en el enlace. Revisa tu correo o solicita uno nuevo.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  if (_message != null) ...[
                    FilledButton(
                      onPressed: () => context.go('/iniciar-sesion'),
                      child: const Text('Iniciar sesión en TRAXIA'),
                    ),
                  ] else if (hasToken) ...[
                    FilledButton(
                      onPressed: _isSubmitting ? null : _verify,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Confirmar mi correo electrónico'),
                    ),
                  ] else ...[
                    OutlinedButton(
                      onPressed: () => context.go('/iniciar-sesion'),
                      child: const Text('Volver al inicio de sesión'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
