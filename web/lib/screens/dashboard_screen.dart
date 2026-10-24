import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/app_providers.dart';
import '../widgets/theme_mode_toggle.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedSection = 0;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isAdmin = user.roles.contains('ADMIN');
    final title = isAdmin ? 'Panel de administración' : 'Tu espacio TRAXIA';
    final wide = MediaQuery.sizeOf(context).width >= 850;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          const ThemeModeToggle(),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Tooltip(
              message: user.email,
              child: CircleAvatar(
                child: Text(user.email.substring(0, 1).toUpperCase()),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          if (wide)
            NavigationRail(
              selectedIndex: _selectedSection,
              onDestinationSelected: (index) =>
                  setState(() => _selectedSection = index),
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.space_dashboard_outlined),
                  selectedIcon: Icon(Icons.space_dashboard),
                  label: Text('Resumen'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: Text('Mi cuenta'),
                ),
              ],
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: IconButton(
                      tooltip: 'Cerrar sesión',
                      onPressed: auth.isSubmitting ? null : _signOut,
                      icon: const Icon(Icons.logout),
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: _selectedSection == 0
                ? _Overview(isAdmin: isAdmin, email: user.email)
                : _AccountDetails(email: user.email, roles: user.roles),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _selectedSection,
              onDestinationSelected: (index) =>
                  setState(() => _selectedSection = index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.space_dashboard_outlined),
                  label: 'Resumen',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  label: 'Mi cuenta',
                ),
              ],
            ),
      floatingActionButton: wide
          ? null
          : FloatingActionButton.small(
              tooltip: 'Cerrar sesión',
              onPressed: auth.isSubmitting ? null : _signOut,
              child: const Icon(Icons.logout),
            ),
    );
  }

  Future<void> _signOut() async {
    final signedOut = await ref.read(authControllerProvider).signOut();
    if (!signedOut && mounted) {
      final message = ref.read(authControllerProvider).message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message ?? 'No fue posible cerrar la sesión.')),
      );
    }
    if (signedOut && mounted) {
      context.go('/iniciar-sesion');
    }
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.isAdmin, required this.email});

  final bool isAdmin;
  final String email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAdmin ? 'Bienvenido a TRAXIA' : 'Hola, $email',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isAdmin
                    ? 'Estás usando una cuenta con permisos globales de administración.'
                    : 'Tu sesión está activa. Aquí encontrarás el estado de tu cuenta.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isAdmin
                            ? Icons.admin_panel_settings_outlined
                            : Icons.business_center_outlined,
                        color: theme.colorScheme.primary,
                        size: 30,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAdmin
                                  ? 'Administración de plataforma'
                                  : 'Perfil empresarial pendiente',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isAdmin
                                  ? 'La cuenta ADMIN es global. Los módulos de administración se incorporarán cuando sus servicios estén disponibles.'
                                  : 'La API todavía no entrega membresías ni funciones empresariales. '
                                      'Por eso no se muestra ni se concede acceso de empresa desde esta interfaz.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Estado de la plataforma', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: const [
                  _StatusCard(
                    title: 'Cuenta',
                    value: 'Sesión iniciada',
                    icon: Icons.verified_user_outlined,
                  ),
                  _StatusCard(
                    title: 'Empresas y membresías',
                    value: 'Pendiente de backend',
                    icon: Icons.apartment_outlined,
                  ),
                  _StatusCard(
                    title: 'Operaciones de transporte',
                    value: 'En construcción',
                    icon: Icons.route_outlined,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountDetails extends StatelessWidget {
  const _AccountDetails({required this.email, required this.roles});

  final String email;
  final List<String> roles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mi cuenta', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 20),
                  _DetailRow(label: 'Correo electrónico', value: email),
                  const Divider(height: 28),
                  _DetailRow(
                    label: 'Permisos globales',
                    value: roles.isEmpty ? 'Sin permisos globales' : roles.join(', '),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Los perfiles y permisos de empresa se administrarán por membresía; '
                    'no se deducen de la selección del registro.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        SelectableText(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 260,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(height: 14),
              Text(title, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
