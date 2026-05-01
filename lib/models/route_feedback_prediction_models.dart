// lib/models/route_feedback_prediction_models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum TransportType { bus, metro, metrobus, tram }
enum DensityStatus { empty, standing, full }

class RouteModel {
  final String routeId;
  final String lineName;
  final TransportType type;

  RouteModel({
    required this.routeId,
    required this.lineName,
    required this.type,
  });

  factory RouteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RouteModel(
      routeId:  doc.id,
      lineName: data['lineName'] ?? '',
      type: TransportType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'bus'),
        orElse: () => TransportType.bus,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'lineName': lineName,
      'type':     type.name,
    };
  }

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      routeId:  json['routeId'] ?? '',
      lineName: json['lineName'] ?? '',
      type: TransportType.values.firstWhere(
        (e) => e.name == (json['type'] ?? 'bus'),
        orElse: () => TransportType.bus,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'routeId':  routeId,
      'lineName': lineName,
      'type':     type.name,
    };
  }
}

class FeedbackModel {
  final String feedbackId;
  final String userId;
  final String routeId;
  final DensityStatus status;
  final DateTime timestamp;

  FeedbackModel({
    required this.feedbackId,
    required this.userId,
    required this.routeId,
    required this.status,
    required this.timestamp,
  });

  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedbackModel(
      feedbackId: doc.id,
      userId:     data['userId'] ?? '',
      routeId:    data['routeId'] ?? '',
      status: DensityStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'empty'),
        orElse: () => DensityStatus.empty,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId':    userId,
      'routeId':   routeId,
      'status':    status.name,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      feedbackId: json['feedbackId'] ?? '',
      userId:     json['userId'] ?? '',
      routeId:    json['routeId'] ?? '',
      status: DensityStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'empty'),
        orElse: () => DensityStatus.empty,
      ),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feedbackId': feedbackId,
      'userId':     userId,
      'routeId':    routeId,
      'status':     status.name,
      'timestamp':  timestamp.toIso8601String(),
    };
  }
}

class PredictionModel {
  final String predId;
  final String routeId;
  final double densityScore;
  final double confidenceScore;
  final DateTime timestamp;

  PredictionModel({
    required this.predId,
    required this.routeId,
    required this.densityScore,
    required this.confidenceScore,
    required this.timestamp,
  });

  String get densityLabel {
    final pct = (densityScore * 100).round();
    if (densityScore < 0.33) return '$pct% Boş';
    if (densityScore < 0.66) return '$pct% Orta Yoğun';
    return '$pct% Dolu';
  }

  String get confidenceLabel {
    final pct = (confidenceScore * 100).round();
    if (confidenceScore < 0.5) return 'Düşük güven ($pct%)';
    if (confidenceScore < 0.75) return 'Orta güven ($pct%)';
    return 'Yüksek güven ($pct%)';
  }

  factory PredictionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PredictionModel(
      predId:       doc.id,
      routeId:      data['routeId'] ?? '',
      densityScore: (data['densityScore'] ?? 0.0).toDouble(),
      confidenceScore: (data['confidenceScore'] ?? 0.5).toDouble(),
      timestamp:    (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'routeId':      routeId,
      'densityScore': densityScore,
      'confidenceScore': confidenceScore,
      'timestamp':    Timestamp.fromDate(timestamp),
    };
  }

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    return PredictionModel(
      predId:       json['predId'] ?? '',
      routeId:      json['routeId'] ?? '',
      densityScore: (json['densityScore'] ?? 0.0).toDouble(),
      confidenceScore: (json['confidenceScore'] ?? 0.5).toDouble(),
      timestamp:    DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'predId':       predId,
      'routeId':      routeId,
      'densityScore': densityScore,
      'confidenceScore': confidenceScore,
      'timestamp':    timestamp.toIso8601String(),
    };
  }
}
