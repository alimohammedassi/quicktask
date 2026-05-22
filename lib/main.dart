// lib/main.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/constants/app_colors.dart';
import 'core/providers/theme_provider.dart';
import 'core/database/database_service.dart';
import 'services/notification_service.dart';
import 'package:google_fonts/google_fonts.dart';

// Localization
import 'core/localization/app_localizations.dart';
import 'core/localization/locale_provider.dart';
import 'core/localization/l10n.dart';

// Providers and Services
import 'features/auth/data/datasources/supabase_auth_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'data/repositories/local_task_repository.dart';
import 'data/repositories/supabase_task_repository.dart';

import 'services/calendar_service.dart';
import 'presentation/providers/task_provider.dart';
import 'presentation/providers/current_task_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive local database
  await DatabaseService.init();

  await Supabase.initialize(
    url: 'https://fvhohltfuokekjiojefe.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ2aG9obHRmdW9rZWtqaW9qZWZlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg1MDcyNDAsImV4cCI6MjA5NDA4MzI0MH0.U-g8EveBTGcaU7iBrLK5oIitZdYlinSZZNv-LMTCl2s',
  );

  await NotificationService.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<SupabaseAuthDatasource>(create: (_) => SupabaseAuthDatasource()),
        Provider<AuthRepository>(
          create: (context) => AuthRepositoryImpl(
            datasource: context.read<SupabaseAuthDatasource>(),
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
          update: (context, user, previous) => LocalTaskRepository(userId: user?.id ?? 'guest'),
        ),
        Provider<SupabaseTaskRepository>(
          create: (_) => SupabaseTaskRepository(),
        ),
        Provider<CalendarService>(
          create: (context) => CalendarService(context.read<AuthRepository>()),
        ),
        ChangeNotifierProxyProvider4<User?, LocalTaskRepository, SupabaseTaskRepository, CalendarService, TasksNotifier>(
          create: (context) => TasksNotifier(
            context.read<LocalTaskRepository>(),
            context.read<SupabaseTaskRepository>(),
            context.read<CalendarService>(),
            'guest',
          ),
          update: (context, user, local, supabase, calendar, previous) {
            previous!.updateDependencies(user?.id ?? 'guest', local, supabase, calendar);
            return previous;
          },
        ),
        ChangeNotifierProxyProvider<TasksNotifier, CurrentTaskNotifier>(
          create: (context) => CurrentTaskNotifier(),
          update: (context, tasksNotifier, previous) {
            previous!.updateTasks(tasksNotifier.tasks);
            return previous;
          },
        ),
        ChangeNotifierProvider<LocaleProvider>(
          create: (_) => LocaleProvider(),
        ),
        ChangeNotifierProvider<ThemeNotifier>(
          create: (_) => ThemeNotifier(),
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

  ThemeData _buildTheme(AppThemeTokens tokens, bool isDark) {
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    return base.copyWith(
      extensions: [tokens],
      scaffoldBackgroundColor: tokens.background,
      colorScheme: (isDark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
        primary: tokens.mint,
        secondary: tokens.purple,
        surface: tokens.cardBg,
        onSurface: tokens.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.background,
        elevation: 0,
        foregroundColor: tokens.textPrimary,
      ),
      cardColor: tokens.cardBg,
      dividerColor: tokens.divider,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        base.textTheme.copyWith(
          displayLarge: const TextStyle(fontWeight: FontWeight.w200),
          displayMedium: const TextStyle(fontWeight: FontWeight.w200),
          displaySmall: const TextStyle(fontWeight: FontWeight.w200),
          headlineLarge: const TextStyle(fontWeight: FontWeight.w200),
          headlineMedium: const TextStyle(fontWeight: FontWeight.w200),
          headlineSmall: const TextStyle(fontWeight: FontWeight.w200),
          titleLarge: const TextStyle(fontWeight: FontWeight.w300),
          titleMedium: const TextStyle(fontWeight: FontWeight.w300),
          titleSmall: const TextStyle(fontWeight: FontWeight.w300),
          bodyLarge: const TextStyle(fontWeight: FontWeight.w200),
          bodyMedium: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.w200),
          bodySmall: const TextStyle(fontWeight: FontWeight.w200),
          labelLarge: const TextStyle(fontWeight: FontWeight.w300),
          labelMedium: const TextStyle(fontWeight: FontWeight.w300),
          labelSmall: const TextStyle(fontWeight: FontWeight.w300),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.mint,
        linearTrackColor: tokens.divider,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final themeNotifier = context.watch<ThemeNotifier>();
    final isDark = themeNotifier.isDark;
    final tokens = isDark ? darkTokens : lightTokens;

    return MaterialApp.router(
      title: 'QuickTask',
      debugShowCheckedModeBanner: false,
      locale: localeProvider.locale,
      supportedLocales: L10n.all,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: _buildTheme(tokens, isDark),
      routerConfig: _router,
    );
  }
}




