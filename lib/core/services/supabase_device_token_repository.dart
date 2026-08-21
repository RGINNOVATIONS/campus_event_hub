import 'package:campus_pulse/core/errors/app_failure.dart';
import 'package:campus_pulse/core/result/result.dart';
import 'package:campus_pulse/core/services/device_token_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDeviceTokenRepository implements DeviceTokenRepository {
  final SupabaseClient _client;
  SupabaseDeviceTokenRepository(this._client);

  String _platformString(DevicePlatform p) => p.name;

  @override
  Future<Result<void>> registerToken({
    required String userId,
    required String fcmToken,
    required DevicePlatform platform,
  }) async {
    try {
      // `device_tokens.fcm_token` is UNIQUE — upsert on that column so a
      // re-registration (same device, same token) updates in place
      // instead of violating the constraint or creating a duplicate row.
      await _client.from('device_tokens').upsert({
        'user_id': userId,
        'fcm_token': fcmToken,
        'platform': _platformString(platform),
        'last_seen_at': DateTime.now().toIso8601String(),
      }, onConflict: 'fcm_token');
      return Result.ok(null);
    } catch (e) {
      return Result.err(NotificationFailure(
          'Could not register this device for notifications.', e));
    }
  }

  @override
  Future<Result<void>> refreshToken({
    required String userId,
    required String oldToken,
    required String newToken,
    required DevicePlatform platform,
  }) async {
    try {
      await _client.from('device_tokens').delete().eq('fcm_token', oldToken);
      return registerToken(
          userId: userId, fcmToken: newToken, platform: platform);
    } catch (e) {
      return Result.err(
          NotificationFailure('Could not refresh the notification token.', e));
    }
  }

  @override
  Future<Result<void>> removeToken(String fcmToken) async {
    try {
      await _client.from('device_tokens').delete().eq('fcm_token', fcmToken);
      return Result.ok(null);
    } catch (e) {
      return Result.err(
          NotificationFailure('Could not remove the notification token.', e));
    }
  }

  @override
  Future<Result<Set<String>>> tokensForUser(String userId) async {
    try {
      final rows = await _client
          .from('device_tokens')
          .select('fcm_token')
          .eq('user_id', userId);
      return Result.ok(
          (rows as List).map((r) => r['fcm_token'] as String).toSet());
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }
}
