import 'dart:async';

import 'package:campus_event_hub/core/demo/demo_data_store.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/core/errors/app_failure.dart';
import 'package:campus_event_hub/core/result/result.dart';
import 'package:campus_event_hub/features/auth/domain/auth_repository.dart';
import 'package:campus_event_hub/features/auth/domain/profile.dart';

/// Seeded demo accounts. Passwords are demo-only and documented in the
/// README "Demo-mode usage" section — never used against a real backend.
class DemoAccounts {
  DemoAccounts._();

  static final student = Profile(
    id: 'demo-student-1',
    fullName: 'Aisha Sharma',
    collegeEmail: 'demo.student@college.edu.example',
    collegeId: 'STU2026041',
    department: 'Computer Engineering',
    academicYear: 'Third Year',
    role: UserRole.student,
    emailVerified: true,
    createdAt: DateTime(2026, 1, 10),
  );

  static final organizer = Profile(
    id: 'demo-organizer-1',
    fullName: 'Rahul Verma',
    collegeEmail: 'demo.organizer@college.edu.example',
    collegeId: 'EMP0098',
    department: 'Robotics & Automation Club',
    academicYear: 'N/A',
    role: UserRole.organizer,
    emailVerified: true,
    createdAt: DateTime(2025, 8, 1),
  );

  static final admin = Profile(
    id: 'demo-admin-1',
    fullName: 'Dr. Meera Kulkarni',
    collegeEmail: 'demo.admin@college.edu.example',
    collegeId: 'EMP0001',
    department: 'Student Affairs',
    academicYear: 'N/A',
    role: UserRole.admin,
    emailVerified: true,
    createdAt: DateTime(2024, 6, 1),
  );

  static const demoPassword = 'CampusEventHub#Demo1';
}

class DemoAuthRepository implements AuthRepository {
  final _controller = StreamController<Profile?>.broadcast();
  Profile? _current;

  DemoAuthRepository() {
    final uid = DemoDataStore.instance.currentUserId;
    if (uid != null) {
      _current = [
        DemoAccounts.student,
        DemoAccounts.organizer,
        DemoAccounts.admin
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
    if (normalized == DemoAccounts.student.collegeEmail) {
      match = DemoAccounts.student;
    }
    if (normalized == DemoAccounts.organizer.collegeEmail) {
      match = DemoAccounts.organizer;
    }
    if (normalized == DemoAccounts.admin.collegeEmail) {
      match = DemoAccounts.admin;
    }

    if (match == null || password != DemoAccounts.demoPassword) {
      return Result.err(const AuthFailure('Incorrect email or password.'));
    }
    _current = match;
    DemoDataStore.instance.currentUserId = match.id;
    _controller.add(_current);
    return Result.ok(null);
  }

  @override
  Future<Result<void>> logout() async {
    _current = null;
    DemoDataStore.instance.currentUserId = null;
    _controller.add(null);
    return Result.ok(null);
  }

  @override
  Future<Result<void>> register({
    required String fullName,
    required String collegeEmail,
    required String collegeId,
    required String department,
    required String academicYear,
    required String password,
  }) async {
    // Demo mode simulates instant "registration" as a new unverified student.
    _current = Profile(
      id: 'demo-new-${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName,
      collegeEmail: collegeEmail,
      collegeId: collegeId,
      department: department,
      academicYear: academicYear,
      role: UserRole.student,
      emailVerified: false,
      createdAt: DateTime.now(),
    );
    DemoDataStore.instance.currentUserId = _current!.id;
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
