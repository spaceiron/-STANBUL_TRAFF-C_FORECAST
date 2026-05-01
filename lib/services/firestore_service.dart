// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/route_feedback_prediction_models.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference get _users       => _db.collection('users');
  CollectionReference get _routes      => _db.collection('routes');
  CollectionReference get _feedbacks   => _db.collection('feedbacks');
  CollectionReference get _predictions => _db.collection('predictions');

  String? get _uid => _auth.currentUser?.uid;

  // ── USER ─────────────────────────────────────────────────

  Future<void> createUser(UserModel user) async {
    await _users.doc(user.uid).set(user.toFirestore(), SetOptions(merge: true));
  }

  Future<UserModel?> getUser([String? uid]) async {
    final id = uid ?? _uid;
    if (id == null) return null;
    final doc = await _users.doc(id).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> updateUser(Map<String, dynamic> fields) async {
    if (_uid == null) return;
    await _users.doc(_uid).set(fields, SetOptions(merge: true));
  }

  Future<void> addFavoriteRoute(String routeId) async {
    if (_uid == null) return;
    await _users.doc(_uid).set({
      'favoriteRoutes': FieldValue.arrayUnion([routeId]),
    }, SetOptions(merge: true));
  }

  Future<void> removeFavoriteRoute(String routeId) async {
    if (_uid == null) return;
    await _users.doc(_uid).update({
      'favoriteRoutes': FieldValue.arrayRemove([routeId]),
    });
  }

  Stream<UserModel?> watchUser() {
    if (_uid == null) return const Stream.empty();
    return _users.doc(_uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  // ── ROUTES ───────────────────────────────────────────────

  Future<List<RouteModel>> getRoutes() async {
    final snap = await _routes.get();
    return snap.docs.map((d) => RouteModel.fromFirestore(d)).toList();
  }

  Future<RouteModel?> getRoute(String routeId) async {
    final doc = await _routes.doc(routeId).get();
    if (!doc.exists) return null;
    return RouteModel.fromFirestore(doc);
  }

  Stream<List<RouteModel>> searchRoutes(String query) {
    if (query.isEmpty) {
      return _routes.snapshots().map(
            (s) => s.docs.map((d) => RouteModel.fromFirestore(d)).toList(),
          );
    }
    final upper = query.toUpperCase();
    return _routes
        .where('lineName', isGreaterThanOrEqualTo: upper)
        .where('lineName', isLessThanOrEqualTo: '$upper\uf8ff')
        .snapshots()
        .map((s) => s.docs.map((d) => RouteModel.fromFirestore(d)).toList());
  }

  // ── FEEDBACK ─────────────────────────────────────────────

  Future<String> addFeedback({
    required String routeId,
    required DensityStatus status,
  }) async {
    if (_uid == null) throw Exception('Kullanıcı girişi gerekli');
    final feedback = FeedbackModel(
      feedbackId: '',
      userId:     _uid!,
      routeId:    routeId,
      status:     status,
      timestamp:  DateTime.now(),
    );
    final ref = await _feedbacks.add(feedback.toFirestore());
    return ref.id;
  }

  Stream<List<FeedbackModel>> watchFeedbacks(String routeId,
      {int limit = 20}) {
    return _feedbacks
        .where('routeId', isEqualTo: routeId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => FeedbackModel.fromFirestore(d)).toList());
  }

  Future<double> getFeedbackDensityScore(String routeId) async {
    final since = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(hours: 1)),
    );
    final snap = await _feedbacks
        .where('routeId', isEqualTo: routeId)
        .where('timestamp', isGreaterThan: since)
        .get();

    if (snap.docs.isEmpty) return 0.5;

    final feedbacks =
        snap.docs.map((d) => FeedbackModel.fromFirestore(d)).toList();
    double total = 0;
    for (final f in feedbacks) {
      total += switch (f.status) {
        DensityStatus.empty    => 0.1,
        DensityStatus.standing => 0.55,
        DensityStatus.full     => 0.95,
      };
    }
    return (total / feedbacks.length).clamp(0.0, 1.0);
  }

  Future<int> getUserFeedbackCountToday(String routeId) async {
    if (_uid == null) return 0;
    final since = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(hours: 24)),
    );
    final snap = await _feedbacks
        .where('routeId', isEqualTo: routeId)
        .where('userId', isEqualTo: _uid)
        .where('timestamp', isGreaterThan: since)
        .get();
    return snap.docs.length;
  }

  // ── PREDICTIONS ──────────────────────────────────────────

  Future<void> savePrediction(PredictionModel prediction) async {
    await _predictions
        .doc(prediction.predId)
        .set(prediction.toFirestore());
  }

  Future<PredictionModel?> getLatestPrediction(String routeId) async {
    final snap = await _predictions
        .where('routeId', isEqualTo: routeId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return PredictionModel.fromFirestore(snap.docs.first);
  }

  Stream<PredictionModel?> watchLatestPrediction(String routeId) {
    return _predictions
        .where('routeId', isEqualTo: routeId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((s) {
      if (s.docs.isEmpty) return null;
      return PredictionModel.fromFirestore(s.docs.first);
    });
  }

  Future<int> getUserTotalFeedbacks() async {
    if (_uid == null) return 0;
    final snap = await _feedbacks
        .where('userId', isEqualTo: _uid)
        .count()
        .get();
    return snap.count ?? 0;
  }
}
