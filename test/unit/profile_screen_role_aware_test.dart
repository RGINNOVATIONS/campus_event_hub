import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/features/auth/domain/profile.dart';
import 'package:campus_event_hub/features/profile/presentation/screens/profile_screen.dart';

void main() {
  Widget buildTestScreen(Profile profile) {
    return ProviderScope(
      overrides: [
        currentProfileProvider.overrideWith((ref) => Stream.value(profile)),
      ],
      child: const MaterialApp(
        home: ProfileScreen(),
      ),
    );
  }

  group('Role-Aware ProfileScreen Tests', () {
    testWidgets('Student profile displays academic fields and Branch, NOT Department', (tester) async {
      final studentProfile = Profile(
        id: 'student-1',
        fullName: 'Gurjot Singh',
        collegeEmail: 'gurjot.singh2@nmims.in',
        studentId: '70022300245',
        rollNo: 'B205',
        programme: 'B.Tech',
        branch: 'Computer Engineering (CE)',
        department: 'Computer Engineering (CE)',
        academicYear: 'Third Year',
        role: UserRole.student,
        emailVerified: true,
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(buildTestScreen(studentProfile));
      await tester.pumpAndSettle();

      // Student academic fields MUST appear
      expect(find.text('Gurjot Singh'), findsOneWidget);
      expect(find.text('70022300245'), findsOneWidget);
      expect(find.text('B205'), findsOneWidget);
      expect(find.text('B.Tech'), findsOneWidget);
      expect(find.text('Branch'), findsOneWidget);
      expect(find.text('Computer Engineering (CE)'), findsOneWidget);
      expect(find.text('Third Year'), findsOneWidget);
      expect(find.text('gurjot.singh2@nmims.in'), findsWidgets);

      // Department MUST NOT appear in the UI
      expect(find.text('Department'), findsNothing);

      // No raw placeholder '—' or 'N/A'
      expect(find.text('—'), findsNothing);
      expect(find.text('N/A'), findsNothing);
    });

    testWidgets('Organizer profile hides Roll No, Programme, Branch, Department, Academic Year', (tester) async {
      final organizerProfile = Profile(
        id: 'org-1',
        fullName: 'Swapnil Mahajan',
        collegeEmail: 'swapnil.mahajan@nmims.edu',
        studentId: 'ORG-2023-018',
        rollNo: '—',
        programme: '—',
        branch: 'N/A',
        department: 'N/A',
        academicYear: '—',
        role: UserRole.organizer,
        emailVerified: true,
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(buildTestScreen(organizerProfile));
      await tester.pumpAndSettle();

      // Organizer details MUST appear
      expect(find.text('Swapnil Mahajan'), findsOneWidget);
      expect(find.text('Organizer ID'), findsOneWidget);
      expect(find.text('ORG-2023-018'), findsOneWidget);
      expect(find.text('swapnil.mahajan@nmims.edu'), findsWidgets);
      expect(find.text('Organizer'), findsWidgets);

      // Student-only academic fields MUST NOT appear
      expect(find.text('Roll No'), findsNothing);
      expect(find.text('Programme'), findsNothing);
      expect(find.text('Branch'), findsNothing);
      expect(find.text('Department'), findsNothing);
      expect(find.text('Academic year'), findsNothing);

      // No raw placeholder '—' or 'N/A' rendered as rows
      expect(find.text('—'), findsNothing);
      expect(find.text('N/A'), findsNothing);
    });

    testWidgets('Admin profile hides student academic fields and shows staff info', (tester) async {
      final adminProfile = Profile(
        id: 'admin-1',
        fullName: 'Dr. Admin User',
        collegeEmail: 'admin@nmims.edu',
        studentId: 'EMP-9901',
        rollNo: '—',
        programme: '—',
        branch: 'N/A',
        department: 'N/A',
        academicYear: '—',
        role: UserRole.admin,
        emailVerified: true,
        createdAt: DateTime(2026, 1, 1),
      );



      await tester.pumpWidget(buildTestScreen(adminProfile));
      await tester.pumpAndSettle();

      expect(find.text('Dr. Admin User'), findsOneWidget);
      expect(find.text('Staff ID'), findsOneWidget);
      expect(find.text('EMP-9901'), findsOneWidget);
      expect(find.text('Admin'), findsWidgets);

      expect(find.text('Roll No'), findsNothing);
      expect(find.text('Programme'), findsNothing);
      expect(find.text('Branch'), findsNothing);
      expect(find.text('Department'), findsNothing);
      expect(find.text('Academic year'), findsNothing);
    });
  });
}
