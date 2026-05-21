// lib/core/localization/app_localizations.dart
import 'package:flutter/material.dart';
import 'translations/en_translations.dart';
import 'translations/ar_translations.dart';
import 'translations/de_translations.dart';
import 'translations/fr_translations.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  late Map<String, String> _localizedStrings;

  void load() {
    switch (locale.languageCode) {
      case 'ar':
        _localizedStrings = arTranslations;
        break;
      case 'de':
        _localizedStrings = deTranslations;
        break;
      case 'fr':
        _localizedStrings = frTranslations;
        break;
      case 'en':
      default:
        _localizedStrings = enTranslations;
        break;
    }
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  bool isRtl() => locale.languageCode == 'ar';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar', 'de', 'fr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}

extension AppLocalizationsExtension on BuildContext {
  String translate(String key) {
    return AppLocalizations.of(this)?.translate(key) ?? key;
  }

  bool get isRtl => AppLocalizations.of(this)?.isRtl() ?? false;
}
