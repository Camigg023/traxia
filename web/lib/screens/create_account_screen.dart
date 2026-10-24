import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_api.dart';
import '../state/app_providers.dart';
import '../widgets/theme_mode_toggle.dart';

enum AccountProfile {
  shipper(
    'SHIPPER',
    'Empresa que solicita transporte',
    Icons.inventory_2_outlined,
  ),
  driver('DRIVER', 'Conductor', Icons.local_shipping_outlined),
  legalizer('LEGALIZER', 'Empresa legalizadora', Icons.fact_check_outlined);

  const AccountProfile(this.code, this.label, this.icon);

  final String code;
  final String label;
  final IconData icon;
}

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) {
      return;
    }
    final profile = _selectedProfile;
    if (profile == null || !_testNoticeAccepted) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await ref.read(authApiProvider).register(
            displayName: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            profile: profile.code,
          );
      if (mounted) {
        setState(() => _registeredEmail = _emailController.text.trim());
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        actions: const [ThemeModeToggle(), SizedBox(width: 12)],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: _registeredEmail == null
                ? _buildForm(context, theme)
                : _buildConfirmation(context, theme, _registeredEmail!),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Crea tu cuenta de prueba',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Elige el perfil con el que explorarás TRAXIA.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 650 ? 3 : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: AccountProfile.values
                    .map(
                      (profile) => SizedBox(
                        width: width,
                        child: _ProfileCard(
                          profile: profile,
                          selected: _selectedProfile == profile,
                          enabled: !_isSubmitting,
                          onTap: () =>
                              setState(() => _selectedProfile = profile),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            enabled: !_isSubmitting,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Nombre completo o de contacto',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) {
              final name = value?.trim() ?? '';
              if (name.length < 2) {
                return 'Escribe un nombre de al menos 2 caracteres.';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            enabled: !_isSubmitting,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            maxLength: 254,
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
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            enabled: !_isSubmitting,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            maxLength: 72,
            decoration: const InputDecoration(
              labelText: 'Contraseña',
              helperText: 'Usa entre 16 y 72 caracteres.',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (value) {
              final password = value ?? '';
              if (password.runes.length < 16) {
                return 'La contraseña debe tener al menos 16 caracteres.';
              }
              if (utf8.encode(password).length > 72) {
                return 'La contraseña supera el límite permitido.';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmationController,
            enabled: !_isSubmitting,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            decoration: const InputDecoration(
              labelText: 'Confirma la contraseña',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Las contraseñas no coinciden.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.science_outlined,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Solo para desarrollo local. Este aviso provisional no son los términos de uso ni la política de privacidad definitivos. Usa datos de prueba; no registres información sensible ni documentos reales.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _testNoticeAccepted,
                    onChanged: _isSubmitting
                        ? null
                        : (accepted) => setState(
                              () => _testNoticeAccepted = accepted ?? false,
                            ),
                    title: const Text(
                      'Leí y acepto usar este registro provisional solo con datos de prueba.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(message: _error!),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isSubmitting ||
                    _selectedProfile == null ||
                    !_testNoticeAccepted
                ? null
                : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Crear cuenta de prueba'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed:
                _isSubmitting ? null : () => context.go('/iniciar-sesion'),
            child: const Text('Volver a iniciar sesión'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmation(
    BuildContext context,
    ThemeData theme,
    String email,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.mark_email_unread_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Revisa el correo local de pruebas',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Si la cuenta puede registrarse, el mensaje de verificación llegará a $email. '
              'Abre Mailpit en http://localhost:8025 y usa el enlace antes de que venza en 30 minutos.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SelectableText(
              'http://localhost:8025',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => setState(() => _registeredEmail = null),
              child: const Text('Volver al formulario'),
            ),
            TextButton(
              onPressed: () => context.go('/iniciar-sesion'),
              child: const Text('Ya verifiqué mi correo; iniciar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final AccountProfile profile;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: profile.label,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Card(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  profile.icon,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 30,
                ),
                const SizedBox(height: 18),
                Text(
                  profile.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: selected ? theme.colorScheme.primary : null,
                    ),
                    const SizedBox(width: 8),
                    Text(selected ? 'Seleccionado' : 'Seleccionar'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message,
          style: TextStyle(color: theme.colorScheme.onErrorContainer),
        ),
      ),
    );
  }
}
