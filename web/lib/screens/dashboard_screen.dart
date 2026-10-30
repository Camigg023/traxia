import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/app_providers.dart';
import '../theme/app_colors.dart';
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
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: const AppNavBar(
        currentSection: AppNavSection.dashboard,
      ),
      body: Row(
        children: [
          if (wide)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
              ),
              child: NavigationRail(
                selectedIndex: _selectedSection,
                onDestinationSelected: (index) => setState(() => _selectedSection = index),
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.grid_view_rounded),
                    selectedIcon: Icon(Icons.grid_view_rounded),
                    label: Text('Consola'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.account_circle_outlined),
                    selectedIcon: Icon(Icons.account_circle_rounded),
                    label: Text('Mi cuenta'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _selectedSection == 0
                ? _Overview(isAdmin: isAdmin, email: user.email, isDark: isDark)
                : _AccountDetails(email: user.email, roles: user.roles, isDark: isDark),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _selectedSection,
              onDestinationSelected: (index) => setState(() => _selectedSection = index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.grid_view_rounded),
                  label: 'Consola',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_circle_outlined),
                  selectedIcon: Icon(Icons.account_circle_rounded),
                  label: 'Mi cuenta',
                ),
              ],
            ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({
    required this.isAdmin,
    required this.email,
    required this.isDark,
  });

  final bool isAdmin;
  final String email;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner SaaS
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: SaasDecoration.subtleHeroGradient(isDark),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  boxShadow: SaasDecoration.softShadow(isDark),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_rounded, size: 14, color: AppColors.primary),
                                    SizedBox(width: 4),
                                    Text(
                                      'Ambiente Operativo Activo',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Panel de Control de Transporte',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gestiona fletes, monitorea ofertas en subasta, cotiza rutas con el Gemelo Digital y supervisa viajes en carretera con total seguridad.',
                            style: TextStyle(
                              fontSize: 14.5,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Métricas rápidas (KPIs SaaS)
              Text(
                'Métricas del Ecosistema',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final kpiWidth = constraints.maxWidth > 760
                      ? (constraints.maxWidth - 32) / 3
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: kpiWidth,
                        child: _KpiCard(
                          title: 'Precio Base ACPM',
                          value: '\$10.500 COP',
                          badge: 'Regulado',
                          icon: Icons.local_gas_station_rounded,
                          color: AppColors.primary,
                          isDark: isDark,
                        ),
                      ),
                      SizedBox(
                        width: kpiWidth,
                        child: _KpiCard(
                          title: 'Costos y Peajes',
                          value: 'Gemelo Digital',
                          badge: 'Activo',
                          icon: Icons.calculate_rounded,
                          color: AppColors.secondary,
                          isDark: isDark,
                        ),
                      ),
                      SizedBox(
                        width: kpiWidth,
                        child: _KpiCard(
                          title: 'Trazabilidad Legal',
                          value: '100% Manifiestos',
                          badge: 'Auditado',
                          icon: Icons.security_rounded,
                          color: AppColors.success,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 36),

              // Acciones Rápidas (Tarjetas con Hover y elevación)
              Text(
                'Módulos y Operaciones Principales',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = constraints.maxWidth > 760
                      ? (constraints.maxWidth - 20) / 2
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _ActionCard(
                          title: 'Publicar Nueva Carga',
                          description:
                              'Registra una carga en 5 sencillos pasos: origen, destino, tipo de vehículo (Tractomula, Dobletroque, etc.), peso y flete sugerido.',
                          buttonText: 'Publicar Carga',
                          icon: Icons.add_box_rounded,
                          color: AppColors.primary,
                          onPressed: () => context.go('/publicar-carga'),
                          isDark: isDark,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _ActionCard(
                          title: 'Tablero de Cargas',
                          description:
                              'Explora cargas abiertas, filtra por ciudades colombianas, simula costos de ruta en tiempo real y postula tus ofertas de flete.',
                          buttonText: 'Ver Cargas',
                          icon: Icons.explore_rounded,
                          color: AppColors.secondary,
                          onPressed: () => context.go('/cargas'),
                          isDark: isDark,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _ActionCard(
                          title: 'Monitoreo de Viajes',
                          description:
                              'Supervisa viajes en curso, registra salida en ruta y confirma entrega final adjuntando observaciones y acta de recibo.',
                          buttonText: 'Ir a Mis Viajes',
                          icon: Icons.route_rounded,
                          color: AppColors.tertiary,
                          onPressed: () => context.go('/viajes'),
                          isDark: isDark,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _ActionCard(
                          title: 'Seguridad y Cumplimiento',
                          description:
                              'Verifica identidades, roles de empresa generadora, conductores certificados y empresas legalizadoras asociadas.',
                          buttonText: 'Ver Mi Cuenta',
                          icon: Icons.fact_check_rounded,
                          color: AppColors.success,
                          onPressed: () => context.go('/panel'),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.badge,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  final String title;
  final String value;
  final String badge;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: SaasDecoration.softShadow(isDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatefulWidget {
  const _ActionCard({
    required this.title,
    required this.description,
    required this.buttonText,
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.isDark,
  });

  final String title;
  final String description;
  final String buttonText;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isDark;

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isHovered
                ? widget.color.withValues(alpha: 0.6)
                : (widget.isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: _isHovered
              ? SaasDecoration.elevatedShadow(widget.isDark)
              : SaasDecoration.softShadow(widget.isDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: widget.isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              widget.description,
              style: TextStyle(
                fontSize: 13.5,
                color: widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: widget.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                minimumSize: const Size(0, 42),
              ),
              onPressed: widget.onPressed,
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text(widget.buttonText),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountDetails extends StatelessWidget {
  const _AccountDetails({
    required this.email,
    required this.roles,
    required this.isDark,
  });

  final String email;
  final List<String> roles;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              boxShadow: SaasDecoration.elevatedShadow(isDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        email.isNotEmpty ? email[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Usuario verificado en TRAXIA',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 20),
                const Text(
                  'Roles asignados',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: roles.map((r) {
                    return Chip(
                      label: Text(r),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 20),
                const Text(
                  'Cumplimiento y Seguridad',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu cuenta cuenta con autenticación segura por tokens JWT firmados, control de accesos por roles (RBAC) y soporte de inicio de sesión empresarial.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
