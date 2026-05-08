// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../constants/app_colors.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';

// ─── Auth Guard Wrapper ───────────────────────────────────────────────────────

class AuthWrapper extends StatelessWidget {
  final Widget child;

  const AuthWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // With GoRouter redirect, this wrapper might be redundant, but keeping it for safety.
    final user = context.watch<User?>();
    
    if (user != null) {
      return child;
    }
    return const LoginScreen();
  }
}

// ─── Router Instance ──────────────────────────────────────────────────────────

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter(AuthNotifier authNotifier) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/home',
    debugLogDiagnostics: false,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final user = context.read<User?>();
      final isLoggingIn = state.uri.path == '/login' || state.uri.path == '/register';
      
      if (user != null) {
        return isLoggingIn ? '/home' : null;
      }
      return isLoggingIn ? null : '/login';
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AuthWrapper(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
        ],
      ),
    ],
  );
}
