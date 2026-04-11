import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) throw Exception('StorageService not initialized');
    return _prefs!;
  }

  // Token
  static String? getToken() => prefs.getString(AppConstants.tokenKey);
  static Future<bool> setToken(String token) =>
      prefs.setString(AppConstants.tokenKey, token);
  static Future<bool> removeToken() => prefs.remove(AppConstants.tokenKey);

  // User data (stored as JSON)
  static Map<String, dynamic>? getUser() {
    final data = prefs.getString(AppConstants.userKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  static Future<bool> setUser(Map<String, dynamic> user) =>
      prefs.setString(AppConstants.userKey, jsonEncode(user));
  static Future<bool> removeUser() => prefs.remove(AppConstants.userKey);

  // Theme
  static String getThemeMode() =>
      prefs.getString(AppConstants.themeKey) ?? 'light';
  static Future<bool> setThemeMode(String mode) =>
      prefs.setString(AppConstants.themeKey, mode);

  // Locale
  static String getLocale() =>
      prefs.getString(AppConstants.localeKey) ?? 'en';
  static Future<bool> setLocale(String locale) =>
      prefs.setString(AppConstants.localeKey, locale);

  // Notifications (stored as JSON array)
  static List<Map<String, dynamic>> getNotifications() {
    final data = prefs.getString(AppConstants.notificationsKey);
    if (data == null) return [];
    final list = jsonDecode(data) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  static Future<bool> setNotifications(List<Map<String, dynamic>> items) =>
      prefs.setString(AppConstants.notificationsKey, jsonEncode(items));

  // Clear all
  static Future<bool> clearAll() => prefs.clear();

  // Is logged in
  static bool isLoggedIn() {
    final token = getToken();
    return token != null && token.isNotEmpty;
  }
}
