import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/app_providers.dart';
import 'theme_mode_toggle.dart';

enum AppNavSection {
  dashboard,
  publishLoad,
  loads,
  trips,
  account,
}

class AppNavBar extends ConsumerWidget implements PreferredSizeWidget {
  const AppNavBar({
    super.key,
    required this.currentSection,
    this.title,
    this.extraActions = const [],
  });

  final AppNavSection currentSection;
  final String? title;
  final List<Widget> extraActions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 860;
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final isAdmin = user?.roles.contains('ADMIN') ?? false;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 2,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: theme.dividerColor.withValues(alpha: 0.15),
          height: 1,
        ),
      ),
      leading: !isDesktop
          ? IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Abrir menú de navegación',
              onPressed: () => _openMobileMenu(context, ref, currentSection, isAdmin),
            )
          : null,
      titleSpacing: isDesktop ? 20 : 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo e identidad de marca
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              if (currentSection != AppNavSection.dashboard) {
                context.go('/panel');
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.local_shipping,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'TRAXIA',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: theme.colorScheme.onSurface,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'ADMIN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
          if (isDesktop) ...[
            const SizedBox(width: 28),
            // Enlaces de navegación desktop
            _DesktopNavLink(
              icon: Icons.space_dashboard_outlined,
              activeIcon: Icons.space_dashboard,
              label: 'Panel',
              isActive: currentSection == AppNavSection.dashboard,
              onTap: () => context.go('/panel'),
            ),
            const SizedBox(width: 8),
            _DesktopNavLink(
              icon: Icons.add_circle_outline,
              activeIcon: Icons.add_circle,
              label: 'Publicar Carga',
              isActive: currentSection == AppNavSection.publishLoad,
              onTap: () => context.go('/publicar-carga'),
            ),
            const SizedBox(width: 8),
            _DesktopNavLink(
              icon: Icons.search,
              activeIcon: Icons.travel_explore,
              label: 'Cargas Disponibles',
              isActive: currentSection == AppNavSection.loads,
              onTap: () => context.go('/cargas'),
            ),
            const SizedBox(width: 8),
            _DesktopNavLink(
              icon: Icons.route_outlined,
              activeIcon: Icons.route,
              label: 'Mis Viajes',
              isActive: currentSection == AppNavSection.trips,
              onTap: () => context.go('/viajes'),
            ),
          ] else if (title != null) ...[
            const SizedBox(width: 8),
            Text(
              '| $title',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      actions: [
        ...extraActions,
        const ThemeModeToggle(),
        const SizedBox(width: 4),
        if (user != null)
          _UserAccountMenu(
            email: user.email,
            roles: user.roles,
            onOpenAccountDetails: () => _showAccountDetailsModal(context, user.email, user.roles, user.id),
            onSignOut: () => _handleSignOut(context, ref),
          ),
        const SizedBox(width: 12),
      ],
    );
  }

  void _openMobileMenu(
    BuildContext context,
    WidgetRef ref,
    AppNavSection currentSection,
    bool isAdmin,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final auth = ref.read(authControllerProvider);
        final user = auth.user;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.local_shipping,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TRAXIA',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          user?.email ?? 'Sesión activa',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.space_dashboard_outlined),
                  title: const Text('Panel de inicio'),
                  selected: currentSection == AppNavSection.dashboard,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.go('/panel');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('Publicar Carga'),
                  selected: currentSection == AppNavSection.publishLoad,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.go('/publicar-carga');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.search),
                  title: const Text('Cargas Disponibles'),
                  selected: currentSection == AppNavSection.loads,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.go('/cargas');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.route_outlined),
                  title: const Text('Mis Viajes'),
                  selected: currentSection == AppNavSection.trips,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.go('/viajes');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Mi Cuenta y Perfil'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    if (user != null) {
                      _showAccountDetailsModal(context, user.email, user.roles, user.id);
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: theme.colorScheme.error),
                  title: Text(
                    'Cerrar Sesión',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _handleSignOut(context, ref);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAccountDetailsModal(
    BuildContext context,
    String email,
    List<String> roles,
    String id,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  email.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Mi Cuenta TRAXIA',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AccountDetailItem(label: 'Correo electrónico', value: email),
                const SizedBox(height: 12),
                _AccountDetailItem(
                  label: 'Roles de plataforma',
                  value: roles.isEmpty ? 'Usuario general' : roles.join(', '),
                ),
                const SizedBox(height: 12),
                _AccountDetailItem(
                  label: 'Identificador único',
                  value: id,
                  isCode: true,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Las operaciones de flete y transporte están habilitadas en tu cuenta.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final signedOut = await ref.read(authControllerProvider).signOut();
    if (signedOut && context.mounted) {
      context.go('/iniciar-sesion');
    }
  }
}

class _DesktopNavLink extends StatelessWidget {
  const _DesktopNavLink({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.8);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserAccountMenu extends StatelessWidget {
  const _UserAccountMenu({
    required this.email,
    required this.roles,
    required this.onOpenAccountDetails,
    required this.onSignOut,
  });

  final String email;
  final List<String> roles;
  final VoidCallback onOpenAccountDetails;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      tooltip: 'Perfil y cuenta',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          email.isNotEmpty ? email.substring(0, 1).toUpperCase() : 'U',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      onSelected: (value) {
        if (value == 'account') {
          onOpenAccountDetails();
        } else if (value == 'logout') {
          onSignOut();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                email,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                roles.isEmpty ? 'Usuario TRAXIA' : roles.join(', '),
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const Divider(),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'account',
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 18),
              SizedBox(width: 10),
              Text('Mi Cuenta / Perfil'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: theme.colorScheme.error),
              const SizedBox(width: 10),
              Text('Cerrar Sesión', style: TextStyle(color: theme.colorScheme.error)),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountDetailItem extends StatelessWidget {
  const _AccountDetailItem({
    required this.label,
    required this.value,
    this.isCode = false,
  });

  final String label;
  final String value;
  final bool isCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            fontFamily: isCode ? 'monospace' : null,
          ),
        ),
      ],
    );
  }
}
