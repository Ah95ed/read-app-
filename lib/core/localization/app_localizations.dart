import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'translations_ar.dart';
import 'translations_en.dart';

/// Application Localizations manager
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('ar'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('ar', ''),
    Locale('en', ''),
  ];

  Map<String, String> get _currentTranslations {
    if (locale.languageCode == 'en') {
      return translationsEn;
    }
    return translationsAr;
  }

  /// Translate a key, optionally replacing `{placeholder}` arguments
  String translate(String key, {Map<String, dynamic>? args}) {
    String text = _currentTranslations[key] ?? key;
    if (args != null) {
      args.forEach((k, v) {
        text = text.replaceAll('{$k}', v.toString());
      });
    }
    return text;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Convenience extension on BuildContext to get translations easily
extension LocalizationExtension on BuildContext {
  String tr(String key, {Map<String, dynamic>? args}) {
    return AppLocalizations.of(this).translate(key, args: args);
  }

  bool get isRtl {
    return Directionality.of(this) == TextDirection.rtl;
  }
}

