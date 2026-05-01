import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/route_feedback_prediction_models.dart';

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

  bool _adminLoading = false;
  Map<String, dynamic>? _modelMetrics;
  Map<String, dynamic>? _lastRetrainJob;
  Map<String, dynamic>? _lastPushEvent;
  String _adminMessage = '';

  @override
  void initState() {
    super.initState();
    _refreshAdminData();
  }

  Future<void> _refreshAdminData() async {
    setState(() => _adminLoading = true);
    try {
      final res = await http
          .get(Uri.parse('${AppConfig.apiBaseUrl}/admin/model_metrics'))
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
          _adminMessage = 'Admin API bağlı';
        });
      } else {
        if (!mounted) return;
        setState(() => _adminMessage = 'Admin API hatası: ${res.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _adminMessage = 'Admin API erişilemedi: $e');
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
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'reason': 'dashboard-manual-trigger'}),
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        await _refreshAdminData();
        _showSnack('Retrain tamamlandı (prototype)');
      } else {
        _showSnack('Retrain hatası: ${res.statusCode}', isError: true);
      }
    } catch (e) {
      _showSnack('Retrain çağrısı başarısız: $e', isError: true);
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
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'routeId': 'M4',
              'densityScore': 0.89,
              'incidentType': 'density_alert',
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        await _refreshAdminData();
        _showSnack('Push tetiklendi (prototype)');
      } else {
        _showSnack('Push tetikleme hatası: ${res.statusCode}', isError: true);
      }
    } catch (e) {
      _showSnack('Push çağrısı başarısız: $e', isError: true);
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
              child: Text('Hata: ${snapshot.error}',
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
                title: 'Admin API Durumu',
                value: _adminLoading ? 'Yükleniyor...' : 'Bağlı',
                subtitle: _adminMessage.isEmpty ? 'Durum bekleniyor' : _adminMessage,
                valueColor: _adminMessage.startsWith('Admin API hatası') ||
                        _adminMessage.startsWith('Admin API erişilemedi')
                    ? Colors.orange
                    : Colors.green,
              ),
              const SizedBox(height: 10),
              _statsCard(
                title: 'Toplam Son Kayıt',
                value: '${feedbacks.length}',
                subtitle: 'Stream edilen son 120 feedback',
              ),
              const SizedBox(height: 10),
              _statsCard(
                title: 'Son 24 Saat',
                value: '$last24h',
                subtitle: '24 saat içindeki kullanıcı bildirimi',
              ),
              const SizedBox(height: 10),
              _statsCard(
                title: 'Şüpheli Çakışma',
                value: '${suspicious.length}',
                subtitle: 'Aynı hatta 5 dk içinde çelişkili yoğunluk',
                valueColor: suspicious.isEmpty ? Colors.green : Colors.orange,
              ),
              const SizedBox(height: 10),
              _statsCard(
                title: 'Toplam Kullanıcı',
                value: '${_countUniqueUsers(feedbacks)}',
                subtitle: 'Feedback veren benzersiz kullanıcı',
              ),
              const SizedBox(height: 10),
              _statsCard(
                title: 'Popüler Hat',
                value: _mostReportedRoute(feedbacks),
                subtitle: 'En çok bildirim alan hat (stream)',
              ),
              const SizedBox(height: 18),
              const Text(
                'Model Performans İzleme',
                style: TextStyle(
                    color: _textPri, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              _metricsCard(),
              const SizedBox(height: 18),
              const Text(
                'Operasyon Kontrolleri',
                style: TextStyle(
                    color: _textPri, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              _controlCard(
                title: 'Model Retrain',
                subtitle: 'Admin tetiklemeli yeniden eğitim (prototype pipeline)',
                buttonText: 'Retrain Başlat',
                icon: Icons.model_training_outlined,
                onTap: _adminLoading ? null : _triggerRetrain,
              ),
              const SizedBox(height: 10),
              _controlCard(
                title: 'Backend Push Trigger',
                subtitle: 'FCM backend-trigger akış simülasyonu',
                buttonText: 'Push Tetikle',
                icon: Icons.notifications_active_outlined,
                onTap: _adminLoading ? null : _triggerPush,
              ),
              const SizedBox(height: 18),
              const Text(
                'Şüpheli Kayıtlar',
                style: TextStyle(
                    color: _textPri, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              if (suspicious.isEmpty)
                _emptyCard('Şu anda çelişkili veri tespit edilmedi.')
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
          Text('Model Version: $version', style: const TextStyle(color: _textPri)),
          const SizedBox(height: 4),
          Text('Last Trained: $trainedAt',
              style: const TextStyle(color: _textSec, fontSize: 12)),
          const SizedBox(height: 8),
          Text('Last Retrain Job: $retrainJob',
              style: const TextStyle(color: _textSec, fontSize: 12)),
          const SizedBox(height: 4),
          Text('Last Push Event: $pushEvent',
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
                Text('${aggregate.routeId} hattı',
                    style: const TextStyle(
                        color: _textPri, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${aggregate.minuteBucket} dakikasında çelişkili ${aggregate.uniqueStatusCount} farklı bildirim',
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
