// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/app_settings_service.dart';
import '../widgets/density_chart_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _fs   = FirestoreService();
  final _auth = FirebaseAuth.instance;
  final _settings = AppSettingsService();

  static const Color _bg      = Color(0xFF080C14);
  static const Color _card    = Color(0xFF0F1826);
  static const Color _accent  = Color(0xFF3B82F6);
  static const Color _border  = Color(0xFF1E3A5F);
  static const Color _textPri = Color(0xFFEFF6FF);
  static const Color _textSec = Color(0xFF64748B);

  AppLanguage _language = AppLanguage.tr;
  int _densityAlertThreshold = 85;

  bool get _isEn => _language == AppLanguage.en;
  String _t(String tr, String en) => _isEn ? en : tr;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final language = await _settings.getLanguage();
    final threshold = await _settings.getDensityAlertThreshold();
    await _ensureUserProfile();
    if (!mounted) return;
    setState(() {
      _language = language;
      _densityAlertThreshold = threshold;
    });
  }

  Future<void> _ensureUserProfile() async {
    final authUser = _auth.currentUser;
    if (authUser == null) return;
    final existing = await _fs.getUser(authUser.uid);
    if (existing != null && existing.name.trim().isNotEmpty) return;
    final email = authUser.email ?? '';
    final fallbackName = authUser.displayName?.trim().isNotEmpty == true
        ? authUser.displayName!.trim()
        : (email.split('@').first.isNotEmpty
            ? email.split('@').first
                .replaceAll('.', ' ')
                .split(' ')
                .where((w) => w.isNotEmpty)
                .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
                .join(' ')
            : _t('Misafir', 'Guest'));
    await _fs.createUser(
      UserModel(
        uid: authUser.uid,
        name: fallbackName,
        email: email,
        favoriteRoutes: existing?.favoriteRoutes ?? const [],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(_t('Profilim', 'My Profile'),
            style: const TextStyle(color: _textPri, fontWeight: FontWeight.w600)),
        backgroundColor: _bg,
        elevation:       0,
        iconTheme:       const IconThemeData(color: _textPri),
        actions: [
          IconButton(
            icon:    const Icon(Icons.logout_rounded, color: _textSec),
            tooltip: _t('Çıkış Yap', 'Sign out'),
            onPressed: _confirmSignOut,
          ),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: _fs.watchUser(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _accent));
          }
          final user = snap.data;
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(user),
                const SizedBox(height: 24),
                _buildStatsRow(user),
                const SizedBox(height: 28),
                _buildFavoriteRoutes(user),
                const SizedBox(height: 28),
                _buildSettingsSection(),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(UserModel? user) {
    final authUser = _auth.currentUser;
    final rawName = (user?.name ?? authUser?.displayName ?? '').trim();
    final email = user?.email ?? authUser?.email ?? _t('Anonim Kullanıcı', 'Anonymous User');
    final computedFromEmail = email
        .split('@')
        .first
        .replaceAll('.', ' ')
        .trim();
    final fallbackName = computedFromEmail.isEmpty
        ? _t('Misafir', 'Guest')
        : computedFromEmail
            .split(' ')
            .where((w) => w.isNotEmpty)
            .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ');
    final name = rawName.isEmpty ? fallbackName : rawName;
    final initials = name.isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : 'M';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        _card,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape:  BoxShape.circle,
              color:  _accent.withOpacity(0.15),
              border: Border.all(
                  color: _accent.withOpacity(0.4), width: 1.5),
            ),
            child: Center(
              child: Text(initials,
                  style: const TextStyle(
                      color:      _accent,
                      fontSize:   22,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color:      _textPri,
                        fontSize:   18,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(email,
                    style: const TextStyle(
                        color: _textSec, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:        _accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _accent.withOpacity(0.3)),
                  ),
                  child: Text(_t('Aktif Kullanıcı', 'Active User'),
                      style: const TextStyle(color: _accent, fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(UserModel? user) {
    return FutureBuilder<int>(
      future: _fs.getUserTotalFeedbacks(),
      builder: (context, snap) {
        final count    = snap.data ?? 0;
        final favCount = user?.favoriteRoutes.length ?? 0;
        return Row(
          children: [
            _statCard(_t('Toplam Bildirim', 'Total Reports'), '$count',
                Icons.thumb_up_alt_outlined),
            const SizedBox(width: 12),
            _statCard(_t('Favorite Hat', 'Favorite Lines'), '$favCount',
                Icons.star_outline_rounded),
            const SizedBox(width: 12),
            _statCard(_t('Puan', 'Score'), '${count * 10}',
                Icons.emoji_events_outlined),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color:        _card,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: _border),
        ),
        child: Column(
          children: [
            Icon(icon, color: _accent, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    color:      _textPri,
                    fontSize:   20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _textSec, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteRoutes(UserModel? user) {
    final favorites = user?.favoriteRoutes ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(_t('Favori Hatlarım', 'My Favorite Lines'),
                style: const TextStyle(
                    color:      _textPri,
                    fontSize:   16,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showAddFavoriteSheet(favorites),
              icon:  const Icon(Icons.add, size: 16, color: _accent),
              label: Text(_t('Ekle', 'Add'),
                  style: const TextStyle(color: _accent, fontSize: 13)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (favorites.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color:        _card,
              borderRadius: BorderRadius.circular(16),
              border:       Border.all(color: _border),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.star_border_rounded,
                      color: _textSec, size: 40),
                  const SizedBox(height: 12),
                  Text(_t('Henüz favori hat eklemediniz', 'No favorite line added yet'),
                      style: TextStyle(color: _textSec, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _showAddFavoriteSheet(favorites),
                    child: Text(_t('Hat Ekle', 'Add Line'),
                        style: const TextStyle(color: _accent)),
                  ),
                ],
              ),
            ),
          )
        else
          ...favorites.map((routeId) => _FavoriteRouteTile(
                routeId:  routeId,
                onRemove: () => _fs.removeFavoriteRoute(routeId),
                onTap:    () => Navigator.pushNamed(context, '/map'),
              )),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('Ayarlar', 'Settings'),
            style: TextStyle(
                color:      _textPri,
                fontSize:   16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _settingsTile(
          icon:     Icons.notifications_outlined,
          title:    _t('Yoğunluk Uyarı Eşiği', 'Density Alert Threshold'),
          subtitle: _isEn
              ? 'Notify when > $_densityAlertThreshold%'
              : '$_densityAlertThreshold% üstünde uyar',
          onTap:    _showThresholdDialog,
        ),
        _settingsTile(
          icon:     Icons.language_outlined,
          title:    _t('Dil', 'Language'),
          subtitle: _isEn ? 'English' : 'Türkçe',
          onTap:    _showLanguageDialog,
        ),
        _settingsTile(
          icon:     Icons.privacy_tip_outlined,
          title:    _t('Gizlilik', 'Privacy'),
          subtitle: _t('Veri kullanım bilgilendirmesi', 'Data usage information'),
          onTap:    _showPrivacyDialog,
        ),
        _settingsTile(
          icon:     Icons.admin_panel_settings_outlined,
          title:    _t('Admin Dashboard (Lite)', 'Admin Dashboard (Lite)'),
          subtitle: _t('Şüpheli veri ve temel metrikler', 'Suspicious data and quick metrics'),
          onTap:    () => Navigator.pushNamed(context, '/admin-lite'),
        ),
        _settingsTile(
          icon:     Icons.info_outline_rounded,
          title:    _t('Hakkında', 'About'),
          subtitle: 'TrafikPuls v1.0.0',
          onTap:    _showAboutDialog,
        ),
      ],
    );
  }

  Future<void> _showPrivacyDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        title: Text(_t('Gizlilik ve Kullanım Bilgilendirmesi', 'Privacy and Usage Notice'),
            style: const TextStyle(color: _textPri)),
        content: SingleChildScrollView(
          child: Text(
            _t(
              'TrafikPuls uygulaması, hizmetin sürekliliğini sağlamak ve kullanıcı deneyimini geliştirmek amacıyla gerekli teknik verileri işler. '
              'Toplanan bilgiler; yoğunluk tahmini, performans takibi, güvenlik doğrulaması ve uygulama kalitesini artırma amaçlarıyla kullanılır. '
              'Bu veriler yetkisiz kişilerle paylaşılmaz ve sistem güvenliği kapsamında korunur. '
              'Uygulamayı kullanmanız, ilgili kullanım koşullarını kabul ettiğiniz anlamına gelir. '
              'Haklarınız saklıdır.',
              'TrafikPuls processes the required technical data to maintain service quality and improve user experience. '
              'Collected information is used for density forecasting, performance monitoring, security checks, and product improvements. '
              'Data is not shared with unauthorized parties and is protected within system security practices. '
              'By using the app, you accept the applicable usage terms. '
              'All rights reserved.',
            ),
            style: const TextStyle(color: _textSec, height: 1.45),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('Kapat', 'Close'),
                style: const TextStyle(color: _accent)),
          ),
        ],
      ),
    );
  }

  Future<void> _showAboutDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        title: Text(_t('Uygulama Hakkında', 'About the App'),
            style: const TextStyle(color: _textPri)),
        content: SingleChildScrollView(
          child: Text(
            _t(
              'TrafikPuls, İstanbul\'daki toplu taşıma kullanıcıları için geliştirilen akıllı bir yoğunluk tahmin uygulamasıdır. '
              'Uygulama; hat arama, durak görüntüleme, ETA (tahmini varış süresi), anlık yoğunluk analizi ve 30-60 dakika ileri tahmin özelliklerini tek ekranda sunar. '
              'Kullanıcı geri bildirimleri (Boş, Ayakta, Dolu) sistem tahminlerine entegre edilerek sonuçların daha güncel ve topluluk odaklı olmasına yardımcı olur. '
              'Amaç, yolculuk planlamasını daha öngörülebilir hale getirmek, yoğun saatlerde alternatif karar vermeyi kolaylaştırmak ve şehir içi mobilite deneyimini iyileştirmektir.',
              'TrafikPuls is a smart public-transport density forecasting app designed for commuters in Istanbul. '
              'It combines line search, stop visualization, ETA, live density analysis, and 30-60 minute forecast in a single flow. '
              'User feedback (Empty, Standing, Full) is blended into predictions to keep results more current and community-driven. '
              'The goal is to make trip planning more predictable, support better decisions during peak hours, and improve the urban mobility experience.',
            ),
            style: const TextStyle(color: _textSec, height: 1.45),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('Kapat', 'Close'),
                style: const TextStyle(color: _accent)),
          ),
        ],
      ),
    );
  }

  Future<void> _showLanguageDialog() async {
    final selected = await showDialog<AppLanguage>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        title: Text(_t('Dil Seçimi', 'Language Selection'),
            style: const TextStyle(color: _textPri)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<AppLanguage>(
              value: AppLanguage.tr,
              groupValue: _language,
              activeColor: _accent,
              title: const Text('Türkçe', style: TextStyle(color: _textPri)),
              onChanged: (v) => Navigator.pop(context, v),
            ),
            RadioListTile<AppLanguage>(
              value: AppLanguage.en,
              groupValue: _language,
              activeColor: _accent,
              title: const Text('English', style: TextStyle(color: _textPri)),
              onChanged: (v) => Navigator.pop(context, v),
            ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    await _settings.setLanguage(selected);
    if (!mounted) return;
    setState(() => _language = selected);
  }

  Future<void> _showThresholdDialog() async {
    double localValue = _densityAlertThreshold.toDouble();
    final selected = await showDialog<int>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          backgroundColor: _card,
          title: Text(_t('Uyarı Eşiği', 'Alert Threshold'),
              style: const TextStyle(color: _textPri)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isEn
                    ? 'Notify when route density exceeds ${localValue.round()}%'
                    : 'Yoğunluk ${localValue.round()}% üstüne çıktığında bildir',
                style: const TextStyle(color: _textSec),
              ),
              const SizedBox(height: 12),
              Slider(
                value: localValue,
                min: 50,
                max: 100,
                divisions: 10,
                label: '${localValue.round()}%',
                activeColor: _accent,
                onChanged: (v) => setLocalState(() => localValue = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_t('İptal', 'Cancel'),
                  style: const TextStyle(color: _textSec)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, localValue.round()),
              child: Text(_t('Kaydet', 'Save')),
            ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    await _settings.setDensityAlertThreshold(selected);
    if (!mounted) return;
    setState(() => _densityAlertThreshold = selected);
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color:        _card,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: _border),
      ),
      child: ListTile(
        onTap:    onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:        _accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _accent, size: 20),
        ),
        title:    Text(title,
            style: const TextStyle(color: _textPri, fontSize: 14)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: _textSec, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: _textSec, size: 20),
      ),
    );
  }

  void _showAddFavoriteSheet(List<String> current) {
    final allRoutes = ['500T', 'M2', 'MARMARAY', '34B', '15', 'E2'];
    showModalBottomSheet(
      context:         context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize:     MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t('Hat Seç', 'Select Line'),
                style: const TextStyle(
                    color:      _textPri,
                    fontSize:   18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Wrap(
              spacing:  10,
              runSpacing: 10,
              children: allRoutes.map((r) {
                final isFav = current.contains(r);
                return GestureDetector(
                  onTap: () async {
                    if (isFav) {
                      await _fs.removeFavoriteRoute(r);
                    } else {
                      await _fs.addFavoriteRoute(r);
                    }
                    if (mounted) Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:  const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color:        isFav ? _accent : _accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24),
                      border:       Border.all(
                          color: isFav ? _accent : _border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isFav) ...[
                          const Icon(Icons.star_rounded,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                        ],
                        Text(r,
                            style: TextStyle(
                                color:      isFav ? Colors.white : _textSec,
                                fontWeight: FontWeight.w600,
                                fontSize:   14)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(_t('Çıkış Yap', 'Sign out'),
            style: TextStyle(
                color: _textPri, fontWeight: FontWeight.w600)),
        content: Text(
            _t('Hesabınızdan çıkmak istediğinize emin misiniz?',
                'Are you sure you want to sign out?'),
            style: const TextStyle(color: _textSec)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_t('İptal', 'Cancel'),
                style: TextStyle(color: _textSec)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(_t('Çıkış Yap', 'Sign out')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _auth.signOut();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }
}

class _FavoriteRouteTile extends StatelessWidget {
  final String routeId;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _FavoriteRouteTile({
    required this.routeId,
    required this.onRemove,
    required this.onTap,
  });

  static const Color _card    = Color(0xFF0F1826);
  static const Color _border  = Color(0xFF1E3A5F);
  static const Color _textPri = Color(0xFFEFF6FF);
  static const Color _textSec = Color(0xFF64748B);
  static const Color _accent  = Color(0xFF3B82F6);

  IconData get _icon {
    if (routeId.startsWith('M') || routeId == 'MARMARAY') {
      return Icons.subway_rounded;
    }
    if (routeId == '34B') return Icons.directions_bus_filled_rounded;
    return Icons.directions_bus_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color:        _card,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: _border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:        onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:        _accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_icon, color: _accent, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(routeId,
                          style: const TextStyle(
                              color:      _textPri,
                              fontSize:   15,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      FutureBuilder<double>(
                        future: FirestoreService()
                            .getFeedbackDensityScore(routeId),
                        builder: (_, snap) {
                          final score = snap.data ?? 0.5;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DensityGradientBar(score: score, height: 5),
                              const SizedBox(height: 4),
                              Text(
                                score < 0.33
                                    ? 'Genellikle boş'
                                    : score < 0.66
                                        ? 'Orta yoğunluk'
                                        : 'Yoğun',
                                style: const TextStyle(
                                    color:    _textSec,
                                    fontSize: 11),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.star_rounded,
                      color: Color(0xFFFBBF24), size: 22),
                  onPressed: onRemove,
                  tooltip:   'Favoriden çıkar',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
