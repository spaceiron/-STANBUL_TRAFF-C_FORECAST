import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { tr, en }

class AppSettingsService {
  static const _languageKey = 'app_language';
  static const _densityAlertThresholdKey = 'density_alert_threshold';

  Future<AppLanguage> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_languageKey) ?? 'tr';
    return raw == 'en' ? AppLanguage.en : AppLanguage.tr;
  }

  Future<void> setLanguage(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language == AppLanguage.en ? 'en' : 'tr');
  }

  Future<int> getDensityAlertThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_densityAlertThresholdKey) ?? 85;
  }

  Future<void> setDensityAlertThreshold(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_densityAlertThresholdKey, value.clamp(50, 100));
  }
}
