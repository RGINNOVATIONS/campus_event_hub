import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/features/auth/domain/profile.dart';

/// Seeded test accounts for the test suite.
///
/// Renamed and relocated from DemoAccounts to test/fakes/test_accounts.dart.
class TestAccounts {
  TestAccounts._();

  static final student = Profile(
    id: 'demo-student-1',
    fullName: 'Aisha Sharma',
    collegeEmail: 'demo.student@college.edu.example',
    studentId: 'STU2026041',
    rollNo: '70012026041',
    programme: 'B.Tech',
    branch: 'Computer Engineering (CE)',
    department: 'Computer Engineering (CE)',
    academicYear: 'Third Year',
    role: UserRole.student,
    emailVerified: true,
    createdAt: DateTime(2026, 1, 10),
  );

  static final organizer = Profile(
    id: 'demo-organizer-1',
    fullName: 'Rahul Verma',
    collegeEmail: 'demo.organizer@college.edu.example',
    studentId: 'EMP0098',
    rollNo: 'EMP0098',
    programme: 'N/A',
    branch: 'N/A',
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
    studentId: 'EMP0001',
    rollNo: 'EMP0001',
    programme: 'N/A',
    branch: 'N/A',
    department: 'Student Affairs',
    academicYear: 'N/A',
    role: UserRole.admin,
    emailVerified: true,
    createdAt: DateTime(2024, 6, 1),
  );

  static const testPassword = 'CampusEventHub#Demo1';
  static const demoPassword = 'CampusEventHub#Demo1';
}
