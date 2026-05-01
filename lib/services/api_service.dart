// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/route_feedback_prediction_models.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String _baseUrl = AppConfig.apiBaseUrl;
  static const Duration _timeout = Duration(seconds: 12);

  final _client = http.Client();

  Uri _uri(String path, [Map<String, String>? params]) =>
      Uri.parse('$_baseUrl$path').replace(queryParameters: params);

  Future<Map<String, dynamic>> _get(String path,
      [Map<String, String>? params]) async {
    try {
      final res = await _client.get(_uri(path, params)).timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      throw ApiException('Sunucu hatası: ${res.statusCode}', res.statusCode);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Bağlantı hatası: $e', 0);
    }
  }

  Future<PredictionResult> getPrediction(
    String routeId, {
    double? lat,
    double? lng,
    double? speed,
  }) async {
    final params = <String, String>{};
    if (lat != null) params['lat'] = lat.toString();
    if (lng != null) params['lng'] = lng.toString();
    if (speed != null) params['speed'] = speed.toString();
    final data = await _get('/get_prediction/$routeId', params);
    return PredictionResult.fromJson(data);
  }

  Future<PredictionModel> predictLocation(
      double lat, double lng, {double speed = 50}) async {
    final data = await _get('/predict_location', {
      'lat':   lat.toString(),
      'lng':   lng.toString(),
      'speed': speed.toString(),
    });
    return PredictionModel(
      predId:       'loc_${DateTime.now().millisecondsSinceEpoch}',
      routeId:      'location',
      densityScore: (data['densityScore'] as num).toDouble(),
      confidenceScore: (data['confidenceScore'] as num? ?? 0.5).toDouble(),
      timestamp:    DateTime.now(),
    );
  }

  Future<List<RouteModel>> getRoutes() async {
    try {
      final res = await _client.get(_uri('/routes')).timeout(_timeout);
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list
            .map((e) => RouteModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw ApiException('Hatlar alınamadı', res.statusCode);
    } catch (e) {
      throw ApiException('$e', 0);
    }
  }

  Future<bool> isHealthy() async {
    try {
      final res = await _client
          .get(_uri('/health'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void dispose() => _client.close();
}

class PredictionResult {
  final String routeId;
  final double densityScore;
  final String densityLabel;
  final int busCount;
  final List<BusLocation> buses;
  final List<ForecastPoint> forecast;
  final DateTime timestamp;

  const PredictionResult({
    required this.routeId,
    required this.densityScore,
    required this.densityLabel,
    required this.busCount,
    required this.buses,
    required this.forecast,
    required this.timestamp,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      routeId:      json['routeId'] as String,
      densityScore: (json['densityScore'] as num).toDouble(),
      densityLabel: json['densityLabel'] as String,
      busCount:     json['busCount'] as int,
      buses: (json['buses'] as List<dynamic>)
          .map((b) => BusLocation.fromJson(b as Map<String, dynamic>))
          .toList(),
      forecast: (json['forecast'] as List<dynamic>)
          .map((f) => ForecastPoint.fromJson(f as Map<String, dynamic>))
          .toList(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class BusLocation {
  final String plate;
  final double lat;
  final double lng;
  final double speed;

  const BusLocation({
    required this.plate,
    required this.lat,
    required this.lng,
    required this.speed,
  });

  factory BusLocation.fromJson(Map<String, dynamic> json) => BusLocation(
        plate: json['plate'] as String? ?? '',
        lat:   (json['lat'] as num).toDouble(),
        lng:   (json['lng'] as num).toDouble(),
        speed: (json['speed'] as num).toDouble(),
      );
}

class ForecastPoint {
  final int minutesAhead;
  final double densityScore;
  final String label;

  const ForecastPoint({
    required this.minutesAhead,
    required this.densityScore,
    required this.label,
  });

  factory ForecastPoint.fromJson(Map<String, dynamic> json) => ForecastPoint(
        minutesAhead: json['minutesAhead'] as int,
        densityScore: (json['densityScore'] as num).toDouble(),
        label:        json['label'] as String,
      );
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  const ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
