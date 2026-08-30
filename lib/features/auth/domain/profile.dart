import 'package:campus_event_hub/core/domain/enums.dart';

class Profile {
  final String id;
  final String fullName;
  final String collegeEmail;
  final String studentId;
  final String rollNo;
  final String programme;
  final String branch;
  final String department;
  final String academicYear;
  final UserRole role;
  final bool emailVerified;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.fullName,
    required this.collegeEmail,
    required this.studentId,
    required this.rollNo,
    required this.programme,
    required this.branch,
    required this.department,
    required this.academicYear,
    required this.role,
    required this.emailVerified,
    required this.createdAt,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    final branchVal = (map['branch'] as String?)?.trim();
    final deptVal = (map['department'] as String?)?.trim();
    final resolvedBranch = (branchVal != null && branchVal.isNotEmpty)
        ? branchVal
        : (deptVal != null && deptVal.isNotEmpty ? deptVal : 'N/A');

    return Profile(
      id: map['id'] as String,
      fullName: (map['full_name'] as String?) ?? '',
      collegeEmail: (map['college_email'] as String?) ?? '',
      studentId: ((map['student_id'] ?? map['college_id']) as String?) ?? 'N/A',
      rollNo: (map['roll_no'] as String?) ?? 'N/A',
      programme: (map['programme'] as String?) ?? 'N/A',
      branch: resolvedBranch,
      department: (deptVal != null && deptVal.isNotEmpty) ? deptVal : resolvedBranch,
      academicYear: (map['academic_year'] as String?) ?? 'First Year',
      role: UserRoleX.fromDb((map['role'] as String?) ?? 'student'),
      emailVerified: map['email_verified'] as bool? ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  Profile copyWith({
    String? id,
    String? fullName,
    String? collegeEmail,
    String? studentId,
    String? rollNo,
    String? programme,
    String? branch,
    String? department,
    String? academicYear,
    UserRole? role,
    bool? emailVerified,
    DateTime? createdAt,
  }) =>
      Profile(
        id: id ?? this.id,
        fullName: fullName ?? this.fullName,
        collegeEmail: collegeEmail ?? this.collegeEmail,
        studentId: studentId ?? this.studentId,
        rollNo: rollNo ?? this.rollNo,
        programme: programme ?? this.programme,
        branch: branch ?? this.branch,
        department: department ?? this.department,
        academicYear: academicYear ?? this.academicYear,
        role: role ?? this.role,
        emailVerified: emailVerified ?? this.emailVerified,
        createdAt: createdAt ?? this.createdAt,
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
