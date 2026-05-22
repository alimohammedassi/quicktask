// lib/core/providers/theme_provider.dart
import 'package:flutter/material.dart';
import '../database/database_service.dart';

class ThemeNotifier extends ChangeNotifier {
  bool _isDark = true;

  bool get isDark => _isDark;

  ThemeNotifier() {
    _loadTheme();
  }

  void _loadTheme() {
    try {
      _isDark = DatabaseService.settingsBox.get('isDark', defaultValue: true) as bool;
      notifyListeners();
    } catch (_) {
      _isDark = true;
    }
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    notifyListeners();
    try {
      await DatabaseService.settingsBox.put('isDark', _isDark);
    } catch (_) {}
  }

  Future<void> setDark(bool value) async {
    if (_isDark == value) return;
    _isDark = value;
    notifyListeners();
    try {
      await DatabaseService.settingsBox.put('isDark', _isDark);
    } catch (_) {}
  }
}
