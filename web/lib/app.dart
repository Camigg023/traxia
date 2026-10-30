import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth/auth_controller.dart';
import 'screens/create_account_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/loads_screen.dart';
import 'screens/publish_load_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/trips_screen.dart';
import 'screens/verify_email_screen.dart';
import 'state/app_providers.dart';
import 'theme/app_theme.dart';

class TraxiaApp extends ConsumerStatefulWidget {
  const TraxiaApp({super.key});

  @override
  ConsumerState<TraxiaApp> createState() => _TraxiaAppState();
}

class _TraxiaAppState extends ConsumerState<TraxiaApp> {
  late final AuthController _authController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authController = ref.read(authControllerProvider);
    _router = GoRouter(
      initialLocation: '/',
      refreshListenable: _authController,
      redirect: (context, state) {
        final path = state.uri.path;
        final isSignedIn = _authController.status == AuthStatus.signedIn;
        if (_authController.status == AuthStatus.restoring) {
          return null;
        }

        final authOnlyPaths = [
          '/panel',
          '/publicar-carga',
          '/publish-load',
          '/viajes',
          '/trips',
        ];
        final unauthOnlyPaths = ['/iniciar-sesion', '/crear-cuenta'];

        if (path == '/') {
          return isSignedIn ? '/panel' : '/iniciar-sesion';
        }
        if (isSignedIn && unauthOnlyPaths.contains(path)) {
          return '/panel';
        }
        if (!isSignedIn && authOnlyPaths.contains(path)) {
          return '/iniciar-sesion';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
        ),
        GoRoute(
          path: '/iniciar-sesion',
          builder: (context, state) => const SignInScreen(),
        ),
        GoRoute(
          path: '/crear-cuenta',
          builder: (context, state) => CreateAccountScreen(
            googleIdToken: state.extra as String?,
          ),
        ),
        GoRoute(
          path: '/verificar-correo',
          builder: (context, state) => VerifyEmailScreen(
            token: state.uri.queryParameters['token'],
          ),
        ),
        GoRoute(
          path: '/panel',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/publicar-carga',
          builder: (context, state) => const PublishLoadScreen(),
        ),
        GoRoute(
          path: '/publish-load',
          builder: (context, state) => const PublishLoadScreen(),
        ),
        GoRoute(
          path: '/cargas',
          builder: (context, state) => const LoadsScreen(),
        ),
        GoRoute(
          path: '/loads',
          builder: (context, state) => const LoadsScreen(),
        ),
        GoRoute(
          path: '/viajes',
          builder: (context, state) => const TripsScreen(),
        ),
        GoRoute(
          path: '/trips',
          builder: (context, state) => const TripsScreen(),
        ),
      ],
    );
    unawaited(_authController.restoreSession());
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'TRAXIA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      routerConfig: _router,
    );
  }
}
