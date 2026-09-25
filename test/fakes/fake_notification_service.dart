import 'dart:async';

import 'package:campus_event_hub/core/services/device_token_repository.dart';
import 'package:campus_event_hub/core/services/notification_service.dart';

/// Test implementation of NotificationService.
///
/// Renamed and relocated from DemoNotificationService to test/fakes/fake_notification_service.dart.
class FakeNotificationService implements NotificationService {
  final DeviceTokenRepository _tokenRepository;
  final String? Function() _currentUserId;
  final _tapController = StreamController<String?>.broadcast();
  String? _fakeToken;

  FakeNotificationService({
    required DeviceTokenRepository tokenRepository,
    required String? Function() currentUserId,
  })  : _tokenRepository = tokenRepository,
        _currentUserId = currentUserId;

  @override
  Future<void> registerDeviceToken() async {
    final userId = _currentUserId();
    if (userId == null) return;
    _fakeToken = 'test-device-token-$userId';
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
    // Tests rely on in-memory notification list or assertions rather than real OS notifications.
  }

  @override
  Stream<String?> get onNotificationTapped => _tapController.stream;
}
