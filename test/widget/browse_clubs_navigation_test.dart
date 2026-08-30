import 'package:campus_event_hub/app/env.dart';
import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/app/router.dart';
import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/core/demo/demo_data_store.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/features/admin/data/demo_admin_repository.dart';
import 'package:campus_event_hub/features/auth/data/demo_auth_repository.dart';
import 'package:campus_event_hub/features/auth/domain/profile.dart';
import 'package:campus_event_hub/features/certificates/data/demo_certificate_repository.dart';
import 'package:campus_event_hub/features/clubs/data/demo_club_repository.dart';
import 'package:campus_event_hub/features/clubs/presentation/screens/clubs_screen.dart';
import 'package:campus_event_hub/features/events/data/demo_event_repository.dart';
import 'package:campus_event_hub/features/notifications/data/demo_notification_repository.dart';
import 'package:campus_event_hub/features/organizer/data/demo_organizer_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    await Env.load();
  });

  setUp(() => DemoDataStore.instance.resetForTests());

  Widget buildAppWithProfile(Profile profile) {
    DemoDataStore.instance.currentUserId = profile.id;

    return ProviderScope(
      overrides: [
        demoModeProvider.overrideWithValue(true),
        authRepositoryProvider.overrideWithValue(DemoAuthRepository()),
        adminRepositoryProvider.overrideWithValue(DemoAdminRepository()),
        clubRepositoryProvider.overrideWithValue(DemoClubRepository()),
        eventRepositoryProvider.overrideWithValue(DemoEventRepository()),
        certificateRepositoryProvider
            .overrideWithValue(DemoCertificateRepository()),
        organizerRepositoryProvider
            .overrideWithValue(DemoOrganizerRepository()),
        notificationRepositoryProvider
            .overrideWithValue(DemoNotificationRepository()),
        currentProfileProvider.overrideWith((ref) => Stream.value(profile)),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(routerProvider);
          return MaterialApp.router(
            theme: AppTheme.dark,
            routerConfig: router,
          );
        },
      ),
    );
  }

  group('Browse Clubs Navigation Tests across all roles', () {
    testWidgets('Student taps Browse Clubs from Profile and reaches ClubsScreen',
        (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final studentProfile = Profile(
        id: 'student-demo-1',
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

      await tester.pumpWidget(buildAppWithProfile(studentProfile));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp)));
      container.read(routerProvider).go('/profile');
      await tester.pumpAndSettle();

      final browseClubsFinder = find.text('Browse Clubs');
      await tester.scrollUntilVisible(browseClubsFinder, 200,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      expect(browseClubsFinder, findsOneWidget);
      await tester.tap(browseClubsFinder);
      await tester.pumpAndSettle();

      expect(find.byType(ClubsScreen), findsOneWidget);
    });

    testWidgets(
        'Organizer taps Browse Clubs from Profile and reaches ClubsScreen (not Home)',
        (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final organizerProfile = Profile(
        id: 'org-demo-1',
        fullName: 'Swapnil Mahajan',
        collegeEmail: 'swapnil.mahajan@nmims.edu',
        studentId: 'ORG-001',
        rollNo: '',
        programme: '',
        branch: '',
        department: '',
        academicYear: '',
        role: UserRole.organizer,
        emailVerified: true,
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(buildAppWithProfile(organizerProfile));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp)));
      container.read(routerProvider).go('/profile');
      await tester.pumpAndSettle();

      final browseClubsFinder = find.text('Browse Clubs');
      await tester.scrollUntilVisible(browseClubsFinder, 200,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      expect(browseClubsFinder, findsOneWidget);
      await tester.tap(browseClubsFinder);
      await tester.pumpAndSettle();

      // Must open ClubsScreen, NOT redirected to /organizer
      expect(find.byType(ClubsScreen), findsOneWidget);
    });

    testWidgets(
        'Admin taps Browse Clubs from Profile and reaches ClubsScreen (not Home)',
        (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final adminProfile = Profile(
        id: 'admin-demo-1',
        fullName: 'Campus Administrator',
        collegeEmail: 'admin@nmims.edu',
        studentId: 'ADM-001',
        rollNo: '',
        programme: '',
        branch: '',
        department: '',
        academicYear: '',
        role: UserRole.admin,
        emailVerified: true,
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(buildAppWithProfile(adminProfile));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp)));
      container.read(routerProvider).go('/profile');
      await tester.pumpAndSettle();

      final browseClubsFinder = find.text('Browse Clubs');
      await tester.scrollUntilVisible(browseClubsFinder, 200,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      expect(browseClubsFinder, findsOneWidget);
      await tester.tap(browseClubsFinder);
      await tester.pumpAndSettle();

      // Must open ClubsScreen, NOT redirected to /admin
      expect(find.byType(ClubsScreen), findsOneWidget);
    });
  });
}
