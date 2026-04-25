// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/constants/app_colors.dart';
import 'core/database/database_service.dart';
import 'services/notification_service.dart';
import 'package:google_fonts/google_fonts.dart';

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

  runApp(const ProviderScope(child: QuickTaskApp()));
}

class QuickTaskApp extends ConsumerWidget {
  const QuickTaskApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'QuickTask',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: AppColors.bgLight,
        colorScheme: ColorScheme.light(
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
      routerConfig: router,
    );
  }
}
