import 'package:flutter_test/flutter_test.dart';
import 'package:campus_event_hub/core/services/demo_device_token_repository.dart';
import 'package:campus_event_hub/core/services/demo_notification_service.dart';

// NOTE ON COVERAGE: FirebaseNotificationService's "missing Firebase
// configuration" and "permission denied" branches are guarded by plain
// if-checks on Env / FirebaseMessaging.requestPermission's result (see
// lib/core/services/firebase_notification_service.dart) and are
// verifiable by reading the code, but calling into firebase_core /
// firebase_messaging requires platform channel mocks this sandbox can't
// set up without a real Flutter test runner. DemoNotificationService
// below exercises the same DeviceTokenRepository contract without ever
// touching Firebase, which is what demo mode actually runs.
void main() {
  group('DemoNotificationService — device-token lifecycle', () {
    test('registerDeviceToken is a no-op when no user is signed in', () async {
      final tokenRepo = DemoDeviceTokenRepository();
      final service = DemoNotificationService(
          tokenRepository: tokenRepo, currentUserId: () => null);
      await service.registerDeviceToken();
      final tokens =
          (await tokenRepo.tokensForUser('demo-student-1')).valueOrNull!;
      expect(tokens, isEmpty);
    });

    test('registerDeviceToken registers a token once a user is signed in',
        () async {
      final tokenRepo = DemoDeviceTokenRepository();
      final service = DemoNotificationService(
          tokenRepository: tokenRepo, currentUserId: () => 'demo-student-1');
      await service.registerDeviceToken();
      final tokens =
          (await tokenRepo.tokensForUser('demo-student-1')).valueOrNull!;
      expect(tokens, isNotEmpty);
    });

    test('unregisterDeviceToken removes the previously registered token',
        () async {
      final tokenRepo = DemoDeviceTokenRepository();
      final service = DemoNotificationService(
          tokenRepository: tokenRepo, currentUserId: () => 'demo-student-1');
      await service.registerDeviceToken();
      await service.unregisterDeviceToken();
      final tokens =
          (await tokenRepo.tokensForUser('demo-student-1')).valueOrNull!;
      expect(tokens, isEmpty);
    });
  });
}
