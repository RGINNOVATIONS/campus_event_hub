import 'package:campus_event_hub/core/result/result.dart';

enum DevicePlatform { android, ios, web }

abstract class DeviceTokenRepository {
  /// Upserts the current device's FCM token for the signed-in user.
  /// Enforces "no duplicate active tokens" at the repository level (the
  /// live Supabase table also has a `unique (fcm_token)` constraint —
  /// see `docs/NOTIFICATIONS.md`).
  Future<Result<void>> registerToken({
    required String userId,
    required String fcmToken,
    required DevicePlatform platform,
  });

  /// Called from the `onTokenRefresh` stream — replaces the old token
  /// row for this user/device with the new one.
  Future<Result<void>> refreshToken({
    required String userId,
    required String oldToken,
    required String newToken,
    required DevicePlatform platform,
  });

  /// Called on logout — removes this device's token so a signed-out
  /// device stops receiving pushes for the old account.
  Future<Result<void>> removeToken(String fcmToken);

  Future<Result<Set<String>>> tokensForUser(String userId);
}
