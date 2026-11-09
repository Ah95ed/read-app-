import 'package:shared_preferences/shared_preferences.dart';

/// Service abstraction for local persistent storage
class StorageService {
  final SharedPreferences _preferences;

  StorageService(this._preferences);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  int? getInt(String key) => _preferences.getInt(key);

  Future<bool> setInt(String key, int value) =>
      _preferences.setInt(key, value);

  String? getString(String key) => _preferences.getString(key);

  Future<bool> setString(String key, String value) =>
      _preferences.setString(key, value);

  bool? getBool(String key) => _preferences.getBool(key);

  Future<bool> setBool(String key, bool value) =>
      _preferences.setBool(key, value);

  List<String>? getStringList(String key) =>
      _preferences.getStringList(key);

  Future<bool> setStringList(String key, List<String> value) =>
      _preferences.setStringList(key, value);

  Future<bool> remove(String key) => _preferences.remove(key);
}

