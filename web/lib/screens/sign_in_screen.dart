import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/google_auth_client.dart';
import '../state/app_providers.dart';
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
    final idToken = await GoogleAuthClient.signIn();
    if (idToken == null) return;
    final ok = await ref.read(authControllerProvider).signInWithGoogle(idToken: idToken);
    if (ok && mounted) context.go('/panel');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 980;

    final form = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Qué bueno verte', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Ingresa para continuar en TRAXIA.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _emailController,
                    enabled: !auth.isSubmitting,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.username, AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty || !email.contains('@') || email.length > 254) {
                        return 'Escribe un correo válido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    enabled: !auth.isSubmitting,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock_outline),
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
                    const SizedBox(height: 16),
                    _MessageBanner(message: auth.message!),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: auth.isSubmitting ? null : _submit,
                    child: auth.isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Iniciar sesión'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('o', style: Theme.of(context).textTheme.bodySmall),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: auth.isSubmitting ? null : _signInWithGoogle,
                    icon: const _GoogleLogo(),
                    label: const Text('Continuar con Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Flexible(child: Text('¿Aún no tienes cuenta?')),
                      TextButton(
                        onPressed: () => context.go('/crear-cuenta'),
                        child: const Text('Conoce el registro'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Acceso seguro. Nunca guardamos la contraseña en este navegador.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const _Brand(),
        actions: const [ThemeModeToggle(), SizedBox(width: 12)],
      ),
      body: SafeArea(
        top: false,
        child: wide
            ? Row(
                children: [
                  const Expanded(child: _WelcomePanel()),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: form,
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  children: [
                    if (MediaQuery.sizeOf(context).width >= 600) ...[
                      const _CompactWelcome(),
                      const SizedBox(height: 24),
                    ],
                    form,
                  ],
                ),
              ),
      ),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 12, 0, 24),
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            Color.lerp(theme.colorScheme.primary, const Color(0xFF173A58), 0.72)!,
          ],
        ),
      ),
      child: const _WelcomeContent(light: true),
    );
  }
}

class _CompactWelcome extends StatelessWidget {
  const _CompactWelcome();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: _WelcomeContent(light: false),
    );
  }
}

class _WelcomeContent extends StatelessWidget {
  const _WelcomeContent({required this.light});

  final bool light;

  @override
  Widget build(BuildContext context) {
    final foreground =
        light ? Colors.white : Theme.of(context).colorScheme.onSurface;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.route_rounded, size: 44, color: foreground),
        const SizedBox(height: 28),
        Text(
          'El transporte,\nmejor conectado.',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
        ),
        const SizedBox(height: 18),
        Text(
          'Un espacio para empresas que necesitan transportar, conductores y empresas legalizadoras.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: foreground.withValues(alpha: 0.86),
                height: 1.5,
              ),
        ),
        const SizedBox(height: 32),
        for (final item in const [
          'Información clara en cada etapa',
          'Acceso desde el navegador',
          'Diseñado para trabajar en equipo',
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: foreground, size: 20),
                const SizedBox(width: 12),
                Text(item, style: TextStyle(color: foreground)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.route_rounded, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        const Text('TRAXIA', style: TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(color: scheme.onErrorContainer),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontWeight: FontWeight.w900,
          fontSize: 15,
        ),
      ),
    );
  }
}
