import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/core/errors/app_failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthActionState {
  final bool isLoading;
  final String? errorMessage;
  const AuthActionState({this.isLoading = false, this.errorMessage});
}

class AuthController extends StateNotifier<AuthActionState> {
  final Ref _ref;
  AuthController(this._ref) : super(const AuthActionState());

  Future<bool> login(String email, String password) async {
    state = const AuthActionState(isLoading: true);
    final result = await _ref
        .read(authRepositoryProvider)
        .login(email: email, password: password);
    return result.when(
      ok: (_) {
        state = const AuthActionState();
        // Fire-and-forget: device-token registration must never block or
        // fail the login flow itself (e.g. permission denied, missing
        // Firebase config in a misconfigured production build).
        _ref.read(notificationServiceProvider).registerDeviceToken();
        return true;
      },
      err: (f) {
        state = AuthActionState(errorMessage: f.message);
        return false;
      },
    );
  }

  /// The only sanctioned way to sign out — screens should call this
  /// instead of the repository directly, so the device token is always
  /// unregistered first (spec section 5.10).
  Future<void> logout() async {
    await _ref.read(notificationServiceProvider).unregisterDeviceToken();
    await _ref.read(authRepositoryProvider).logout();
  }

  Future<bool> register({
    required String fullName,
    required String collegeEmail,
    required String collegeId,
    required String department,
    required String academicYear,
    required String password,
  }) async {
    state = const AuthActionState(isLoading: true);
    final result = await _ref.read(authRepositoryProvider).register(
          fullName: fullName,
          collegeEmail: collegeEmail,
          collegeId: collegeId,
          department: department,
          academicYear: academicYear,
          password: password,
        );
    return result.when(
      ok: (_) {
        state = const AuthActionState();
        return true;
      },
      err: (f) {
        state = AuthActionState(errorMessage: f.message);
        return false;
      },
    );
  }

  Future<bool> sendPasswordReset(String email) async {
    state = const AuthActionState(isLoading: true);
    final result =
        await _ref.read(authRepositoryProvider).sendPasswordReset(email);
    return result.when(
      ok: (_) {
        state = const AuthActionState();
        return true;
      },
      err: (f) {
        state = AuthActionState(errorMessage: f.message);
        return false;
      },
    );
  }

  void clearError() => state = const AuthActionState();
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthActionState>(
        (ref) => AuthController(ref));

/// AppFailure re-export point for screens that only need the type.
typedef AuthError = AppFailure;
