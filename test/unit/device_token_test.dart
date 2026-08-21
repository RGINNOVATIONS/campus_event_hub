import 'package:flutter_test/flutter_test.dart';
import 'package:campus_pulse/core/services/demo_device_token_repository.dart';
import 'package:campus_pulse/core/services/device_token_repository.dart';

void main() {
  group('DeviceTokenRepository — lifecycle', () {
    test('registerToken makes the token retrievable for that user', () async {
      final repo = DemoDeviceTokenRepository();
      await repo.registerToken(
          userId: 'u1', fcmToken: 'tok-a', platform: DevicePlatform.android);
      final tokens = (await repo.tokensForUser('u1')).valueOrNull!;
      expect(tokens, contains('tok-a'));
    });

    test('refreshToken replaces the old token with the new one', () async {
      final repo = DemoDeviceTokenRepository();
      await repo.registerToken(
          userId: 'u1', fcmToken: 'tok-old', platform: DevicePlatform.android);
      await repo.refreshToken(
        userId: 'u1',
        oldToken: 'tok-old',
        newToken: 'tok-new',
        platform: DevicePlatform.android,
      );
      final tokens = (await repo.tokensForUser('u1')).valueOrNull!;
      expect(tokens, contains('tok-new'));
      expect(tokens, isNot(contains('tok-old')));
    });

    test('removeToken clears it from the user\'s active tokens', () async {
      final repo = DemoDeviceTokenRepository();
      await repo.registerToken(
          userId: 'u1', fcmToken: 'tok-a', platform: DevicePlatform.android);
      await repo.removeToken('tok-a');
      final tokens = (await repo.tokensForUser('u1')).valueOrNull!;
      expect(tokens, isEmpty);
    });

    test(
        're-registering the same token for the same user does not duplicate it',
        () async {
      final repo = DemoDeviceTokenRepository();
      await repo.registerToken(
          userId: 'u1', fcmToken: 'tok-a', platform: DevicePlatform.android);
      await repo.registerToken(
          userId: 'u1', fcmToken: 'tok-a', platform: DevicePlatform.android);
      final tokens = (await repo.tokensForUser('u1')).valueOrNull!;
      expect(tokens.length, 1);
    });

    test(
        'registering the same token under a new user reassigns ownership (no duplicate token rows)',
        () async {
      final repo = DemoDeviceTokenRepository();
      await repo.registerToken(
          userId: 'u1',
          fcmToken: 'shared-tok',
          platform: DevicePlatform.android);
      await repo.registerToken(
          userId: 'u2',
          fcmToken: 'shared-tok',
          platform: DevicePlatform.android);
      final u1Tokens = (await repo.tokensForUser('u1')).valueOrNull!;
      final u2Tokens = (await repo.tokensForUser('u2')).valueOrNull!;
      expect(u1Tokens, isEmpty);
      expect(u2Tokens, contains('shared-tok'));
    });
  });
}
