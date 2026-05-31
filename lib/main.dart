// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/map_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'services/notification_service.dart';
import 'config/admin_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const TrafikPulsApp());
}

class TrafikPulsApp extends StatelessWidget {
  const TrafikPulsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrafikPuls',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor:  const Color(0xFF3B82F6),
          brightness: Brightness.dark,
        ),
        useMaterial3:            true,
        scaffoldBackgroundColor: const Color(0xFF080C14),
      ),
      home: const _AppGate(),
      routes: {
        '/login':      (_) => const LoginScreen(),
        '/map':        (_) => const MapScreen(),
        '/profile':    (_) => const ProfileScreen(),
        '/admin-lite': (_) {
          if (!AdminConfig.isAdminEmail(FirebaseAuth.instance.currentUser?.email)) {
            return const _AdminAccessDeniedScreen();
          }
          return const AdminDashboardScreen();
        },
        '/onboarding': (_) => const OnboardingScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/feedback') {
          final routeId = settings.arguments as String? ?? '';
          return MaterialPageRoute(
            builder: (_) => FeedbackScreen(routeId: routeId),
          );
        }
        return null;
      },
    );
  }
}

class _AppGate extends StatelessWidget {
  const _AppGate();

  Future<bool> _isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_done') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }

        final user = authSnap.data;
        if (user == null) return const LoginScreen();

        return FutureBuilder<bool>(
          future: _isOnboardingDone(),
          builder: (context, onbSnap) {
            if (!onbSnap.hasData) return const _SplashScreen();
            if (onbSnap.data == false) {
              NotificationService().initialize();
              return const OnboardingScreen();
            }
            return const MapScreen();
          },
        );
      },
    );
  }
}

class _AdminAccessDeniedScreen extends StatelessWidget {
  const _AdminAccessDeniedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        title: const Text('Admin'),
        backgroundColor: const Color(0xFF080C14),
        foregroundColor: const Color(0xFFEFF6FF),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, color: Color(0xFF64748B), size: 48),
              const SizedBox(height: 16),
              const Text(
                'You do not have admin access.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFEFF6FF), fontSize: 16),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF080C14),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_transit_filled,
                color: Color(0xFF3B82F6), size: 48),
            SizedBox(height: 20),
            CircularProgressIndicator(
                color: Color(0xFF3B82F6), strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}