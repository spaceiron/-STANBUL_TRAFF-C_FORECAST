class AppConfig {
  /// Cloud API (Render). Override for local dev:
  /// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://stanbul-traff-c-forecast.onrender.com',
  );
}
