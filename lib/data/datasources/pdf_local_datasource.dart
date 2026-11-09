import '../../core/constants/app_constants.dart';
import '../../core/services/storage_service.dart';

abstract class IPdfLocalDataSource {
  Future<int> getLastPage(String documentKey);
  Future<bool> saveLastPage(String documentKey, int page);
  Future<bool> getScrollDirection();
  Future<bool> saveScrollDirection(bool isVertical);
  Future<String> getThemeMode();
  Future<bool> saveThemeMode(String themeMode);
  Future<String> getLocale();
  Future<bool> saveLocale(String localeCode);
}

class PdfLocalDataSourceImpl implements IPdfLocalDataSource {
  final StorageService _storageService;

  PdfLocalDataSourceImpl(this._storageService);

  @override
  Future<int> getLastPage(String documentKey) async {
    final key = '${AppConstants.keyLastPage}_$documentKey';
    return _storageService.getInt(key) ?? 1;
  }

  @override
  Future<bool> saveLastPage(String documentKey, int page) async {
    final key = '${AppConstants.keyLastPage}_$documentKey';
    return _storageService.setInt(key, page);
  }

  @override
  Future<bool> getScrollDirection() async {
    return _storageService.getBool(AppConstants.keyScrollDirection) ?? true;
  }

  @override
  Future<bool> saveScrollDirection(bool isVertical) async {
    return _storageService.setBool(AppConstants.keyScrollDirection, isVertical);
  }

  @override
  Future<String> getThemeMode() async {
    return _storageService.getString(AppConstants.keyThemeMode) ?? 'light';
  }

  @override
  Future<bool> saveThemeMode(String themeMode) async {
    return _storageService.setString(AppConstants.keyThemeMode, themeMode);
  }

  @override
  Future<String> getLocale() async {
    return _storageService.getString(AppConstants.keyLocale) ?? 'ar';
  }

  @override
  Future<bool> saveLocale(String localeCode) async {
    return _storageService.setString(AppConstants.keyLocale, localeCode);
  }
}

