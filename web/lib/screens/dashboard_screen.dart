import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/app_providers.dart';
import '../widgets/app_nav_bar.dart';

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
    final wide = MediaQuery.sizeOf(context).width >= 850;

    return Scaffold(
      appBar: const AppNavBar(
        currentSection: AppNavSection.dashboard,
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
              ]
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
            )
    );
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
              const SizedBox(height: 24),
              Text(
                'Módulos de Carga y Transporte',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmall = constraints.maxWidth < 600;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: isSmall ? constraints.maxWidth : 320,
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: theme.colorScheme.primaryContainer,
                                      child: Icon(Icons.add_road, color: theme.colorScheme.primary),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Publicar Carga',
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Registra una nueva carga en 5 pasos (origen, destino, carrocería, fechas y condiciones).',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: () => context.push('/publicar-carga'),
                                    icon: const Icon(Icons.arrow_forward, size: 18),
                                    label: const Text('Nueva Carga'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: isSmall ? constraints.maxWidth : 320,
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: theme.colorScheme.secondaryContainer,
                                      child: Icon(Icons.local_shipping_outlined, color: theme.colorScheme.secondary),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Cargas Disponibles',
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Explora fletes activos en Colombia y simula costos de ruta con el Gemelo Digital.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => context.push('/cargas'),
                                    icon: const Icon(Icons.search, size: 18),
                                    label: const Text('Ver Cartelera'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: isSmall ? constraints.maxWidth : 320,
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: theme.colorScheme.tertiaryContainer,
                                      child: Icon(Icons.route, color: theme.colorScheme.tertiary),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Mis Viajes',
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Monitorea y ejecuta viajes asignados: cambia a en tránsito y confirma entrega.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => context.push('/viajes'),
                                    icon: const Icon(Icons.playlist_play, size: 18),
                                    label: const Text('Ver Mis Viajes'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
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
