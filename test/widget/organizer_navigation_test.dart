import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/core/result/result.dart';
import 'package:campus_event_hub/features/attendance/domain/scan_result.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';
import 'package:campus_event_hub/features/organizer/domain/organizer_repository.dart';
import 'package:campus_event_hub/features/organizer/presentation/screens/organizer_events_screen.dart';
import 'package:campus_event_hub/features/organizer/presentation/screens/organizer_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

EventModel _event(EventStatus status, String id, String title) => EventModel(
      id: id,
      clubId: 'c1',
      clubName: 'Cultural Committee',
      categoryId: 'cat1',
      categoryName: 'Cultural',
      title: title,
      shortDescription: 'short',
      fullDescription: 'full',
      venue: 'Auditorium',
      startAt: DateTime(2026, 9, 10),
      endAt: DateTime(2026, 9, 10, 8),
      registrationDeadline: DateTime(2026, 9, 5),
      eligibility: 'All',
      rules: 'None',
      contactName: 'Organizer',
      contactEmail: 'organizer@college.edu',
      status: status,
    );

class _MockOrganizerRepo implements OrganizerRepository {
  @override
  Future<Result<List<EventModel>>> myClubEvents() async => Result.ok([
        _event(EventStatus.published, 'e1', 'Hackathon 2026'),
        _event(EventStatus.pendingApproval, 'e2', 'Dance Competition'),
        _event(EventStatus.completed, 'e3', 'Alumni Meet'),
        _event(EventStatus.draft, 'e4', 'Robotics Workshop'),
      ]);

  @override
  Future<Result<OrganizerDashboardCounts>> dashboardCounts() async =>
      Result.ok(const OrganizerDashboardCounts(
        totalEvents: 4,
        pendingApprovals: 1,
        published: 1,
        completed: 1,
        totalRegistrations: 42,
        totalAttendees: 20,
      ));

  @override
  Future<Result<int>> issueCertificates(String eventId) async => Result.ok(0);

  @override
  Future<Result<void>> markEventCompleted(String eventId) async =>
      Result.ok(null);

  @override
  Future<Result<List<RegistrationRow>>> registrationsFor(
          String eventId) async =>
      Result.ok([]);

  @override
  Future<Result<EventModel>> saveDraft(DraftEventInput input) async =>
      throw UnimplementedError();

  @override
  Future<Result<ScanOutcome>> scanAttendance(
          {required String eventId, required String qrToken}) async =>
      throw UnimplementedError();

  @override
  Future<Result<void>> submitForApproval(String eventId) async =>
      Result.ok(null);

  @override
  Future<Result<void>> postponeEvent({
    required String eventId,
    required DateTime startAt,
    required DateTime endAt,
    required DateTime registrationDeadline,
    required String reason,
  }) async =>
      Result.ok(null);

  @override
  Future<Result<void>> deleteEvent(String eventId) async => Result.ok(null);

  @override
  Future<Result<String>> uploadPoster(
          {required List<int> bytes, required String fileExtension}) async =>
      throw UnimplementedError();
}

void main() {
  testWidgets('OrganizerShell renders 4 core destinations and no profile in bottom nav',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          organizerRepositoryProvider.overrideWithValue(_MockOrganizerRepo()),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const OrganizerShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify 4 bottom navigation destinations exist
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('My Events'), findsWidgets);
    expect(find.text('Create Event'), findsWidgets);
    expect(find.text('Scan'), findsWidgets);

    // Profile should NOT be in bottom navigation
    final bottomNav = find.byType(NavigationBar);
    expect(bottomNav, findsOneWidget);
    expect(find.descendant(of: bottomNav, matching: find.text('Profile')),
        findsNothing);
  });

  testWidgets('OrganizerEventsScreen filter tabs filter events correctly',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          organizerRepositoryProvider.overrideWithValue(_MockOrganizerRepo()),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const OrganizerEventsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Initially "All" shows all 4 events
    expect(find.text('Hackathon 2026'), findsOneWidget);
    expect(find.text('Dance Competition'), findsOneWidget);
    expect(find.text('Alumni Meet'), findsOneWidget);
    expect(find.text('Robotics Workshop'), findsOneWidget);

    // Tap "Published" tab
    await tester.tap(find.text('Published (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Hackathon 2026'), findsOneWidget);
    expect(find.text('Dance Competition'), findsNothing);
    expect(find.text('Alumni Meet'), findsNothing);
    expect(find.text('Robotics Workshop'), findsNothing);

    // Tap "Pending" tab
    await tester.tap(find.text('Pending (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Hackathon 2026'), findsNothing);
    expect(find.text('Dance Competition'), findsOneWidget);

    // Tap "Completed" tab
    await tester.tap(find.text('Completed (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Alumni Meet'), findsOneWidget);
    expect(find.text('Dance Competition'), findsNothing);
  });
}
