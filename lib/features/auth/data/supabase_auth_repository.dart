import 'dart:async';

import 'package:campus_event_hub/core/errors/app_failure.dart';
import 'package:campus_event_hub/core/result/result.dart';
import 'package:campus_event_hub/features/auth/domain/auth_repository.dart';
import 'package:campus_event_hub/features/auth/domain/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;
  final _profileController = StreamController<Profile?>.broadcast();
  Profile? _cached;

  SupabaseAuthRepository(this._client) {
    _client.auth.onAuthStateChange.listen((_) => _refreshProfile());
    _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      _cached = null;
      _profileController.add(null);
      return;
    }
    try {
      final rows =
          await _client.from('profiles').select().eq('id', user.id);
      if ((rows as List).isNotEmpty) {
        _cached = Profile.fromMap(rows.first);
      } else {
        _cached = null;
      }
    } catch (_) {
      _cached = null;
    }
    _profileController.add(_cached);
  }

  @override
  Profile? get currentProfile => _cached;

  @override
  Stream<Profile?> watchCurrentProfile() => _profileController.stream;

  @override
  Future<Result<void>> login(
      {required String email, required String password}) async {
    try {
      await _client.auth
          .signInWithPassword(email: email.trim(), password: password);
      await _refreshProfile();
      return Result.ok(null);
    } catch (e) {
      return Result.err(
          mapExceptionToFailure(e, fallbackMessage: 'Could not sign in.'));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      // Best-effort: clear this device's push token before signing out.
      final uid = _client.auth.currentUser?.id;
      if (uid != null) {
        // Token removal is best-effort/non-fatal — handled by NotificationService.
      }
      await _client.auth.signOut();
      return Result.ok(null);
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> register({
    required String fullName,
    required String collegeEmail,
    required String studentId,
    required String rollNo,
    required String programme,
    required String branch,
    required String academicYear,
    required String password,
  }) async {
    try {
      await _client.auth.signUp(
        email: collegeEmail.trim(),
        password: password,
        data: {
          'full_name': fullName,
          'student_id': studentId,
          'college_id': studentId,
          'roll_no': rollNo,
          'programme': programme,
          'branch': branch,
          'department': branch,
          'academic_year': academicYear,
        },
        // The handle_new_user() trigger creates the profiles row and
        // Supabase Auth handles sending the verification email.
      );
      return Result.ok(null);
    } catch (e) {
      return Result.err(
          mapExceptionToFailure(e, fallbackMessage: 'Could not register.'));
    }
  }

  @override
  Future<Result<void>> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
      return Result.ok(null);
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> resendVerificationEmail() async {
    try {
      final email = _client.auth.currentUser?.email;
      if (email == null) {
        return Result.err(const AuthFailure('No signed-in user.'));
      }
      await _client.auth.resend(type: OtpType.signup, email: email);
      return Result.ok(null);
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<List<String>> allowedEmailDomains() async {
    final rows = await _client
        .from('allowed_email_domains')
        .select('domain')
        .eq('is_active', true);
    return (rows as List).map((r) => r['domain'] as String).toList();
  }
}
