import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/features/auth/domain/academic_options.dart';
import 'package:campus_event_hub/features/auth/domain/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Academic Options Domain Rules', () {
    test('authoritative programme list contains expected keys', () {
      expect(programmeBranches.containsKey('B.Tech'), isTrue);
      expect(programmeBranches.containsKey('MBA Tech'), isTrue);
      expect(programmeBranches.containsKey('B.Pharm'), isTrue);
      expect(programmeBranches.containsKey('M.Pharm'), isTrue);
      expect(programmeBranches.containsKey('MBA Pharm'), isTrue);
      expect(programmeBranches.containsKey('MBA MPharm'), isTrue);
      expect(programmeBranches.containsKey('B.Sc (Hon.) Agriculture'), isTrue);
      expect(programmeBranches.containsKey('Diploma in Textile Tech. (DTT)'), isTrue);
    });

    test('B.Tech has 5 authoritative branches', () {
      final branches = programmeBranches['B.Tech']!;
      expect(branches, [
        'Computer Engineering (CE)',
        'Computer Science (CS)',
        'Information Technology (IT)',
        'Artificial Intelligence & Machine Learning (AIML)',
        'Computer Science & Data Science (CSDS)',
      ]);
    });

    test('MBA Tech has 1 branch and branch-less programmes have empty lists', () {
      expect(programmeBranches['MBA Tech'], ['Computer Engineering (CE)']);
      expect(programmeBranches['B.Pharm'], isEmpty);
      expect(programmeBranches['M.Pharm'], isEmpty);
      expect(programmeBranches['MBA Pharm'], isEmpty);
      expect(programmeBranches['MBA MPharm'], isEmpty);
      expect(programmeBranches['B.Sc (Hon.) Agriculture'], isEmpty);
      expect(programmeBranches['Diploma in Textile Tech. (DTT)'], isEmpty);
    });

    test('academic years list contains 5 distinct years', () {
      expect(academicYears, [
        'First Year',
        'Second Year',
        'Third Year',
        'Fourth Year',
        'Fifth Year',
      ]);
    });
  });

  group('Profile Model Parsing & Backward Compatibility', () {
    test('parses new schema fields correctly', () {
      final nowStr = DateTime.now().toIso8601String();
      final map = {
        'id': 'user-123',
        'full_name': 'Test Student',
        'college_email': 'test@nmims.in',
        'student_id': 'STU999',
        'roll_no': '7001999',
        'programme': 'B.Tech',
        'branch': 'Computer Engineering (CE)',
        'department': 'Computer Engineering (CE)',
        'academic_year': 'Second Year',
        'role': 'student',
        'email_verified': true,
        'created_at': nowStr,
      };

      final profile = Profile.fromMap(map);
      expect(profile.id, 'user-123');
      expect(profile.fullName, 'Test Student');
      expect(profile.collegeEmail, 'test@nmims.in');
      expect(profile.studentId, 'STU999');
      expect(profile.rollNo, '7001999');
      expect(profile.programme, 'B.Tech');
      expect(profile.branch, 'Computer Engineering (CE)');
      expect(profile.department, 'Computer Engineering (CE)');
      expect(profile.academicYear, 'Second Year');
      expect(profile.role, UserRole.student);
      expect(profile.emailVerified, isTrue);
    });

    test('falls back gracefully on legacy college_id and missing fields', () {
      final nowStr = DateTime.now().toIso8601String();
      final legacyMap = {
        'id': 'legacy-user-456',
        'full_name': 'Legacy Student',
        'college_email': 'legacy@nmims.in',
        'college_id': 'LEGACY001',
        'department': 'Computer Science',
        'academic_year': 'First Year',
        'role': 'student',
        'email_verified': false,
        'created_at': nowStr,
      };

      final profile = Profile.fromMap(legacyMap);
      expect(profile.studentId, 'LEGACY001');
      expect(profile.rollNo, 'N/A');
      expect(profile.programme, 'N/A');
      expect(profile.branch, 'Computer Science');
      expect(profile.department, 'Computer Science');
      expect(profile.academicYear, 'First Year');
    });

    test('copyWith updates fields while preserving existing values', () {
      final original = Profile(
        id: 'p-1',
        fullName: 'Name 1',
        collegeEmail: 'email1@nmims.in',
        studentId: 'ID1',
        rollNo: 'R1',
        programme: 'B.Tech',
        branch: 'CS',
        department: 'CS',
        academicYear: 'Third Year',
        role: UserRole.student,
        emailVerified: true,
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = original.copyWith(
        fullName: 'Name 2',
        rollNo: 'R2',
      );

      expect(updated.fullName, 'Name 2');
      expect(updated.rollNo, 'R2');
      expect(updated.studentId, 'ID1');
      expect(updated.programme, 'B.Tech');
      expect(updated.branch, 'CS');
    });
  });
}
