import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/app_providers.dart';
import '../theme/app_colors.dart';
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
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final isAdmin = user?.roles.contains('ADMIN') ?? false;

    // Glassmorphism sutil para la barra superior
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: preferredSize.height,
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkSurface : Colors.white).withValues(alpha: 0.82),
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                if (!isDesktop) ...[
                  IconButton(
                    icon: const Icon(Icons.menu_rounded),
                    tooltip: 'Abrir menú',
                    onPressed: () => _openMobileMenu(context, ref, currentSection, isAdmin),
                  ),
                  const SizedBox(width: 8),
                ],

                // Logo e isotipo SaaS TRAXIA
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    if (currentSection != AppNavSection.dashboard) {
                      context.go('/panel');
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.local_shipping_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'TRAXIA',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            fontSize: 19,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (isAdmin) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ADMIN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],

                // Navegación central en Desktop
                if (isDesktop) ...[
                  const SizedBox(width: 32),
                  _DesktopNavLink(
                    icon: Icons.grid_view_rounded,
                    label: 'Panel',
                    isActive: currentSection == AppNavSection.dashboard,
                    onTap: () => context.go('/panel'),
                  ),
                  const SizedBox(width: 4),
                  _DesktopNavLink(
                    icon: Icons.add_box_rounded,
                    label: 'Publicar Carga',
                    isActive: currentSection == AppNavSection.publishLoad,
                    onTap: () => context.go('/publicar-carga'),
                  ),
                  const SizedBox(width: 4),
                  _DesktopNavLink(
                    icon: Icons.explore_rounded,
                    label: 'Cargas Disponibles',
                    isActive: currentSection == AppNavSection.loads,
                    onTap: () => context.go('/cargas'),
                  ),
                  const SizedBox(width: 4),
                  _DesktopNavLink(
                    icon: Icons.route_rounded,
                    label: 'Mis Viajes',
                    isActive: currentSection == AppNavSection.trips,
                    onTap: () => context.go('/viajes'),
                  ),
                ],

                const Spacer(),

                // Acciones adicionales (refresh, botones contextuales)
                ...extraActions,

                const SizedBox(width: 6),
                const ThemeModeToggle(),
                const SizedBox(width: 12),

                // Perfil de usuario / Logout
                if (user != null) ...[
                  _UserMenuButton(user: user, onLogout: () => _confirmLogout(context, ref)),
                ],
              ],
            ),
          ),
        ),
      ),
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
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _MobileMenuItem(
                icon: Icons.grid_view_rounded,
                label: 'Panel General',
                isActive: currentSection == AppNavSection.dashboard,
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/panel');
                },
              ),
              _MobileMenuItem(
                icon: Icons.add_box_rounded,
                label: 'Publicar Carga',
                isActive: currentSection == AppNavSection.publishLoad,
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/publicar-carga');
                },
              ),
              _MobileMenuItem(
                icon: Icons.explore_rounded,
                label: 'Cargas Disponibles',
                isActive: currentSection == AppNavSection.loads,
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/cargas');
                },
              ),
              _MobileMenuItem(
                icon: Icons.route_rounded,
                label: 'Mis Viajes Activos',
                isActive: currentSection == AppNavSection.trips,
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/viajes');
                },
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _confirmLogout(context, ref);
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Cerrar sesión'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
          'Finalizarás tu sesión actual en TRAXIA. Podrás volver a entrar con tus credenciales en cualquier momento.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authControllerProvider).signOut();
              if (context.mounted) {
                context.go('/iniciar-sesion');
              }
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}

class _DesktopNavLink extends StatefulWidget {
  const _DesktopNavLink({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_DesktopNavLink> createState() => _DesktopNavLinkState();
}

class _DesktopNavLinkState extends State<_DesktopNavLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color textColor;
    final Color iconColor;
    final Color bgColor;

    if (widget.isActive) {
      textColor = AppColors.primary;
      iconColor = AppColors.primary;
      bgColor = AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08);
    } else if (_isHovered) {
      textColor = theme.colorScheme.onSurface;
      iconColor = AppColors.primary;
      bgColor = isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle;
    } else {
      textColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
      iconColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
      bgColor = Colors.transparent;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: widget.isActive
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileMenuItem extends StatelessWidget {
  const _MobileMenuItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? AppColors.primary : theme.colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          color: isActive ? AppColors.primary : theme.colorScheme.onSurface,
        ),
      ),
      selected: isActive,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}

class _UserMenuButton extends StatelessWidget {
  const _UserMenuButton({required this.user, required this.onLogout});

  final dynamic user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final email = (user.email as String?) ?? 'usuario';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'U';

    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      tooltip: 'Cuenta de usuario',
      onSelected: (val) {
        if (val == 'logout') {
          onLogout();
        } else if (val == 'panel') {
          context.go('/panel');
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sesión activa',
                style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              ),
              const SizedBox(height: 2),
              Text(
                email,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'panel',
          child: Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 18),
              SizedBox(width: 10),
              Text('Mi perfil y roles', style: TextStyle(fontSize: 13.5)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
              SizedBox(width: 10),
              Text('Cerrar sesión', style: TextStyle(fontSize: 13.5, color: AppColors.error)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: Text(
                email,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ],
        ),
      ),
    );
  }
}
