import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _themeKey = 'app_theme';
  static const String _autoBackupKey = 'auto_backup';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _currencyKey = 'currency_symbol';
  static const String _dateFormatKey = 'date_format';
  static const String _languageKey = 'app_language';

  // Theme settings
  static Future<String> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'system';
  }

  static Future<void> setTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme);
  }

  // Auto backup settings
  static Future<bool> getAutoBackup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoBackupKey) ?? false;
  }

  static Future<void> setAutoBackup(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupKey, enabled);
  }

  // Notifications settings
  static Future<bool> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsKey) ?? true;
  }

  static Future<void> setNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }

  // Currency settings
  static Future<String> getCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencyKey) ?? 'TL';
  }

  static Future<void> setCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currency);
  }

  // Date format settings
  static Future<String> getDateFormat() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dateFormatKey) ?? 'dd.MM.yyyy';
  }

  static Future<void> setDateFormat(String format) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dateFormatKey, format);
  }

  // Language settings
  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'tr';
  }

  static Future<void> setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }

  // Clear all settings
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Get all settings as map for backup
  static Future<Map<String, dynamic>> getAllSettings() async {
    return {
      'theme': await getTheme(),
      'autoBackup': await getAutoBackup(),
      'notifications': await getNotifications(),
      'currency': await getCurrency(),
      'dateFormat': await getDateFormat(),
      'language': await getLanguage(),
    };
  }

  // Restore settings from map
  static Future<void> restoreSettings(Map<String, dynamic> settings) async {
    if (settings['theme'] != null) await setTheme(settings['theme']);
    if (settings['autoBackup'] != null) await setAutoBackup(settings['autoBackup']);
    if (settings['notifications'] != null) await setNotifications(settings['notifications']);
    if (settings['currency'] != null) await setCurrency(settings['currency']);
    if (settings['dateFormat'] != null) await setDateFormat(settings['dateFormat']);
    if (settings['language'] != null) await setLanguage(settings['language']);
  }
}
