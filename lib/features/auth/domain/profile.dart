import 'package:campus_pulse/core/domain/enums.dart';

class Profile {
  final String id;
  final String fullName;
  final String collegeEmail;
  final String collegeId;
  final String department;
  final String academicYear;
  final UserRole role;
  final bool emailVerified;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.fullName,
    required this.collegeEmail,
    required this.collegeId,
    required this.department,
    required this.academicYear,
    required this.role,
    required this.emailVerified,
    required this.createdAt,
  });

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
        id: map['id'] as String,
        fullName: map['full_name'] as String,
        collegeEmail: map['college_email'] as String,
        collegeId: map['college_id'] as String,
        department: map['department'] as String,
        academicYear: map['academic_year'] as String,
        role: UserRoleX.fromDb(map['role'] as String),
        emailVerified: map['email_verified'] as bool? ?? false,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

/// Pure validation used by both the register screen and unit tests.
/// The authoritative check still happens server-side against
/// `allowed_email_domains` — this is a fast client-side pre-check only.
class CollegeEmailValidator {
  CollegeEmailValidator._();

  static final _emailFormat = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static bool isWellFormed(String email) => _emailFormat.hasMatch(email.trim());

  /// [allowedDomains] is fetched from the `allowed_email_domains` table at
  /// runtime — never hard-coded to a single guessed institution domain.
  static bool isAllowedDomain(String email, List<String> allowedDomains) {
    if (!isWellFormed(email)) return false;
    final domain = email.trim().toLowerCase().split('@').last;
    return allowedDomains.map((d) => d.toLowerCase()).contains(domain);
  }

  static String? validate(String email, List<String> allowedDomains) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return 'College email is required.';
    if (!isWellFormed(trimmed)) return 'Enter a valid email address.';
    if (allowedDomains.isNotEmpty &&
        !isAllowedDomain(trimmed, allowedDomains)) {
      return 'Use your official college email address.';
    }
    return null;
  }
}
