// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../config/admin_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _fs = FirestoreService();

  static const Color _bgDark       = Color(0xFF080C14);
  static const Color _bgCard       = Color(0xFF0F1826);
  static const Color _accent       = Color(0xFF3B82F6);
  static const Color _accentGlow   = Color(0xFF1D4ED8);
  static const Color _textPrimary  = Color(0xFFEFF6FF);
  static const Color _textSecondary = Color(0xFF94A3B8);
  static const Color _inputBg     = Color(0xFF1A2540);
  static const Color _inputBorder = Color(0xFF2D4070);
  static const Color _errorRed    = Color(0xFFEF4444);
  static const Color _successGreen = Color(0xFF10B981);

  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController     = TextEditingController();
  final _formKey            = GlobalKey<FormState>();

  bool _isLogin     = true;
  bool _isLoading   = false;
  bool _obscurePass = true;
  String? _errorMsg;

  late final AnimationController _pulseCtrl;
  late final AnimationController _slideCtrl;
  late final Animation<double>   _slideAnim;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _slideCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic);
    _fadeAnim  = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeIn);
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _pulseCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _isLoading = true; _errorMsg = null; });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email:    email,
          password: password,
        );
      } else {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email:    email,
          password: password,
        );
        await cred.user?.updateDisplayName(_nameController.text.trim());
        if (cred.user != null) {
          try {
            await _fs.createUser(
              UserModel(
                uid: cred.user!.uid,
                name: _nameController.text.trim(),
                email: email,
              ),
            );
          } catch (_) {
            // Firestore rules may block write; auth still succeeded.
          }
        }
      }
      try {
        await _syncUserRole(email);
      } catch (_) {
        // Role sync is optional; do not block login.
      }
      if (mounted) Navigator.pushReplacementNamed(context, '/map');
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMsg = _friendlyError(e.code));
    } catch (e) {
      setState(() => _errorMsg = 'Giriş sonrası hata: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _syncUserRole(String email) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final role = AdminConfig.isAdminEmail(email) ? 'admin' : 'user';
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'email': email,
      'role':  role,
    }, SetOptions(merge: true));
  }

  Future<void> _signInAnonymously() async {
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      await FirebaseAuth.instance.signInAnonymously();
      if (mounted) Navigator.pushReplacementNamed(context, '/map');
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMsg = _friendlyError(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMsg = 'Şifre sıfırlama için e-posta girin.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showToast('Şifre sıfırlama bağlantısı gönderildi.', isError: false);
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMsg = _friendlyError(e.code));
    }
  }

  String _friendlyError(String code) {
    return switch (code) {
      'user-not-found'       => 'Bu e-posta ile kayıtlı hesap bulunamadı.',
      'wrong-password'       => 'Şifre hatalı. Tekrar deneyin.',
      'email-already-in-use' => 'Bu e-posta zaten kullanımda.',
      'weak-password'        => 'Şifre en az 6 karakter olmalı.',
      'invalid-email'        => 'Geçersiz e-posta adresi.',
      'too-many-requests'    => 'Çok fazla deneme. Lütfen bekleyin.',
      _                      => 'Bir hata oluştu. Tekrar deneyin.',
    };
  }

  void _showToast(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:         Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: isError ? _errorRed : _successGreen,
      behavior:        SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin:          const EdgeInsets.all(16),
    ));
  }

  void _toggleMode() {
    setState(() { _isLogin = !_isLogin; _errorMsg = null; });
    _slideCtrl.reset();
    _slideCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _bgDark,
      body: Stack(
        children: [
          _NightCityBackground(pulseCtrl: _pulseCtrl, size: size),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                height: math.max(
                    size.height - MediaQuery.of(context).padding.top, 600),
                child: Column(
                  children: [
                    Expanded(flex: 3, child: _buildHeader()),
                    Expanded(
                      flex: 7,
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.08),
                            end:   Offset.zero,
                          ).animate(_slideAnim),
                          child: _buildFormCard(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width:  80 + _pulseCtrl.value * 14,
                  height: 80 + _pulseCtrl.value * 14,
                  decoration: BoxDecoration(
                    shape:  BoxShape.circle,
                    border: Border.all(
                      color: _accent.withOpacity(0.15 + _pulseCtrl.value * 0.1),
                      width: 1,
                    ),
                  ),
                ),
                Container(
                  width:  64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape:  BoxShape.circle,
                    color:  _accentGlow.withOpacity(0.2),
                    border: Border.all(color: _accent.withOpacity(0.5), width: 1.5),
                  ),
                  child: const Icon(Icons.directions_transit_filled,
                      color: _accent, size: 30),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('TrafikPuls',
              style: TextStyle(
                  fontSize:   28,
                  fontWeight: FontWeight.w700,
                  color:      _textPrimary,
                  letterSpacing: 1.2)),
          const SizedBox(height: 6),
          Text("İstanbul'u Akıllıca Geç",
              style: TextStyle(
                  fontSize: 13, color: _textSecondary, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      margin:  const EdgeInsets.fromLTRB(20, 12, 20, 24),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      decoration: BoxDecoration(
        color:        _bgCard,
        borderRadius: BorderRadius.circular(28),
        border:       Border.all(color: _inputBorder.withOpacity(0.6), width: 1),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.6),
              blurRadius: 40,
              offset:     const Offset(0, 12)),
          BoxShadow(color: _accent.withOpacity(0.06), blurRadius: 60),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTabToggle(),
            const SizedBox(height: 24),
            if (!_isLogin) ...[
              _buildField(
                controller: _nameController,
                hint:       'Ad Soyad',
                icon:       Icons.person_outline_rounded,
                validator:  (v) => (v == null || v.trim().length < 2)
                    ? 'Ad en az 2 karakter'
                    : null,
              ),
              const SizedBox(height: 14),
            ],
            _buildField(
              controller:   _emailController,
              hint:         'E-posta adresi',
              icon:         Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator:    (v) {
                if (v == null || !v.contains('@'))
                  return 'Geçerli bir e-posta girin';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _passwordController,
              hint:       'Şifre',
              icon:       Icons.lock_outline_rounded,
              obscure:    _obscurePass,
              suffix: IconButton(
                icon: Icon(
                    _obscurePass
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size:  20,
                    color: _textSecondary),
                onPressed: () =>
                    setState(() => _obscurePass = !_obscurePass),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'En az 6 karakter' : null,
            ),
            if (_isLogin) ...[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _resetPassword,
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8)),
                  child: const Text('Şifremi Unuttum',
                      style: TextStyle(fontSize: 13, color: _accent)),
                ),
              ),
            ] else
              const SizedBox(height: 16),
            if (_errorMsg != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color:        _errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: _errorRed.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: _errorRed, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_errorMsg!,
                            style: const TextStyle(
                                color: _errorRed, fontSize: 13))),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            _buildPrimaryButton(),
            const SizedBox(height: 16),
            Row(children: [
              const Expanded(child: Divider(color: Color(0xFF2D4070))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('veya',
                    style:
                        TextStyle(color: _textSecondary, fontSize: 13)),
              ),
              const Expanded(child: Divider(color: Color(0xFF2D4070))),
            ]),
            const SizedBox(height: 16),
            _buildGhostButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color:        const Color(0xFF0A1020),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: _inputBorder, width: 1),
      ),
      child: Row(
        children: [
          _tabButton('Giriş Yap', _isLogin,
              () { if (!_isLogin) _toggleMode(); }),
          _tabButton('Kayıt Ol', !_isLogin,
              () { if (_isLogin) _toggleMode(); }),
        ],
      ),
    );
  }

  Widget _tabButton(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding:  const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:        active ? _accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [BoxShadow(
                    color:      _accent.withOpacity(0.35),
                    blurRadius: 12,
                    offset:     const Offset(0, 2))]
                : [],
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize:   14,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : _textSecondary)),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller:   controller,
      keyboardType: keyboardType,
      obscureText:  obscure,
      style: const TextStyle(color: _textPrimary, fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        hintText:  hint,
        hintStyle: TextStyle(
            color: _textSecondary.withOpacity(0.7), fontSize: 14),
        filled:    true,
        fillColor: _inputBg,
        prefixIcon: Icon(icon, color: _textSecondary, size: 20),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:   const BorderSide(color: _inputBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:   const BorderSide(color: _inputBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: _accent, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:   const BorderSide(color: _errorRed)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: _errorRed, width: 1.5)),
        errorStyle: const TextStyle(color: _errorRed, fontSize: 12),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height:   52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
              color:      _accent.withOpacity(0.4),
              blurRadius: 16,
              offset:     const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap:        _isLoading ? null : _submitForm,
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width:  22,
                    height: 22,
                    child:  CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : Text(
                    _isLogin ? 'Giriş Yap' : 'Hesap Oluştur',
                    style: const TextStyle(
                        fontSize:      16,
                        fontWeight:    FontWeight.w700,
                        color:         Colors.white,
                        letterSpacing: 0.5)),
          ),
        ),
      ),
    );
  }

  Widget _buildGhostButton() {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _signInAnonymously,
        style: OutlinedButton.styleFrom(
          side:            const BorderSide(color: _inputBorder, width: 1),
          foregroundColor: _textSecondary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        icon:  const Icon(Icons.person_outline, size: 18),
        label: const Text('Misafir olarak devam et',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _NightCityBackground extends StatelessWidget {
  final AnimationController pulseCtrl;
  final Size size;
  const _NightCityBackground(
      {required this.pulseCtrl, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseCtrl,
      builder:   (_, __) => CustomPaint(
        size:    size,
        painter: _CityPainter(pulse: pulseCtrl.value),
      ),
    );
  }
}

class _CityPainter extends CustomPainter {
  final double pulse;
  _CityPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin:  Alignment.topCenter,
        end:    Alignment.bottomCenter,
        colors: const [
          Color(0xFF050810),
          Color(0xFF080C14),
          Color(0xFF0A1020)
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topCenter,
        radius: 0.8,
        colors: [
          const Color(0xFF1D4ED8).withOpacity(0.12 + pulse * 0.04),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.6));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.6), glowPaint);

    final bp = Paint()..color = const Color(0xFF080E1A);
    for (final b in [
      [0, h * .55, w * .12, h * .45],
      [w * .04, h * .48, w * .08, h * .52],
      [w * .11, h * .52, w * .09, h * .48],
      [w * .19, h * .45, w * .07, h * .55],
      [w * .25, h * .50, w * .06, h * .50],
      [w * .31, h * .40, w * .06, h * .60],
      [w * .40, h * .38, w * .07, h * .62],
      [w * .50, h * .43, w * .08, h * .57],
      [w * .63, h * .42, w * .06, h * .58],
      [w * .76, h * .47, w * .06, h * .53],
      [w * .88, h * .50, w * .07, h * .50],
      [w * .94, h * .55, w * .06, h * .45],
    ]) {
canvas.drawRect(Rect.fromLTWH(b[0].toDouble(), b[1].toDouble(), b[2].toDouble(), b[3].toDouble()), bp);    
}

    final wp = Paint();
    final rng = math.Random(42);
    for (int i = 0; i < 80; i++) {
      final wx = rng.nextDouble() * w;
      final wy = h * 0.38 + rng.nextDouble() * h * 0.35;
      if (rng.nextDouble() > 0.4) {
        wp.color = const Color(0xFFFFF7E0).withOpacity(0.3);
        canvas.drawRect(Rect.fromLTWH(wx, wy, 3, 2), wp);
      }
    }

    final dp = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final rng2 = math.Random(7);
    for (int i = 0; i < 8; i++) {
      final cx = w * (0.1 + rng2.nextDouble() * 0.8);
      final cy = h * (0.72 + rng2.nextDouble() * 0.15);
      dp.color = (rng2.nextBool()
              ? const Color(0xFFEF4444)
              : const Color(0xFFFBBF24))
          .withOpacity(0.3 + pulse * 0.15);
      canvas.drawCircle(Offset(cx, cy), 2 + pulse, dp);
    }
  }

  @override
  bool shouldRepaint(_CityPainter old) => old.pulse != pulse;
}
