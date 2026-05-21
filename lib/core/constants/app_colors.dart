// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const background = Color(0xFF000000);
  static const cardBg = Color(0xFF0C0C0C);
  static const innerCard = Color(0xFF1E1E1E);

  // ── Accent palette ─────────────────────────────────────────
  static const mint = Color(0xFFB8F0C8);
  static const purple = Color(0xFFD4BFFF);
  static const yellow = Color(0xFFF5EFA0);
  static const gold = Color(0xFFF5EFA0);

  // ── Text ───────────────────────────────────────────────────
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFA0A0A0);
  static const textDark = Color(0xFF000000);
  static const textHint = Color(0xFF606060);

  // ── Borders / dividers ─────────────────────────────────────
  static const divider = Color(0xFF2A2A2A);
  static const cardBorder = Color(0xFF2A2A2A);
  static const checkboxBorder = Color(0xFF3A3A3A);

  // ── Status ─────────────────────────────────────────────────
  static const error = Color(0xFFFF6B6B);
  static const success = Color(0xFFB8F0C8);
  static const warning = Color(0xFFF5EFA0);

  // ── Navigation ─────────────────────────────────────────────
  static const navActive = Color(0xFFFFFFFF);
  static const navInactive = Color(0xFF606060);

  // ── Legacy aliases (keeps auth screens working) ────────────
  static const primary = Color(0xFF1E1B4B);
  static const primaryLight = Color(0xFF4F46E5);
  static const accent = Color(0xFFB8F0C8);
  static const bgLight = Color(0xFF0D0D0D);
  static const bgDark = Color(0xFF0D0D0D);
  static const bgAuthDark = Color(0xFF0D0D14);
  static const surface = Color(0xFF1A1A1A);
  static const accentPurple = Color(0xFFD4BFFF);
  static const accentYellow = Color(0xFFF5EFA0);
  static const textDarkAlias = Color(0xFF111827);
}
