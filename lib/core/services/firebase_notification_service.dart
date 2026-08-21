import 'dart:async';

import 'package:campus_pulse/app/env.dart';
import 'package:campus_pulse/core/services/device_token_repository.dart';
import 'package:campus_pulse/core/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Real implementation, wired against `firebase_messaging` +
/// `flutter_local_notifications` per their documented APIs. This has
/// **not** been run against a live Firebase project or a device/emulator
/// in the sandbox that built this file (no SDK — see TASKS.md section 0).
/// Treat as unverified until exercised on a real device.
class FirebaseNotificationService implements NotificationService {
  final DeviceTokenRepository _tokenRepository;
  final String? Function() _currentUserId;
  final _tapController = StreamController<String?>.broadcast();
  final _localPlugin = FlutterLocalNotificationsPlugin();

  String? _lastRegisteredToken;
  bool _initialized = false;

  FirebaseNotificationService({
    required DeviceTokenRepository tokenRepository,
    required String? Function() currentUserId,
  })  : _tokenRepository = tokenRepository,
        _currentUserId = currentUserId;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    // Never initialize Firebase without real client config — demo mode
    // (and any environment missing Firebase config) must not crash.
    if (Env.isDemoMode ||
        Env.firebaseApiKey.isEmpty ||
        Env.firebaseProjectId.isEmpty) {
      return;
    }
    try {
      await Firebase.initializeApp();
      await _localPlugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
      FirebaseMessaging.instance.onTokenRefresh.listen(_handleTokenRefresh);
      _initialized = true;
    } catch (e) {
      // Firebase misconfiguration must degrade to "no push", not crash
      // the app — in-app notifications keep working regardless.
      debugPrint('FirebaseNotificationService init failed (non-fatal): $e');
    }
  }

  @override
  Future<void> registerDeviceToken() async {
    await _ensureInitialized();
    if (!_initialized) return;
    final userId = _currentUserId();
    if (userId == null) return;

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    // Handles granted / denied / provisional — provisional (iOS) still
    // lets us fetch a token; denied means we simply don't register one,
    // and the app must keep working with in-app notifications only.
    final permitted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
    if (!permitted) return;

    final token = kIsWeb
        ? await FirebaseMessaging.instance
            .getToken(vapidKey: Env.firebaseWebVapidKey)
        : await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    _lastRegisteredToken = token;
    await _tokenRepository.registerToken(
      userId: userId,
      fcmToken: token,
      platform: kIsWeb
          ? DevicePlatform.web
          : (defaultTargetPlatform == TargetPlatform.iOS
              ? DevicePlatform.ios
              : DevicePlatform.android),
    );
  }

  @override
  Future<void> unregisterDeviceToken() async {
    if (_lastRegisteredToken != null) {
      await _tokenRepository.removeToken(_lastRegisteredToken!);
      _lastRegisteredToken = null;
    }
  }

  Future<void> _handleTokenRefresh(String newToken) async {
    final userId = _currentUserId();
    if (userId == null) return;
    final old = _lastRegisteredToken;
    _lastRegisteredToken = newToken;
    if (old != null) {
      await _tokenRepository.refreshToken(
        userId: userId,
        oldToken: old,
        newToken: newToken,
        platform: kIsWeb ? DevicePlatform.web : DevicePlatform.android,
      );
    } else {
      await _tokenRepository.registerToken(
        userId: userId,
        fcmToken: newToken,
        platform: kIsWeb ? DevicePlatform.web : DevicePlatform.android,
      );
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    showForegroundNotification(
      title: message.notification?.title ?? 'CampusPulse',
      body: message.notification?.body ?? '',
    );
  }

  void _handleTap(RemoteMessage message) {
    _tapController.add(message.data['event_id'] as String?);
  }

  @override
  Future<void> showForegroundNotification(
      {required String title, required String body}) async {
    if (!_initialized) return;
    await _localPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android:
            AndroidNotificationDetails('campuspulse_default', 'CampusPulse'),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  @override
  Stream<String?> get onNotificationTapped => _tapController.stream;
}
