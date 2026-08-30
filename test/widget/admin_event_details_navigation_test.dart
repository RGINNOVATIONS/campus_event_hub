import 'package:campus_event_hub/app/env.dart';
import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/core/demo/demo_data_store.dart';
import 'package:campus_event_hub/core/widgets/widgets.dart';
import 'package:campus_event_hub/features/admin/data/demo_admin_repository.dart';
import 'package:campus_event_hub/features/admin/presentation/screens/admin_screens.dart';
import 'package:campus_event_hub/features/admin/presentation/screens/admin_shell.dart';
import 'package:campus_event_hub/features/auth/data/demo_auth_repository.dart';
import 'package:campus_event_hub/features/clubs/data/demo_club_repository.dart';
import 'package:campus_event_hub/features/events/data/demo_event_repository.dart';
import 'package:campus_event_hub/features/organizer/data/demo_organizer_repository.dart';
import 'package:campus_event_hub/features/organizer/presentation/screens/event_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    await Env.load();
  });

  setUp(() => DemoDataStore.instance.resetForTests());

  testWidgets(
      'Admin can tap pending event card to open EventManagementScreen in read-only mode',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminRepositoryProvider.overrideWithValue(DemoAdminRepository()),
          eventRepositoryProvider.overrideWithValue(DemoEventRepository()),
          organizerRepositoryProvider
              .overrideWithValue(DemoOrganizerRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const PendingEventsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify pending event card appears
    expect(find.text('Drone Racing Trials'), findsOneWidget);

    // Tap on the event card (title) to open details
    await tester.tap(find.text('Drone Racing Trials'));
    await tester.pumpAndSettle();

    // Verify EventManagementScreen opened
    expect(find.byType(EventManagementScreen), findsOneWidget);
    expect(find.text('Registered Students'), findsOneWidget);
    expect(find.text('Total Registered'), findsOneWidget);
    expect(find.text('Verified Attended'), findsOneWidget);

    // Verify write actions are NOT present (read-only mode)
    expect(find.text('Edit Event'), findsNothing);
    expect(find.text('Postpone Event'), findsNothing);
    expect(find.text('Scan Attendance'), findsNothing);
    expect(find.text('Delete Event'), findsNothing);
    expect(find.text('Mark Event Completed'), findsNothing);

    // Verify CSV Download action IS present
    expect(find.text('Download CSV'), findsOneWidget);
  });

  testWidgets(
      'Admin can tap calendar event to open EventManagementScreen in read-only mode',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminRepositoryProvider.overrideWithValue(DemoAdminRepository()),
          eventRepositoryProvider.overrideWithValue(DemoEventRepository()),
          organizerRepositoryProvider
              .overrideWithValue(DemoOrganizerRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const AdminCalendarScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Find the first published calendar event title
    final eventTitleFinder = find.text('RoboWars 2026');
    expect(eventTitleFinder, findsOneWidget);

    // Tap the event item
    await tester.tap(eventTitleFinder);
    await tester.pumpAndSettle();

    // Verify EventManagementScreen opened in read-only mode
    expect(find.byType(EventManagementScreen), findsOneWidget);
    expect(find.text('Registered Students'), findsOneWidget);

    // Write actions are hidden
    expect(find.text('Edit Event'), findsNothing);
    expect(find.text('Delete Event'), findsNothing);
  });

  testWidgets(
      'AdminDashboardScreen renders profile button in top-right AppBar actions',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminRepositoryProvider.overrideWithValue(DemoAdminRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const AdminDashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Administrator Dashboard'), findsOneWidget);
    expect(find.byType(OrganizerProfileButton), findsOneWidget);
  });

  testWidgets(
      'AdminShell renders 5 destinations and NO profile in bottom nav',
      (tester) async {
    DemoDataStore.instance.currentUserId = 'demo-admin-1';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          demoModeProvider.overrideWithValue(true),
          adminRepositoryProvider.overrideWithValue(DemoAdminRepository()),
          eventRepositoryProvider.overrideWithValue(DemoEventRepository()),
          clubRepositoryProvider.overrideWithValue(DemoClubRepository()),
          organizerRepositoryProvider
              .overrideWithValue(DemoOrganizerRepository()),
          currentProfileProvider
              .overrideWith((ref) => Stream.value(DemoAccounts.admin)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const AdminShell(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Verify 5 bottom nav destinations
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Campus'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Clubs'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);

    // Profile must NOT appear in bottom navigation
    expect(find.text('Profile'), findsNothing);
  });
}
