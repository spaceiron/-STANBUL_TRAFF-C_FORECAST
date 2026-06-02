import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../config/admin_config.dart';
import '../models/route_feedback_prediction_models.dart';
import '../services/app_settings_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const Color _bg = Color(0xFF080C14);
  static const Color _card = Color(0xFF0F1826);
  static const Color _textPri = Color(0xFFEFF6FF);
  static const Color _textSec = Color(0xFF64748B);
  static const Color _accent = Color(0xFF3B82F6);

  final _settings = AppSettingsService();
  AppLanguage _language = AppLanguage.tr;
  bool get _isEn => _language == AppLanguage.en;
  String _t(String tr, String en) => _isEn ? en : tr;

  bool _adminLoading = false;
  Map<String, dynamic>? _modelMetrics;
  Map<String, dynamic>? _lastRetrainJob;
  Map<String, dynamic>? _lastPushEvent;
  String _adminMessage = '';

  bool _accessDenied = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    final email = FirebaseAuth.instance.currentUser?.email;
    if (!AdminConfig.isAdminEmail(email)) {
      _accessDenied = true;
      return;
    }
    _refreshAdminData();
  }

  Future<void> _loadLanguage() async {
    final language = await _settings.getLanguage();
    if (!mounted) return;
    setState(() => _language = language);
  }

  bool _isAdminErrorMessage(String msg) =>
      msg.startsWith('Admin API hatası') ||
      msg.startsWith('Admin API error') ||
      msg.startsWith('Admin API erişilemedi') ||
      msg.startsWith('Admin API unreachable');

  Map<String, String> _adminHeaders({bool jsonBody = false}) {
    final headers = <String, String>{};
    if (jsonBody) headers['Content-Type'] = 'application/json';
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email != null && email.isNotEmpty) {
      headers['X-User-Email'] = email;
    }
    return headers;
  }

  Future<void> _refreshAdminData() async {
    setState(() => _adminLoading = true);
    try {
      final res = await http
          .get(
            Uri.parse('${AppConfig.apiBaseUrl}/admin/model_metrics'),
            headers: _adminHeaders(),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          _modelMetrics = Map<String, dynamic>.from(data['metrics'] ?? {});
          _lastRetrainJob = data['lastRetrainJob'] == null
              ? null
              : Map<String, dynamic>.from(data['lastRetrainJob']);
          _lastPushEvent = data['lastPushEvent'] == null
              ? null
              : Map<String, dynamic>.from(data['lastPushEvent']);
          _adminMessage = _t('Admin API bağlı', 'Admin API connected');
        });
      } else {
        if (!mounted) return;
        setState(() => _adminMessage =
            _t('Admin API hatası: ${res.statusCode}', 'Admin API error: ${res.statusCode}'));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _adminMessage =
          _t('Admin API erişilemedi: $e', 'Admin API unreachable: $e'));
    } finally {
      if (mounted) setState(() => _adminLoading = false);
    }
  }

  Future<void> _triggerRetrain() async {
    setState(() => _adminLoading = true);
    try {
      final res = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/admin/retrain'),
            headers: _adminHeaders(jsonBody: true),
            body: jsonEncode({'reason': 'dashboard-manual-trigger'}),
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        await _refreshAdminData();
        _showSnack(_t('Retrain tamamlandı (prototype)', 'Retrain completed (prototype)'));
      } else {
        _showSnack(_t('Retrain hatası: ${res.statusCode}', 'Retrain error: ${res.statusCode}'),
            isError: true);
      }
    } catch (e) {
      _showSnack(_t('Retrain çağrısı başarısız: $e', 'Retrain request failed: $e'),
          isError: true);
    } finally {
      if (mounted) setState(() => _adminLoading = false);
    }
  }

  Future<void> _triggerPush() async {
    setState(() => _adminLoading = true);
    try {
      final res = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/admin/trigger_push'),
            headers: _adminHeaders(jsonBody: true),
            body: jsonEncode({
              'routeId': 'M4',
              'densityScore': 0.89,
              'incidentType': 'density_alert',
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        await _refreshAdminData();
        _showSnack(_t('Push tetiklendi (prototype)', 'Push triggered (prototype)'));
      } else {
        _showSnack(
            _t('Push tetikleme hatası: ${res.statusCode}', 'Push trigger error: ${res.statusCode}'),
            isError: true);
      }
    } catch (e) {
      _showSnack(_t('Push çağrısı başarısız: $e', 'Push request failed: $e'),
          isError: true);
    } finally {
      if (mounted) setState(() => _adminLoading = false);
    }
  }

  void _showSnack(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_accessDenied) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('Admin Dashboard',
              style: TextStyle(color: _textPri, fontWeight: FontWeight.w600)),
          backgroundColor: _bg,
          elevation: 0,
          iconTheme: const IconThemeData(color: _textPri),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _t(
                'Bu alan yalnızca yetkili admin hesabı içindir.',
                'This area is restricted to authorized admin accounts only.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(color: _textSec, fontSize: 15),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Admin Dashboard',
            style: TextStyle(color: _textPri, fontWeight: FontWeight.w600)),
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textPri),
        actions: [
          IconButton(
            onPressed: _adminLoading ? null : _refreshAdminData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('feedbacks')
            .orderBy('timestamp', descending: true)
            .limit(120)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _accent),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                _t('Hata: ${snapshot.error}', 'Error: ${snapshot.error}'),
                  style: const TextStyle(color: Colors.redAccent)),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          final feedbacks = docs.map(FeedbackModel.fromFirestore).toList();
          final suspicious = _detectSuspicious(feedbacks);
          final last24h = feedbacks
              .where((f) => DateTime.now().difference(f.timestamp).inHours < 24)
              .length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _statsCard(
                title: _t('Admin API Durumu', 'Admin API Status'),
                value: _adminLoading
                    ? _t('Yükleniyor...', 'Loading...')
                    : _t('Bağlı', 'Connected'),
                subtitle: _adminMessage.isEmpty
                    ? _t('Durum bekleniyor', 'Waiting for status')
                    : _adminMessage,
                valueColor: _isAdminErrorMessage(_adminMessage)
                    ? Colors.orange
                    : Colors.green,
              ),
              const SizedBox(height: 10),
              _statsCard(
                title: _t('Toplam Son Kayıt', 'Recent Records'),
                value: '${feedbacks.length}',
                subtitle: _t('Stream edilen son 120 feedback', 'Last 120 feedback items in stream'),
              ),
              const SizedBox(height: 10),
              _statsCard(
                title: _t('Son 24 Saat', 'Last 24 Hours'),
                value: '$last24h',
                subtitle: _t('24 saat içindeki kullanıcı bildirimi', 'User reports in the last 24 hours'),
              ),
              const SizedBox(height: 10),
              _statsCard(
                title: _t('Şüpheli Çakışma', 'Suspicious Conflicts'),
                value: '${suspicious.length}',
                subtitle: _t(
                  'Aynı hatta 5 dk içinde çelişkili yoğunluk',
                  'Conflicting density reports on same line within 5 min',
                ),
                valueColor: suspicious.isEmpty ? Colors.green : Colors.orange,
              ),
              const SizedBox(height: 10),
              _statsCard(
                title: _t('Toplam Kullanıcı', 'Total Users'),
                value: '${_countUniqueUsers(feedbacks)}',
                subtitle: _t('Feedback veren benzersiz kullanıcı', 'Unique users who submitted feedback'),
              ),
              const SizedBox(height: 10),
              _statsCard(
                title: _t('Popüler Hat', 'Popular Line'),
                value: _mostReportedRoute(feedbacks),
                subtitle: _t('En çok bildirim alan hat (stream)', 'Most reported line in stream'),
              ),
              const SizedBox(height: 18),
              Text(
                _t('Model Performans İzleme', 'Model Performance Monitoring'),
                style: const TextStyle(
                    color: _textPri, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              _metricsCard(),
              const SizedBox(height: 18),
              Text(
                _t('Operasyon Kontrolleri', 'Operations Controls'),
                style: const TextStyle(
                    color: _textPri, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              _controlCard(
                title: _t('Model Retrain', 'Model Retrain'),
                subtitle: _t(
                  'Admin tetiklemeli yeniden eğitim (prototype pipeline)',
                  'Admin-triggered retraining (prototype pipeline)',
                ),
                buttonText: _t('Retrain Başlat', 'Start Retrain'),
                icon: Icons.model_training_outlined,
                onTap: _adminLoading ? null : _triggerRetrain,
              ),
              const SizedBox(height: 10),
              _controlCard(
                title: _t('Backend Push Trigger', 'Backend Push Trigger'),
                subtitle: _t(
                  'FCM backend-trigger akış simülasyonu',
                  'Simulated FCM backend-trigger flow',
                ),
                buttonText: _t('Push Tetikle', 'Trigger Push'),
                icon: Icons.notifications_active_outlined,
                onTap: _adminLoading ? null : _triggerPush,
              ),
              const SizedBox(height: 18),
              Text(
                _t('Şüpheli Kayıtlar', 'Suspicious Records'),
                style: const TextStyle(
                    color: _textPri, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              if (suspicious.isEmpty)
                _emptyCard(_t(
                  'Şu anda çelişkili veri tespit edilmedi.',
                  'No conflicting data detected right now.',
                ))
              else
                ...suspicious.map((s) => _suspiciousTile(s)),
            ],
          );
        },
      ),
    );
  }

  Widget _metricsCard() {
    final m = _modelMetrics ?? {};
    final mae = (m['mae'] ?? '-').toString();
    final rmse = (m['rmse'] ?? '-').toString();
    final drift = (m['driftScore'] ?? '-').toString();
    final version = (m['trainingVersion'] ?? '-').toString();
    final trainedAt = (m['lastTrainedAt'] ?? '-').toString();
    final retrainJob = (_lastRetrainJob?['jobId'] ?? '-').toString();
    final pushEvent = (_lastPushEvent?['eventId'] ?? '-').toString();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MAE: $mae', style: const TextStyle(color: _textPri)),
          const SizedBox(height: 4),
          Text('RMSE: $rmse', style: const TextStyle(color: _textPri)),
          const SizedBox(height: 4),
          Text('Drift Score: $drift', style: const TextStyle(color: _textPri)),
          const SizedBox(height: 4),
          Text('${_t("Model Sürümü", "Model Version")}: $version',
              style: const TextStyle(color: _textPri)),
          const SizedBox(height: 4),
          Text('${_t("Son Eğitim", "Last Trained")}: $trainedAt',
              style: const TextStyle(color: _textSec, fontSize: 12)),
          const SizedBox(height: 8),
          Text('${_t("Son Retrain İşi", "Last Retrain Job")}: $retrainJob',
              style: const TextStyle(color: _textSec, fontSize: 12)),
          const SizedBox(height: 4),
          Text('${_t("Son Push Olayı", "Last Push Event")}: $pushEvent',
              style: const TextStyle(color: _textSec, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _controlCard({
    required String title,
    required String subtitle,
    required String buttonText,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: _accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: _textPri, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(color: _textSec, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onTap,
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  Widget _statsCard({
    required String title,
    required String value,
    required String subtitle,
    Color valueColor = _accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: _textSec, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: valueColor, fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: _textSec, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text, style: const TextStyle(color: _textSec)),
    );
  }

  Widget _suspiciousTile(_SuspiciousAggregate aggregate) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEn
                      ? '${aggregate.routeId} line'
                      : '${aggregate.routeId} hattı',
                    style: const TextStyle(
                        color: _textPri, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  _isEn
                      ? '${aggregate.uniqueStatusCount} conflicting reports at ${aggregate.minuteBucket}'
                      : '${aggregate.minuteBucket} dakikasında çelişkili ${aggregate.uniqueStatusCount} farklı bildirim',
                  style: const TextStyle(color: _textSec, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _countUniqueUsers(List<FeedbackModel> feedbacks) =>
      feedbacks.map((f) => f.userId).toSet().length;

  String _mostReportedRoute(List<FeedbackModel> feedbacks) {
    if (feedbacks.isEmpty) return '-';
    final counts = <String, int>{};
    for (final f in feedbacks) {
      counts[f.routeId] = (counts[f.routeId] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return '${sorted.first.key} (${sorted.first.value})';
  }

  List<_SuspiciousAggregate> _detectSuspicious(List<FeedbackModel> feedbacks) {
    final byBucket = <String, Set<DensityStatus>>{};

    for (final f in feedbacks) {
      final bucket = DateTime(
        f.timestamp.year,
        f.timestamp.month,
        f.timestamp.day,
        f.timestamp.hour,
        (f.timestamp.minute ~/ 5) * 5,
      );
      final key =
          '${f.routeId}|${bucket.year}-${bucket.month}-${bucket.day} ${bucket.hour}:${bucket.minute.toString().padLeft(2, '0')}';
      byBucket.putIfAbsent(key, () => <DensityStatus>{}).add(f.status);
    }

    final suspicious = <_SuspiciousAggregate>[];
    byBucket.forEach((key, value) {
      if (value.length <= 1) return;
      final parts = key.split('|');
      suspicious.add(_SuspiciousAggregate(
        routeId: parts.first,
        minuteBucket: parts.last,
        uniqueStatusCount: value.length,
      ));
    });
    suspicious.sort((a, b) => b.minuteBucket.compareTo(a.minuteBucket));
    return suspicious.take(20).toList();
  }
}

class _SuspiciousAggregate {
  final String routeId;
  final String minuteBucket;
  final int uniqueStatusCount;

  _SuspiciousAggregate({
    required this.routeId,
    required this.minuteBucket,
    required this.uniqueStatusCount,
  });
}
