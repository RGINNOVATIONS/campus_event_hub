import 'dart:async';

import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/core/errors/app_failure.dart';
import 'package:campus_event_hub/core/result/result.dart';
import 'package:campus_event_hub/features/auth/domain/auth_repository.dart';
import 'package:campus_event_hub/features/auth/domain/profile.dart';

import 'fake_data_store.dart';
import 'test_accounts.dart';

export 'test_accounts.dart';

/// In-memory test implementation of AuthRepository.
///
/// Renamed and relocated from DemoAuthRepository to test/fakes/fake_auth_repository.dart.
class FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<Profile?>.broadcast();
  Profile? _current;

  FakeAuthRepository() {
    final uid = FakeDataStore.instance.currentUserId;
    if (uid != null) {
      _current = [
        TestAccounts.student,
        TestAccounts.organizer,
        TestAccounts.admin
      ].where((p) => p.id == uid).firstOrNull;
    }
  }

  @override
  Profile? get currentProfile => _current;

  @override
  Stream<Profile?> watchCurrentProfile() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<Result<void>> login(
      {required String email, required String password}) async {
    final normalized = email.trim().toLowerCase();
    Profile? match;
    if (normalized == TestAccounts.student.collegeEmail) {
      match = TestAccounts.student;
    }
    if (normalized == TestAccounts.organizer.collegeEmail) {
      match = TestAccounts.organizer;
    }
    if (normalized == TestAccounts.admin.collegeEmail) {
      match = TestAccounts.admin;
    }

    if (match == null || password != TestAccounts.testPassword) {
      return Result.err(const AuthFailure('Incorrect email or password.'));
    }
    _current = match;
    FakeDataStore.instance.currentUserId = match.id;
    _controller.add(_current);
    return Result.ok(null);
  }

  @override
  Future<Result<void>> logout() async {
    _current = null;
    FakeDataStore.instance.currentUserId = null;
    _controller.add(null);
    return Result.ok(null);
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
    _current = Profile(
      id: 'test-new-${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName,
      collegeEmail: collegeEmail,
      studentId: studentId,
      rollNo: rollNo,
      programme: programme,
      branch: branch,
      department: branch,
      academicYear: academicYear,
      role: UserRole.student,
      emailVerified: false,
      createdAt: DateTime.now(),
    );
    FakeDataStore.instance.currentUserId = _current!.id;
    _controller.add(_current);
    return Result.ok(null);
  }

  @override
  Future<Result<void>> sendPasswordReset(String email) async => Result.ok(null);

  @override
  Future<Result<void>> resendVerificationEmail() async => Result.ok(null);

  @override
  Future<List<String>> allowedEmailDomains() async => ['college.edu.example'];
}
