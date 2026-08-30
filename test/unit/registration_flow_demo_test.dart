import 'package:campus_event_hub/core/demo/demo_data_store.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/features/auth/data/demo_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    DemoDataStore.instance.resetForTests();
  });

  group('Demo Mode Student Registration & Auth Flows', () {
    test('registers a B.Tech student with selected branch', () async {
      final repo = DemoAuthRepository();

      final result = await repo.register(
        fullName: 'Rohan Sharma',
        collegeEmail: 'rohan.sharma@nmims.edu',
        studentId: 'STU2026888',
        rollNo: '70012026888',
        programme: 'B.Tech',
        branch: 'Artificial Intelligence & Machine Learning (AIML)',
        academicYear: 'First Year',
        password: 'Password123!',
      );

      expect(result.isOk, isTrue);
      final current = repo.currentProfile;
      expect(current, isNotNull);
      expect(current!.fullName, 'Rohan Sharma');
      expect(current.collegeEmail, 'rohan.sharma@nmims.edu');
      expect(current.studentId, 'STU2026888');
      expect(current.rollNo, '70012026888');
      expect(current.programme, 'B.Tech');
      expect(current.branch, 'Artificial Intelligence & Machine Learning (AIML)');
      expect(current.department, 'Artificial Intelligence & Machine Learning (AIML)');
      expect(current.academicYear, 'First Year');
      expect(current.role, UserRole.student);
    });

    test('registers a B.Pharm student with N/A branch', () async {
      final repo = DemoAuthRepository();

      final result = await repo.register(
        fullName: 'Priya Patel',
        collegeEmail: 'priya.patel@nmims.edu',
        studentId: 'PHARM2026101',
        rollNo: '80012026101',
        programme: 'B.Pharm',
        branch: 'N/A',
        academicYear: 'Second Year',
        password: 'Password123!',
      );

      expect(result.isOk, isTrue);
      final current = repo.currentProfile;
      expect(current, isNotNull);
      expect(current!.fullName, 'Priya Patel');
      expect(current.collegeEmail, 'priya.patel@nmims.edu');
      expect(current.studentId, 'PHARM2026101');
      expect(current.rollNo, '80012026101');
      expect(current.programme, 'B.Pharm');
      expect(current.branch, 'N/A');
      expect(current.department, 'N/A');
      expect(current.academicYear, 'Second Year');
      expect(current.role, UserRole.student);
    });

    test('all 3 seeded demo accounts still log in and have expected profile data', () async {
      final repo = DemoAuthRepository();

      // Student login
      var loginRes = await repo.login(
        email: DemoAccounts.student.collegeEmail,
        password: DemoAccounts.demoPassword,
      );
      expect(loginRes.isOk, isTrue);
      expect(repo.currentProfile?.id, DemoAccounts.student.id);
      expect(repo.currentProfile?.studentId, 'STU2026041');
      expect(repo.currentProfile?.rollNo, '70012026041');
      expect(repo.currentProfile?.programme, 'B.Tech');
      expect(repo.currentProfile?.branch, 'Computer Engineering (CE)');

      // Organizer login
      loginRes = await repo.login(
        email: DemoAccounts.organizer.collegeEmail,
        password: DemoAccounts.demoPassword,
      );
      expect(loginRes.isOk, isTrue);
      expect(repo.currentProfile?.id, DemoAccounts.organizer.id);
      expect(repo.currentProfile?.studentId, 'EMP0098');
      expect(repo.currentProfile?.programme, 'N/A');
      expect(repo.currentProfile?.branch, 'N/A');

      // Admin login
      loginRes = await repo.login(
        email: DemoAccounts.admin.collegeEmail,
        password: DemoAccounts.demoPassword,
      );
      expect(loginRes.isOk, isTrue);
      expect(repo.currentProfile?.id, DemoAccounts.admin.id);
      expect(repo.currentProfile?.studentId, 'EMP0001');
      expect(repo.currentProfile?.programme, 'N/A');
      expect(repo.currentProfile?.branch, 'N/A');
    });
  });
}
