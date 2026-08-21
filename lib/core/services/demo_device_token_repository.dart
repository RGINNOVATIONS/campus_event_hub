import 'package:campus_pulse/core/result/result.dart';
import 'package:campus_pulse/core/services/device_token_repository.dart';

class DemoDeviceTokenRepository implements DeviceTokenRepository {
  // token -> userId. A plain Map naturally enforces "one active token
  // maps to one owner" and duplicate-token prevention (re-registering
  // the same token just overwrites its owner rather than creating a
  // second row) — mirrors the live table's `unique (fcm_token)`.
  final Map<String, String> _tokenOwners = {};

  @override
  Future<Result<void>> registerToken({
    required String userId,
    required String fcmToken,
    required DevicePlatform platform,
  }) async {
    _tokenOwners[fcmToken] = userId;
    return Result.ok(null);
  }

  @override
  Future<Result<void>> refreshToken({
    required String userId,
    required String oldToken,
    required String newToken,
    required DevicePlatform platform,
  }) async {
    _tokenOwners.remove(oldToken);
    _tokenOwners[newToken] = userId;
    return Result.ok(null);
  }

  @override
  Future<Result<void>> removeToken(String fcmToken) async {
    _tokenOwners.remove(fcmToken);
    return Result.ok(null);
  }

  @override
  Future<Result<Set<String>>> tokensForUser(String userId) async =>
      Result.ok(_tokenOwners.entries
          .where((e) => e.value == userId)
          .map((e) => e.key)
          .toSet());
}
