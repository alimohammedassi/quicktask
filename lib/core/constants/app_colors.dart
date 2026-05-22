// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  final Color background;
  final Color cardBg;
  final Color innerCard;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color textDark;
  final Color mint;
  final Color purple;
  final Color yellow;
  final Color gold;
  final Color error;
  final Color navActive;
  final Color navInactive;
  final Color checkboxBorder;

  const AppThemeTokens({
    required this.background,
    required this.cardBg,
    required this.innerCard,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.textDark,
    required this.mint,
    required this.purple,
    required this.yellow,
    required this.gold,
    required this.error,
    required this.navActive,
    required this.navInactive,
    required this.checkboxBorder,
  });

  @override
  AppThemeTokens copyWith({
    Color? background,
    Color? cardBg,
    Color? innerCard,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? textDark,
    Color? mint,
    Color? purple,
    Color? yellow,
    Color? gold,
    Color? error,
    Color? navActive,
    Color? navInactive,
    Color? checkboxBorder,
  }) {
    return AppThemeTokens(
      background: background ?? this.background,
      cardBg: cardBg ?? this.cardBg,
      innerCard: innerCard ?? this.innerCard,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      textDark: textDark ?? this.textDark,
      mint: mint ?? this.mint,
      purple: purple ?? this.purple,
      yellow: yellow ?? this.yellow,
      gold: gold ?? this.gold,
      error: error ?? this.error,
      navActive: navActive ?? this.navActive,
      navInactive: navInactive ?? this.navInactive,
      checkboxBorder: checkboxBorder ?? this.checkboxBorder,
    );
  }

  @override
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) return this;
    return AppThemeTokens(
      background: Color.lerp(background, other.background, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      innerCard: Color.lerp(innerCard, other.innerCard, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      textDark: Color.lerp(textDark, other.textDark, t)!,
      mint: Color.lerp(mint, other.mint, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      yellow: Color.lerp(yellow, other.yellow, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      error: Color.lerp(error, other.error, t)!,
      navActive: Color.lerp(navActive, other.navActive, t)!,
      navInactive: Color.lerp(navInactive, other.navInactive, t)!,
      checkboxBorder: Color.lerp(checkboxBorder, other.checkboxBorder, t)!,
    );
  }
}

const darkTokens = AppThemeTokens(
  background: Color(0xFF0D0F1A),
  cardBg: Color(0xFF141720),
  innerCard: Color(0xFF1C1F2E),
  divider: Color(0xFF1E2440),
  textPrimary: Color(0xFFF0F2FF),
  textSecondary: Color(0xFF7B82A8),
  textHint: Color(0xFF3E4466),
  textDark: Color(0xFF0D0F1A),
  navActive: Color(0xFFFFFFFF),
  navInactive: Color(0xFF3E4466),
  checkboxBorder: Color(0xFF3E4466),
  mint: Color(0xFF3DD8C9),
  purple: Color(0xFFD4BFFF),
  yellow: Color(0xFFF5EFA0),
  gold: Color(0xFFF5C842),
  error: Color(0xFFEF4444),
);

const lightTokens = AppThemeTokens(
  background: Color(0xFFF4F6FB),
  cardBg: Color(0xFFFFFFFF),
  innerCard: Color(0xFFEEF1F8),
  divider: Color(0xFFDDE2F0),
  textPrimary: Color(0xFF0D0F1A),
  textSecondary: Color(0xFF5A6282),
  textHint: Color(0xFF9BA3BF),
  textDark: Color(0xFF0D0F1A),
  navActive: Color(0xFF0D0F1A),
  navInactive: Color(0xFF9BA3BF),
  checkboxBorder: Color(0xFFC5CCDF),
  mint: Color(0xFF2EC4B6),
  purple: Color(0xFF7C5CBF),
  yellow: Color(0xFFC9A227),
  gold: Color(0xFFC9A227),
  error: Color(0xFFDC2626),
);

extension BuildContextTokens on BuildContext {
  AppThemeTokens get tokens => Theme.of(this).extension<AppThemeTokens>() ?? darkTokens;
}

class AppColors {
  AppColors._();

  // Legacy static values (used during intermediate refactoring steps)
  static const background = Color(0xFF0D0F1A);
  static const cardBg = Color(0xFF141720);
  static const innerCard = Color(0xFF1C1F2E);
  static const divider = Color(0xFF1E2440);
  static const textPrimary = Color(0xFFF0F2FF);
  static const textSecondary = Color(0xFF7B82A8);
  static const textHint = Color(0xFF3E4466);
  static const textDark = Color(0xFF0D0F1A);
  static const navActive = Color(0xFFFFFFFF);
  static const navInactive = Color(0xFF3E4466);
  static const checkboxBorder = Color(0xFF3E4466);
  static const mint = Color(0xFF3DD8C9);
  static const purple = Color(0xFFD4BFFF);
  static const yellow = Color(0xFFF5EFA0);
  static const gold = Color(0xFFF5C842);
  static const error = Color(0xFFEF4444);

  // Keep success/warning/accent for legacy compatibility
  static const success = Color(0xFF3DD8C9);
  static const warning = Color(0xFFF5EFA0);
  static const accent = Color(0xFF3DD8C9);

  // Legacy aliases (keeps auth screens working during refactoring)
  static const primary = Color(0xFF1E1B4B);
  static const primaryLight = Color(0xFF4F46E5);
  static const bgLight = Color(0xFF0D0D0D);
  static const bgDark = Color(0xFF0D0D0D);
  static const bgAuthDark = Color(0xFF0D0D14);
  static const surface = Color(0xFF1A1A1A);

  static Color getCategoryColor(String cat) {
    switch (cat.toLowerCase().trim()) {
      case 'work':
        return AppColors.purple;
      case 'personal':
        return AppColors.mint;
      case 'health':
      case 'fitness':
        return AppColors.error;
      case 'study':
      case 'learning':
        return AppColors.yellow;
      case 'family':
      case 'home':
        return AppColors.gold;
      default:
        return AppColors.mint;
    }
  }
}
