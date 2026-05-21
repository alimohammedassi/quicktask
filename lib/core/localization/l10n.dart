// lib/core/localization/l10n.dart
import 'package:flutter/material.dart';

class L10n {
  static final all = [
    const Locale('en'), // English
    const Locale('ar'), // Arabic
    const Locale('de'), // German
    const Locale('fr'), // French
  ];

  static String getLanguageName(String code) {
    switch (code) {
      case 'ar':
        return 'العربية';
      case 'de':
        return 'Deutsch';
      case 'fr':
        return 'Français';
      case 'en':
      default:
        return 'English';
    }
  }

  static String getFlag(String code) {
    switch (code) {
      case 'ar':
        return '🇸🇦';
      case 'de':
        return '🇩🇪';
      case 'fr':
        return '🇫🇷';
      case 'en':
      default:
        return '🇺🇸';
    }
  }
}
