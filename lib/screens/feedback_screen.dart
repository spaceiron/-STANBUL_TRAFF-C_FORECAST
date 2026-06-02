// lib/screens/feedback_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/route_feedback_prediction_models.dart';
import '../services/firestore_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/app_settings_service.dart';
import '../config/app_config.dart';
import '../utils/locale_helper.dart';

class FeedbackScreen extends StatefulWidget {
  final String routeId;
  const FeedbackScreen({super.key, required this.routeId});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _fs = FirestoreService();
  final _settings = AppSettingsService();

  static const Color _bg      = Color(0xFF080C14);
  static const Color _card    = Color(0xFF0F1826);
  static const Color _accent  = Color(0xFF3B82F6);
  static const Color _border  = Color(0xFF1E3A5F);
  static const Color _textPri = Color(0xFFEFF6FF);
  static const Color _textSec = Color(0xFF64748B);

  bool _isSending = false;
  DensityStatus? _lastSentStatus;
  AppLanguage _language = AppLanguage.tr;
  bool get _isEn => _language == AppLanguage.en;
  String _t(String tr, String en) => _isEn ? en : tr;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final language = await _settings.getLanguage();
    if (!mounted) return;
    setState(() => _language = language);
  }

  // Tüm işlemlerin yapıldığı ana fonksiyon
  Future<void> _sendFeedback(DensityStatus status) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackbar(_t('Giriş yapmanız gerekiyor.', 'You need to sign in.'), Colors.red);
      return;
    }
    
    setState(() => _isSending = true);
    
    try {
      // 1. Önce senin orijinal kodun: Firebase'e kaydet
      await _fs.addFeedback(routeId: widget.routeId, status: status);

      // 2. Bizim eklediğimiz kod: Python Backend'e gönder
      double scoreToSend = 0.5; 
      if (status == DensityStatus.empty) scoreToSend = 0.1;
      if (status == DensityStatus.standing) scoreToSend = 0.6;
      if (status == DensityStatus.full) scoreToSend = 0.9;

      try {
        await http.post(
          Uri.parse('${AppConfig.apiBaseUrl}/report_density'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'routeId': widget.routeId, 
            'lat': 41.0082, 
            'lng': 28.9784,
            'densityScore': scoreToSend
          }),
        );
        print("Python modeline bildirim basariyla iletildi!");
      } catch (e) {
        print('Python sunucusuna bildirim yollanirken hata: $e');
      }

      // Arayüzü güncelle ve başarılı mesajı ver
      setState(() => _lastSentStatus = status);
      _showSnackbar(_t('Bildiriminiz alındı, teşekkürler!', 'Thanks, your report was saved!'), Colors.green);
      
    } catch (e) {
      _showSnackbar(_t('Hata: $e', 'Error: $e'), Colors.red);
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:         Text(message),
      backgroundColor: color,
      behavior:        SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          '${LocaleHelper.lineName(widget.routeId, _language)} — '
          '${_t("Yoğunluk Bildir", "Report Density")}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        backgroundColor:  _bg,
        foregroundColor:  _textPri,
        elevation:        0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_t('Şu an bu araçta mısınız?\nDoluluk durumunu bildirin:',
                        'Are you in this vehicle now?\nPlease report occupancy:'),
                    style: TextStyle(
                        fontSize: 16, color: _textSec, height: 1.5)),
                const SizedBox(height: 24),
                _FeedbackButton(
                  label:      _t('Boş', 'Empty'),
                  subtitle:   _t('Oturacak yer var, rahat', 'Seats available'),
                  icon:       Icons.airline_seat_recline_normal,
                  color:      Colors.green,
                  isSelected: _lastSentStatus == DensityStatus.empty,
                  isLoading:  _isSending,
                  onTap:      () => _sendFeedback(DensityStatus.empty),
                ),
                const SizedBox(height: 12),
                _FeedbackButton(
                  label:      _t('Ayakta Yolcu Var', 'Standing'),
                  subtitle:   _t('Dolmaya başlıyor, dikkat', 'Getting crowded'),
                  icon:       Icons.people,
                  color:      Colors.orange,
                  isSelected: _lastSentStatus == DensityStatus.standing,
                  isLoading:  _isSending,
                  onTap:      () => _sendFeedback(DensityStatus.standing),
                ),
                const SizedBox(height: 12),
                _FeedbackButton(
                  label:      _t('Dolu', 'Full'),
                  subtitle:   _t('Binmek çok zor, alternatif ara', 'Very crowded'),
                  icon:       Icons.groups,
                  color:      Colors.red,
                  isSelected: _lastSentStatus == DensityStatus.full,
                  isLoading:  _isSending,
                  onTap:      () => _sendFeedback(DensityStatus.full),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Divider(height: 1),
          Expanded(child: _buildLiveFeedStream()),
        ],
      ),
    );
  }

  Widget _buildLiveFeedStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('feedbacks')
          .where('routeId', isEqualTo: widget.routeId)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: _accent));
        }
        if (snapshot.hasError) {
          return Center(child: Text(_t('Hata: ${snapshot.error}', 'Error: ${snapshot.error}')));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 48, color: _textSec),
                const SizedBox(height: 12),
                Text(_t('Henüz bildirim yok.\nİlk bildirimi siz yapın!',
                        'No reports yet.\nBe the first one!'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _textSec)),
              ],
            ),
          );
        }

        final feedbacks =
            docs.map((d) => FeedbackModel.fromFirestore(d)).toList();
        final emptyCnt   = feedbacks.where((f) => f.status == DensityStatus.empty).length;
        final standingCnt = feedbacks.where((f) => f.status == DensityStatus.standing).length;
        final fullCnt    = feedbacks.where((f) => f.status == DensityStatus.full).length;
        final total      = feedbacks.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(_t('Son $total Bildirim', 'Last $total Reports'),
                      style: const TextStyle(
                          fontSize:   14,
                          fontWeight: FontWeight.w600,
                          color:      Color(0xFFEFF6FF))),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:        Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 8, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(_t('Canlı', 'Live'),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.green)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _SummaryBar(
                emptyCnt:    emptyCnt,
                standingCnt: standingCnt,
                fullCnt:     fullCnt,
                total:       total,
                emptyLabel: _t('Boş', 'Empty'),
                standingLabel: _t('Ayakta', 'Standing'),
                fullLabel: _t('Dolu', 'Full')),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding:     const EdgeInsets.symmetric(horizontal: 20),
                itemCount:   feedbacks.length,
                itemBuilder: (context, index) =>
                    _FeedbackTile(feedback: feedbacks[index], isEn: _isEn),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onTap;

  const _FeedbackButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color:        isSelected ? color.withOpacity(0.12) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color : Colors.grey.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [BoxShadow(
                color:      color.withOpacity(0.2),
                blurRadius: 8,
                offset:     const Offset(0, 2))]
            : [BoxShadow(
                color:      Colors.black.withOpacity(0.04),
                blurRadius: 4)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap:        isLoading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:  color.withOpacity(0.15),
                    shape:  BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                              fontSize:   16,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? color : Colors.black87)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 13,
                              color:    Colors.grey[500])),
                    ],
                  ),
                ),
                isSelected
                    ? Icon(Icons.check_circle, color: color)
                    : Icon(Icons.chevron_right,
                        color: Colors.grey[300]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final int emptyCnt;
  final int standingCnt;
  final int fullCnt;
  final int total;
  final String emptyLabel;
  final String standingLabel;
  final String fullLabel;

  const _SummaryBar({
    required this.emptyCnt,
    required this.standingCnt,
    required this.fullCnt,
    required this.total,
    required this.emptyLabel,
    required this.standingLabel,
    required this.fullLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (emptyCnt > 0)
                    Expanded(flex: emptyCnt,
                        child: Container(color: Colors.green)),
                  if (standingCnt > 0)
                    Expanded(flex: standingCnt,
                        child: Container(color: Colors.orange)),
                  if (fullCnt > 0)
                    Expanded(flex: fullCnt,
                        child: Container(color: Colors.red)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _dot(Colors.green,  '$emptyLabel ($emptyCnt)'),
              const SizedBox(width: 12),
              _dot(Colors.orange, '$standingLabel ($standingCnt)'),
              const SizedBox(width: 12),
              _dot(Colors.red,    '$fullLabel ($fullCnt)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 8, height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _FeedbackTile extends StatelessWidget {
  final FeedbackModel feedback;
  final bool isEn;
  const _FeedbackTile({required this.feedback, required this.isEn});

  @override
  Widget build(BuildContext context) {
    final color = feedback.status == DensityStatus.empty
        ? Colors.green
        : feedback.status == DensityStatus.standing
            ? Colors.orange
            : Colors.red;
    final icon = feedback.status == DensityStatus.empty
        ? Icons.airline_seat_recline_normal
        : feedback.status == DensityStatus.standing
            ? Icons.people
            : Icons.groups;
    final label = feedback.status == DensityStatus.empty
        ? (isEn ? 'Empty' : 'Boş')
        : feedback.status == DensityStatus.standing
            ? (isEn ? 'Standing' : 'Ayakta Yolcu')
            : (isEn ? 'Full' : 'Dolu');
    final diff    = DateTime.now().difference(feedback.timestamp);
    final timeAgo = diff.inMinutes < 1
        ? (isEn ? 'Just now' : 'Az önce')
        : diff.inMinutes < 60
            ? (isEn ? '${diff.inMinutes} min ago' : '${diff.inMinutes} dk önce')
            : (isEn ? '${diff.inHours} h ago' : '${diff.inHours} sa önce');

    return Container(
      margin:  const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontSize:   14,
                  color:      color,
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(timeAgo,
              style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        ],
      ),
    );
  }
}