import '../models/route_feedback_prediction_models.dart';
import '../services/app_settings_service.dart';

class LocaleHelper {
  static String tr(String tr, String en, AppLanguage lang) =>
      lang == AppLanguage.en ? en : tr;

  static String densityLabel(double score, AppLanguage lang) {
    final pct = (score * 100).round();
    if (lang == AppLanguage.en) {
      if (score < 0.33) return '$pct% Empty';
      if (score < 0.66) return '$pct% Medium';
      return '$pct% Full';
    }
    if (score < 0.33) return '$pct% Boş';
    if (score < 0.66) return '$pct% Orta Yoğun';
    return '$pct% Dolu';
  }

  static String confidenceLabel(double score, AppLanguage lang) {
    final pct = (score * 100).round();
    if (lang == AppLanguage.en) {
      if (score < 0.5) return 'Low confidence ($pct%)';
      if (score < 0.75) return 'Medium confidence ($pct%)';
      return 'High confidence ($pct%)';
    }
    if (score < 0.5) return 'Düşük güven ($pct%)';
    if (score < 0.75) return 'Orta güven ($pct%)';
    return 'Yüksek güven ($pct%)';
  }

  static String incidentSeverityLabel(String raw, AppLanguage lang) {
    switch (raw.toLowerCase()) {
      case 'high':
        return tr('Yüksek', 'High', lang);
      case 'medium':
        return tr('Orta', 'Medium', lang);
      default:
        return tr('Düşük', 'Low', lang);
    }
  }

  static String incidentTitle(Map<String, dynamic> incident, AppLanguage lang) {
    if (lang == AppLanguage.tr) {
      return (incident['title'] ?? 'Olay').toString();
    }
    final routeId = (incident['routeId'] ?? '').toString();
    switch ((incident['type'] ?? '').toString().toLowerCase()) {
      case 'accident':
        return 'Accident reported on $routeId line';
      case 'roadwork':
        return 'Roadwork on $routeId line';
      case 'closure':
        return 'Previous closure cleared on $routeId line';
      default:
        return (incident['title'] ?? 'Incident').toString();
    }
  }

  static String transportTypeLabel(TransportType type, AppLanguage lang) {
    if (lang == AppLanguage.en) {
      return switch (type) {
        TransportType.metro => 'Metro',
        TransportType.metrobus => 'Metrobus',
        TransportType.tram => 'Tram',
        TransportType.bus => 'Bus',
      };
    }
    return switch (type) {
      TransportType.metro => 'Metro',
      TransportType.metrobus => 'Metrobüs',
      TransportType.tram => 'Tramvay',
      TransportType.bus => 'Otobüs',
    };
  }

  static String lineName(String routeId, AppLanguage lang) =>
      lang == AppLanguage.en ? '$routeId Line' : '$routeId Hattı';

  static String densityAlertTitle(String routeId, AppLanguage lang) =>
      lang == AppLanguage.en ? '$routeId Line Alert' : '$routeId Hattı Uyarısı';

  static String densityAlertBody(int pct, AppLanguage lang) =>
      lang == AppLanguage.en
          ? 'Density reached $pct%.'
          : 'Yoğunluk %$pct seviyesine ulaştı.';

  static String incidentAlertTitle(String routeId, AppLanguage lang) =>
      lang == AppLanguage.en ? '$routeId Incident Alert' : '$routeId Olay Uyarısı';

  static String delayText(int delayMin, AppLanguage lang) =>
      delayMin > 0
          ? tr('~$delayMin dk gecikme', '~$delayMin min delay', lang)
          : tr('gecikme beklenmiyor', 'no delay expected', lang);

  static String speedSnippet(double speed, AppLanguage lang) =>
      tr(
        'Hız: ${speed.toStringAsFixed(0)} km/h',
        'Speed: ${speed.toStringAsFixed(0)} km/h',
        lang,
      );

  static String notificationChannelName(AppLanguage lang) =>
      tr('Trafik Yoğunluğu', 'Traffic Density', lang);

  static String notificationChannelDescription(AppLanguage lang) =>
      tr(
        'Favori hatlarınızdaki yoğunluk değişikliklerini bildirir.',
        'Alerts you about density changes on your favorite lines.',
        lang,
      );
}
