import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';

class AppSettingsController extends ChangeNotifier {
  final StorageService _storageService;

  Locale _currentLocale = const Locale('ar');
  AppThemeMode _currentThemeMode = AppThemeMode.light;

  AppSettingsController(this._storageService) {
    _loadSettings();
  }

  Locale get currentLocale => _currentLocale;
  AppThemeMode get currentThemeMode => _currentThemeMode;

  ThemeData get themeData {
    switch (_currentThemeMode) {
      case AppThemeMode.dark:
        return AppTheme.darkTheme;
      case AppThemeMode.sepia:
        return AppTheme.sepiaTheme;
      case AppThemeMode.light:
        return AppTheme.lightTheme;
    }
  }

  void _loadSettings() {
    final savedLocale = _storageService.getString(AppConstants.keyLocale) ?? 'ar';
    _currentLocale = Locale(savedLocale);

    final savedTheme = _storageService.getString(AppConstants.keyThemeMode) ?? 'light';
    switch (savedTheme) {
      case 'dark':
        _currentThemeMode = AppThemeMode.dark;
        break;
      case 'sepia':
        _currentThemeMode = AppThemeMode.sepia;
        break;
      default:
        _currentThemeMode = AppThemeMode.light;
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_currentLocale == locale) return;
    _currentLocale = locale;
    await _storageService.setString(AppConstants.keyLocale, locale.languageCode);
    notifyListeners();
  }

  Future<void> toggleLocale() async {
    final newLocale = _currentLocale.languageCode == 'ar'
        ? const Locale('en')
        : const Locale('ar');
    await setLocale(newLocale);
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_currentThemeMode == mode) return;
    _currentThemeMode = mode;
    String modeString = 'light';
    if (mode == AppThemeMode.dark) modeString = 'dark';
    if (mode == AppThemeMode.sepia) modeString = 'sepia';

    await _storageService.setString(AppConstants.keyThemeMode, modeString);
    notifyListeners();
  }
}

