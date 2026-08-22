import 'package:campus_event_hub/core/result/result.dart';
import 'package:campus_event_hub/features/auth/domain/profile.dart';

abstract class AuthRepository {
  Stream<Profile?> watchCurrentProfile();
  Profile? get currentProfile;

  Future<Result<void>> register({
    required String fullName,
    required String collegeEmail,
    required String collegeId,
    required String department,
    required String academicYear,
    required String password,
  });

  Future<Result<void>> login({required String email, required String password});
  Future<Result<void>> logout();
  Future<Result<void>> sendPasswordReset(String email);
  Future<Result<void>> resendVerificationEmail();
  Future<List<String>> allowedEmailDomains();
}
