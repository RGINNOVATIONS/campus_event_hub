import 'dart:async';

import 'package:campus_event_hub/core/services/device_token_repository.dart';
import 'package:campus_event_hub/core/services/notification_service.dart';

/// Demo mode must run with zero Firebase/network calls. This still
/// exercises the same DeviceTokenRepository interface (registering a
/// synthetic token) so the "device-token lifecycle" is genuinely
/// demonstrable in demo mode, per spec section 13 — just without ever
/// touching Firebase.
class DemoNotificationService implements NotificationService {
  final DeviceTokenRepository _tokenRepository;
  final String? Function() _currentUserId;
  final _tapController = StreamController<String?>.broadcast();
  String? _fakeToken;

  DemoNotificationService({
    required DeviceTokenRepository tokenRepository,
    required String? Function() currentUserId,
  })  : _tokenRepository = tokenRepository,
        _currentUserId = currentUserId;

  @override
  Future<void> registerDeviceToken() async {
    final userId = _currentUserId();
    if (userId == null) return;
    _fakeToken = 'demo-device-token-$userId';
    await _tokenRepository.registerToken(
      userId: userId,
      fcmToken: _fakeToken!,
      platform: DevicePlatform.android,
    );
  }

  @override
  Future<void> unregisterDeviceToken() async {
    if (_fakeToken != null) {
      await _tokenRepository.removeToken(_fakeToken!);
      _fakeToken = null;
    }
  }

  @override
  Future<void> showForegroundNotification(
      {required String title, required String body}) async {
    // Demo mode relies on the in-app notification centre instead of a
    // real OS-level notification.
  }

  @override
  Stream<String?> get onNotificationTapped => _tapController.stream;
}
