// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../presentation/screens/home_screen.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../presentation/screens/main_shell_screen.dart';
import '../../presentation/screens/summary_screen.dart';
import '../../presentation/screens/profile_screen.dart';
import '../../presentation/screens/add_task_screen.dart';

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
    initialLocation: '/login',
    debugLogDiagnostics: false,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      // Never redirect away from splash – it handles navigation itself

      final user = context.read<User?>();
      final isLoggingIn =
          state.uri.path == '/login' || state.uri.path == '/register';

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
      GoRoute(
        path: '/add-task',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const AddTaskScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AuthWrapper(
            child: MainShellScreen(navigationShell: navigationShell),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/summary',
                builder: (context, state) => const SummaryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
