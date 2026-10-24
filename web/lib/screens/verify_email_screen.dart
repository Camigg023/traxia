import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/app_providers.dart';
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
        setState(
            () => _error = ref.read(authApiProvider).messageFor(exception));
      }
    } on FormatException {
      if (mounted) {
        setState(
            () => _error = 'El servidor devolvió una respuesta no válida.');
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
    final hasToken = widget.token != null && widget.token!.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar correo'),
        actions: const [ThemeModeToggle(), SizedBox(width: 12)],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      _message == null
                          ? Icons.mark_email_read_outlined
                          : Icons.verified_outlined,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _message ?? 'Confirma tu correo de prueba',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _message != null
                          ? 'La cuenta ya está verificada. El perfil elegido es solo una intención de registro; no concede permisos de negocio.'
                          : hasToken
                              ? 'Confirma la solicitud para activar la cuenta local. El enlace solo se puede usar una vez y vence en 30 minutos.'
                              : 'El enlace no incluye un token de verificación. Abre el enlace completo recibido en Mailpit.',
                      textAlign: TextAlign.center,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _error!,
                          style: TextStyle(color: theme.colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (_message != null)
                      FilledButton(
                        onPressed: () => context.go('/iniciar-sesion'),
                        child: const Text('Iniciar sesión'),
                      )
                    else
                      FilledButton(
                        onPressed: !hasToken || _isSubmitting ? null : _verify,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Verificar correo'),
                      ),
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => context.go('/iniciar-sesion'),
                      child: const Text('Volver a iniciar sesión'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
