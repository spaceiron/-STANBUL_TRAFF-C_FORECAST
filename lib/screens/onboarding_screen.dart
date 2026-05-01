// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {

  static const Color _bg      = Color(0xFF080C14);
  static const Color _card    = Color(0xFF0F1826);
  static const Color _accent  = Color(0xFF3B82F6);
  static const Color _border  = Color(0xFF1E3A5F);
  static const Color _textPri = Color(0xFFEFF6FF);
  static const Color _textSec = Color(0xFF64748B);

  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  final Set<String> _selectedRoutes = {};
  bool _notifEnabled = false;
  bool _isFinishing = false;

  final _fs = FirestoreService();
  final _ns = NotificationService();

  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  static const _routes = [
    _RouteOption('500T',     'Bağcılar–Bostancı',   Icons.directions_bus_rounded),
    _RouteOption('M2',       'Yenikapı–Hacıosman',  Icons.subway_rounded),
    _RouteOption('MARMARAY', 'Gebze–Halkalı',        Icons.train_rounded),
    _RouteOption('34B',      'Avcılar–Kadıköy',      Icons.directions_bus_filled_rounded),
    _RouteOption('15',       'Üsküdar–Bostancı',     Icons.directions_bus_rounded),
    _RouteOption('E2',       'Bostancı–Kadıköy',     Icons.directions_bus_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve:    Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);
    try {
      for (final r in _selectedRoutes) {
        await _fs.addFavoriteRoute(r);
        if (_notifEnabled) await _ns.subscribeToRoute(r);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_done', true);
      if (mounted) Navigator.pushReplacementNamed(context, '/map');
    } catch (e) {
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboarding_done', true);
        Navigator.pushReplacementNamed(context, '/map');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kurulum tamamlandı (bazı ayarlar kaydedilemedi: $e)')),
        );
      }
    } finally {
      if (mounted) setState(() => _isFinishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: List.generate(3, (i) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                    height: 3,
                    decoration: BoxDecoration(
                      color:        i <= _currentPage ? _accent : _border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics:    const NeverScrollableScrollPhysics(),
                onPageChanged: (p) {
                  setState(() => _currentPage = p);
                  _fadeCtrl.reset();
                  _fadeCtrl.forward();
                },
                children: [
                  _WelcomePage(fadeAnim: _fadeAnim),
                  _RouteSelectionPage(
                    fadeAnim:       _fadeAnim,
                    routes:         _routes,
                    selectedRoutes: _selectedRoutes,
                    onToggle: (id) => setState(() {
                      _selectedRoutes.contains(id)
                          ? _selectedRoutes.remove(id)
                          : _selectedRoutes.add(id);
                    }),
                  ),
                  _NotificationPage(
                    fadeAnim:  _fadeAnim,
                    enabled:   _notifEnabled,
                    onChanged: (v) => setState(() => _notifEnabled = v),
                    onRequest: () async {
                      await _ns.initialize();
                      setState(() => _notifEnabled = true);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  SizedBox(
                    width:  double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isFinishing ? null : _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isFinishing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _currentPage == 2 ? 'Başla' : 'Devam',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                    ),
                  ),
                  if (_currentPage < 2) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _finish,
                      child: const Text('Atla',
                          style: TextStyle(color: _textSec, fontSize: 14)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteOption {
  final String id;
  final String name;
  final IconData icon;
  const _RouteOption(this.id, this.name, this.icon);
}

class _WelcomePage extends StatelessWidget {
  final Animation<double> fadeAnim;
  const _WelcomePage({required this.fadeAnim});

  static const _textPri = Color(0xFFEFF6FF);
  static const _textSec = Color(0xFF64748B);
  static const _accent  = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width:  100, height: 100,
              decoration: BoxDecoration(
                shape:  BoxShape.circle,
                color:  _accent.withOpacity(0.12),
                border: Border.all(
                    color: _accent.withOpacity(0.35), width: 1.5),
              ),
              child: const Icon(Icons.directions_transit_filled,
                  color: _accent, size: 44),
            ),
            const SizedBox(height: 36),
            const Text("İstanbul'u Akıllıca Geç",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color:      _textPri,
                    fontSize:   28,
                    fontWeight: FontWeight.w700,
                    height:     1.2)),
            const SizedBox(height: 16),
            Text(
              'Gerçek zamanlı trafik tahmini ve toplu taşıma yoğunluk bilgisi ile yolculuğunuzu planlayın.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textSec, fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 48),
            ...[
              (Icons.access_time_rounded,  'Anlık Tahmin',  '30-60 dk önceden yoğunluk görün'),
              (Icons.people_alt_outlined,   'Crowdsourcing', 'Gerçek yolcu bildirimleri'),
              (Icons.map_outlined,          'Canlı Harita',  'İstanbul geneli trafik akışı'),
            ].map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:        _accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(e.$1, color: _accent, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.$2,
                                style: const TextStyle(
                                    color:      _textPri,
                                    fontSize:   14,
                                    fontWeight: FontWeight.w600)),
                            Text(e.$3,
                                style: TextStyle(
                                    color: _textSec, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _RouteSelectionPage extends StatelessWidget {
  final Animation<double> fadeAnim;
  final List<_RouteOption> routes;
  final Set<String> selectedRoutes;
  final void Function(String) onToggle;

  const _RouteSelectionPage({
    required this.fadeAnim,
    required this.routes,
    required this.selectedRoutes,
    required this.onToggle,
  });

  static const _textPri = Color(0xFFEFF6FF);
  static const _textSec = Color(0xFF64748B);
  static const _accent  = Color(0xFF3B82F6);
  static const _card    = Color(0xFF0F1826);
  static const _border  = Color(0xFF1E3A5F);

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hangi Hatları\nKullanıyorsunuz?',
                style: TextStyle(
                    color:      _textPri,
                    fontSize:   26,
                    fontWeight: FontWeight.w700,
                    height:     1.2)),
            const SizedBox(height: 8),
            Text('Favori hatlarınızı seçin, size özel tahminler gösterelim.',
                style: TextStyle(color: _textSec, fontSize: 14)),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount:      routes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final r        = routes[i];
                  final selected = selectedRoutes.contains(r.id);
                  return GestureDetector(
                    onTap: () => onToggle(r.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding:  const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: selected
                            ? _accent.withOpacity(0.12)
                            : _card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected ? _accent : _border,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? _accent.withOpacity(0.2)
                                  : _accent.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(r.icon,
                                color:  selected ? _accent : _textSec,
                                size:   20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.id,
                                    style: TextStyle(
                                        color:      selected ? _accent : _textPri,
                                        fontSize:   15,
                                        fontWeight: FontWeight.w600)),
                                Text(r.name,
                                    style: const TextStyle(
                                        color: _textSec, fontSize: 12)),
                              ],
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selected ? _accent : Colors.transparent,
                              border: Border.all(
                                color: selected ? _accent : _border,
                                width: 1.5,
                              ),
                            ),
                            child: selected
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 14)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationPage extends StatelessWidget {
  final Animation<double> fadeAnim;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final VoidCallback onRequest;

  const _NotificationPage({
    required this.fadeAnim,
    required this.enabled,
    required this.onChanged,
    required this.onRequest,
  });

  static const _textPri = Color(0xFFEFF6FF);
  static const _textSec = Color(0xFF64748B);
  static const _accent  = Color(0xFF3B82F6);
  static const _card    = Color(0xFF0F1826);
  static const _border  = Color(0xFF1E3A5F);

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape:  BoxShape.circle,
                color:  const Color(0xFFF59E0B).withOpacity(0.12),
                border: Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(0.35),
                    width: 1.5),
              ),
              child: const Icon(Icons.notifications_active_outlined,
                  color: Color(0xFFF59E0B), size: 44),
            ),
            const SizedBox(height: 36),
            const Text('Yoğunluk Uyarıları',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color:      _textPri,
                    fontSize:   26,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Text(
              'Favori hatlarınızda ani yoğunluk artışı olduğunda sizi bildirimle uyaralım.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textSec, fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:        _card,
                borderRadius: BorderRadius.circular(20),
                border:       Border.all(color: _border),
              ),
              child: Column(
                children: [
                  _notifItem(Icons.warning_amber_rounded,
                      'Yoğunluk Uyarısı', 'Hat %70+ dolduğunda bildir',
                      const Color(0xFFEF4444)),
                  const Divider(color: Color(0xFF1E3A5F), height: 24),
                  _notifItem(Icons.wb_sunny_outlined,
                      'Sabah Hatırlatması', 'İşe gidiş için trafik özeti',
                      const Color(0xFFF59E0B)),
                  const Divider(color: Color(0xFF1E3A5F), height: 24),
                  _notifItem(Icons.nights_stay_outlined,
                      'Akşam Hatırlatması', 'Eve dönüş yoğunluk tahmini',
                      _accent),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (!enabled)
              SizedBox(
                width: double.infinity, height: 52,
                child: OutlinedButton.icon(
                  onPressed: onRequest,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: Color(0xFFF59E0B), width: 1.5),
                    foregroundColor: const Color(0xFFF59E0B),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon:  const Icon(Icons.notifications_outlined),
                  label: const Text('Bildirimlere İzin Ver',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color:        const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: Color(0xFF10B981), size: 20),
                    SizedBox(width: 10),
                    Text('Bildirimler etkinleştirildi',
                        style: TextStyle(
                            color:      Color(0xFF10B981),
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _notifItem(IconData icon, String title, String sub, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:        color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color:      _textPri,
                    fontSize:   13,
                    fontWeight: FontWeight.w600)),
            Text(sub,
                style: const TextStyle(color: _textSec, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}
