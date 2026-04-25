// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary palette — Deep Indigo
  static const primary = Color(0xFF1E1B4B);
  static const primaryLight = Color(0xFF4F46E5); // Indigo/Violet accent
  static const accent = Color(0xFF8B5CF6); // Violet accent

  // Backgrounds
  static const bgLight = Color(0xFFF8F9FA); // Light surface
  static const surface = Color(0xFFFFFFFF);
  static const cardBg = Color(0xFFFFFFFF);

  // Text
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint = Color(0xFF9CA3AF);

  // Status
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const success = Color(0xFF10B981);
  static const cardBorder = Color(0xFF1E1E30);
  static const bgDark = Color(0xFF0D0D14);

  // Gradients
  static const gradientStart = Color(0xFF312E81);
  static const gradientEnd = Color(0xFF1E1B4B);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF9FAFB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
