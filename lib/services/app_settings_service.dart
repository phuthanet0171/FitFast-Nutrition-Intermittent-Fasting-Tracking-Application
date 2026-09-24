import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  AppSettingsService._();

  static final instance = AppSettingsService._();
  static const _notificationsKey = 'fitfast_app_notifications_enabled_v1';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<bool> notificationsEnabled() async =>
      await _preferences.getBool(_notificationsKey) ?? true;

  Future<void> setNotificationsEnabled(bool value) =>
      _preferences.setBool(_notificationsKey, value);

  Future<void> clear() => _preferences.remove(_notificationsKey);
}
