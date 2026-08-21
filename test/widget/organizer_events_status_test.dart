import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_pulse/app/theme.dart';
import 'package:campus_pulse/app/providers.dart';
import 'package:campus_pulse/core/domain/enums.dart';
import 'package:campus_pulse/core/result/result.dart';
import 'package:campus_pulse/features/attendance/domain/scan_result.dart';
import 'package:campus_pulse/features/events/domain/event.dart';
import 'package:campus_pulse/features/organizer/domain/organizer_repository.dart';
import 'package:campus_pulse/features/organizer/presentation/screens/organizer_events_screen.dart';

EventModel _eventWithStatus(EventStatus status, String id, String title) =>
    EventModel(
      id: id,
      clubId: 'c1',
      clubName: 'Cultural Committee',
      categoryId: 'cat1',
      categoryName: 'Cultural',
      title: title,
      shortDescription: 'short',
      fullDescription: 'full',
      venue: 'Cricket Ground',
      startAt: DateTime(2026, 9, 10),
      endAt: DateTime(2026, 9, 10, 8),
      registrationDeadline: DateTime(2026, 9, 5),
      eligibility: 'All',
      rules: 'None',
      contactName: 'Organizer',
      contactEmail: 'organizer@college.edu.example',
      status: status,
      rejectionReason: status == EventStatus.rejected
          ? 'Estate Office sign-off missing.'
          : null,
    );

class _MultiEventOrganizerRepo implements OrganizerRepository {
  @override
  Future<Result<List<EventModel>>> myClubEvents() async => Result.ok([
        _eventWithStatus(
            EventStatus.rejected, 'e1', 'Midnight Movie Marathon'),
        _eventWithStatus(EventStatus.draft, 'e2', 'Draft Event'),
        _eventWithStatus(
            EventStatus.pendingApproval, 'e3', 'Pending Event'),
        _eventWithStatus(EventStatus.published, 'e4', 'Published Event'),
      ]);
  @override
  Future<Result<OrganizerDashboardCounts>> dashboardCounts() async =>
      throw UnimplementedError();
  @override
  Future<Result<int>> issueCertificates(String eventId) async =>
      throw UnimplementedError();
  @override
  Future<Result<void>> markEventCompleted(String eventId) async =>
      throw UnimplementedError();
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
      throw UnimplementedError();
  @override
  Future<Result<void>> deleteEvent(String eventId) async =>
      throw UnimplementedError();
  @override
  Future<Result<String>> uploadPoster(
          {required List<int> bytes, required String fileExtension}) async =>
      throw UnimplementedError();
}

void main() {
  testWidgets('organizer sees the rejection reason for a rejected event',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          organizerRepositoryProvider
              .overrideWithValue(_MultiEventOrganizerRepo())
        ],
        child: MaterialApp(
            theme: AppTheme.dark, home: const OrganizerEventsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Midnight Movie Marathon'), findsOneWidget);
    expect(
        find.textContaining('Estate Office sign-off missing.'), findsOneWidget);
  });

  testWidgets(
      'organizer sees Edit and Delete actions for draft, pending and rejected events, but not published',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          organizerRepositoryProvider
              .overrideWithValue(_MultiEventOrganizerRepo())
        ],
        child: MaterialApp(
            theme: AppTheme.dark, home: const OrganizerEventsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // The screen should have 4 events. Three of them should have an "Edit" button and a "Delete" button.
    // The total number of "Edit" buttons on the screen should be 3.
    expect(find.text('Edit'), findsNWidgets(3));
    expect(find.text('Delete'), findsNWidgets(3));
  });
}
