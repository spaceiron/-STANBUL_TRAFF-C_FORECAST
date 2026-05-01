import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/route_feedback_prediction_models.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const Color _bg = Color(0xFF080C14);
  static const Color _card = Color(0xFF0F1826);
  static const Color _textPri = Color(0xFFEFF6FF);
  static const Color _textSec = Color(0xFF64748B);
  static const Color _accent = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Admin Dashboard (Lite)',
            style: TextStyle(color: _textPri, fontWeight: FontWeight.w600)),
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textPri),
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
