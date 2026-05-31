// lib/services/notification_service.dart
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_settings_service.dart';
import '../utils/locale_helper.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService().showLocalNotification(
    title:   message.notification?.title ?? 'TrafikPuls',
    body:    message.notification?.body  ?? '',
    payload: message.data['routeId'],
  );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _fcm      = FirebaseMessaging.instance;
  final _local    = FlutterLocalNotificationsPlugin();
  final _settings = AppSettingsService();

  static const _channelId = 'traffic_density_channel';

  Future<void> initialize() async {
    final settings = await _fcm.requestPermission(
      alert:       true,
      badge:       true,
      sound:       true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit     = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _local.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      final language = await _settings.getLanguage();
      final channelName = LocaleHelper.notificationChannelName(language);
      final channelDescription =
          LocaleHelper.notificationChannelDescription(language);

      final androidPlugin = _local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        AndroidNotificationChannel(
          _channelId,
          channelName,
          description: channelDescription,
          importance:  Importance.high,
        ),
      );

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

      await _saveTokenToFirestore();
      _fcm.onTokenRefresh.listen(_onTokenRefresh);
    }
  }

  Future<void> _saveTokenToFirestore() async {
    final uid   = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final token = await _fcm.getToken();
    if (token == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'fcmToken':     token,
      'fcmUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _onTokenRefresh(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'fcmToken':     token,
      'fcmUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    final language = await _settings.getLanguage();
    final channelName = LocaleHelper.notificationChannelName(language);
    final channelDescription =
        LocaleHelper.notificationChannelDescription(language);

    await _local.show(
      id, title, body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority:   Priority.high,
          icon:       '@mipmap/ic_launcher',
          color:      const Color(0xFF3B82F6),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  Future<void> sendDensityAlert({
    required String routeId,
    required double densityScore,
  }) async {
    final language = await _settings.getLanguage();
    final pct   = (densityScore * 100).round();
    final emoji = densityScore > 0.66 ? '🔴' : '🟡';
    await showLocalNotification(
      id:      routeId.hashCode,
      title:   '$emoji ${LocaleHelper.densityAlertTitle(routeId, language)}',
      body:    LocaleHelper.densityAlertBody(pct, language),
      payload: routeId,
    );
  }

  Future<void> sendIncidentAlert({
    required String routeId,
    required String title,
    required int delayMin,
    String? incidentType,
  }) async {
    final language = await _settings.getLanguage();
    final delay = LocaleHelper.delayText(delayMin, language);
    final icon = (incidentType ?? '').toLowerCase() == 'accident' ? '🚧' : '⚠️';
    await showLocalNotification(
      id: '$routeId$title$delayMin'.hashCode,
      title: '$icon ${LocaleHelper.incidentAlertTitle(routeId, language)}',
      body: '$title ($delay)',
      payload: routeId,
    );
  }

  Future<void> subscribeToRoute(String routeId) async {
    await _fcm.subscribeToTopic('route_$routeId');
  }

  Future<void> unsubscribeFromRoute(String routeId) async {
    await _fcm.unsubscribeFromTopic('route_$routeId');
  }

  Future<void> subscribeToFavoriteRoutes(List<String> routeIds) async {
    for (final id in routeIds) await subscribeToRoute(id);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notif = message.notification;
    if (notif != null) {
      showLocalNotification(
        title:   notif.title ?? 'TrafikPuls',
        body:    notif.body  ?? '',
        payload: message.data['routeId'],
      );
    }
  }

  void _handleNotificationOpen(RemoteMessage message) {}

  void _onNotificationTap(NotificationResponse response) {}

  Future<void> saveNotificationPrefs({
    required bool densityAlerts,
    required bool morningReminder,
    required bool eveningReminder,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'notifPrefs': {
        'densityAlerts':   densityAlerts,
        'morningReminder': morningReminder,
        'eveningReminder': eveningReminder,
        'updatedAt':       FieldValue.serverTimestamp(),
      },
    });
  }
}