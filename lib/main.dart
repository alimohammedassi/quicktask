// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/constants/app_colors.dart';
import 'core/database/database_service.dart';
import 'services/notification_service.dart';
import 'package:google_fonts/google_fonts.dart';

// Providers and Services
import 'features/auth/data/datasources/firebase_auth_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'data/repositories/local_task_repository.dart';
import 'data/repositories/task_repository.dart';
import 'services/calendar_service.dart';
import 'presentation/providers/task_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive local database
  await DatabaseService.init();

  // Prevent duplicate initialization during hot reload / debug restarts
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
    // Already initialized – safe to continue
  }

  await NotificationService.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<FirebaseAuthDatasource>(create: (_) => FirebaseAuthDatasource()),
        Provider<AuthRepository>(
          create: (context) => AuthRepositoryImpl(
            datasource: context.read<FirebaseAuthDatasource>(),
          ),
        ),
        ChangeNotifierProvider<AuthNotifier>(
          create: (context) => AuthNotifier(context.read<AuthRepository>()),
        ),
        StreamProvider<User?>(
          create: (context) => context.read<AuthRepository>().authStateChanges,
          initialData: null,
        ),
        ProxyProvider<User?, LocalTaskRepository>(
          update: (context, user, previous) => LocalTaskRepository(userId: user?.uid ?? 'guest'),
        ),
        ProxyProvider<User?, TaskRepository>(
          update: (context, user, previous) => TaskRepository(userId: user?.uid ?? 'guest'),
        ),
        Provider<CalendarService>(
          create: (context) => CalendarService(context.read<AuthRepository>()),
        ),
        ChangeNotifierProxyProvider4<User?, LocalTaskRepository, TaskRepository, CalendarService, TasksNotifier>(
          create: (context) => TasksNotifier(
            context.read<LocalTaskRepository>(),
            context.read<TaskRepository>(),
            context.read<CalendarService>(),
            'guest',
          ),
          update: (context, user, local, remote, calendar, previous) {
            previous!.updateDependencies(user?.uid ?? 'guest', local, remote, calendar);
            return previous;
          },
        ),
      ],
      child: const QuickTaskApp(),
    ),
  );
}

class QuickTaskApp extends StatefulWidget {
  const QuickTaskApp({super.key});

  @override
  State<QuickTaskApp> createState() => _QuickTaskAppState();
}

class _QuickTaskAppState extends State<QuickTaskApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(context.read<AuthNotifier>());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'QuickTask',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: AppColors.bgLight,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          elevation: 0,
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).copyWith(
          bodyMedium: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
      routerConfig: _router,
    );
  }
}
