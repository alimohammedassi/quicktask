// lib/core/localization/locale_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'l10n.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  LocaleProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('selected_language');

      if (languageCode != null) {
        _locale = Locale(languageCode);
      } else {
        // Auto-detect device language
        final String systemLanguage = Platform.localeName.split('_')[0];
        if (L10n.all.any((element) => element.languageCode == systemLanguage)) {
          _locale = Locale(systemLanguage);
        } else {
          _locale = const Locale('en');
        }
      }
      notifyListeners();
    } catch (e) {
      // Fallback in case of storage issues
      _locale = const Locale('en');
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!L10n.all.contains(locale)) return;

    _locale = locale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_language', locale.languageCode);
    } catch (_) {}
  }

  void clearLocale() async {
    _locale = const Locale('en');
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_language');
    } catch (_) {}
  }
}
