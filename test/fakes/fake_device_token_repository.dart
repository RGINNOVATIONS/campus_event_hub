import 'package:campus_event_hub/core/result/result.dart';
import 'package:campus_event_hub/core/services/device_token_repository.dart';

/// In-memory test implementation of DeviceTokenRepository.
///
/// Renamed and relocated from DemoDeviceTokenRepository to test/fakes/fake_device_token_repository.dart.
class FakeDeviceTokenRepository implements DeviceTokenRepository {
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
