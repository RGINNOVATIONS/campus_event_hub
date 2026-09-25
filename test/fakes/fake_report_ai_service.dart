import 'package:campus_event_hub/core/errors/app_failure.dart';
import 'package:campus_event_hub/core/result/result.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';
import 'package:campus_event_hub/features/reports/data/report_ai_service.dart';
import 'package:campus_event_hub/features/reports/domain/event_report_ai_content.dart';

/// In-memory test implementation of ReportAiService.
///
/// Renamed and relocated from DemoReportAiService to test/fakes/fake_report_ai_service.dart.
class FakeReportAiService implements ReportAiService {
  static final Map<String, EventReportContent> _store = {};

  static void reset() {
    _store.clear();
  }

  @override
  Future<Result<ObjectivesAndOutcomesDraft>> draftObjectivesAndOutcomes({
    required String eventId,
    required String organizerNotes,
    String? category,
    int? registrationsCount,
    int? attendanceCount,
    dynamic attendancePercentage,
    List<EventGuest>? guests,
  }) async {
    final notes = organizerNotes.trim();
    if (notes.isEmpty) {
      return Result.err(const ValidationFailure(
          'Organizer notes are required to draft objectives and outcomes.'));
    }

    final objectives =
        '• Equip participants with practical, hands-on experience in core problem domains.\n'
        '• Foster interdisciplinary student collaboration and teamwork across branches.\n'
        '• Deliver structured mentorship and interactive guidance aligned with industry practices.\n'
        '• Address core event goals: $notes';

    final outcomes =
        '• Successfully engaged ${attendanceCount ?? 3} participating students with active attendance.\n'
        '• Achieved an attendance rate of ${attendancePercentage ?? 75.0}% among registered participants.\n'
        '• Facilitated end-to-end prototype delivery and peer review.\n'
        '• Completed scheduled sessions according to the organizer account.';

    return Result.ok(ObjectivesAndOutcomesDraft(
      objectives: objectives,
      outcomes: outcomes,
      rawText: '## Objectives\n$objectives\n\n## Key Outcomes & Impact\n$outcomes',
    ));
  }

  @override
  Future<Result<String>> draftFeedbackNarrative(String eventId) async {
    return Result.ok(
      'Overall student feedback was overwhelmingly positive, with attendees commending the structured hands-on sessions, engaging mentors, and high relevance to coursework. Constructive remarks suggested extending future project review intervals to allow deeper evaluation.',
    );
  }

  @override
  Future<Result<String>> polishOrganizerNotes({
    required String eventId,
    required String organizerNotes,
  }) async {
    final notes = organizerNotes.trim();
    if (notes.isEmpty) {
      return Result.err(const ValidationFailure(
          'Organizer notes are required to polish.'));
    }

    return Result.ok(
      'Successfully organized and executed the scheduled event program. '
      'Key sessions proceeded smoothly with active attendee participation and interactive discussions. '
      'Summary account: $notes',
    );
  }

  @override
  Future<Result<EventReportContent>> saveReportContent(
    String eventId,
    EventReportContent content,
  ) async {
    final now = DateTime.now();
    final saved = EventReportContent(
      eventId: eventId,
      organizerNotes: content.organizerNotes,
      objectives: content.objectives,
      outcomes: content.outcomes,
      feedbackNarrative: content.feedbackNarrative,
      status: content.status,
      createdBy: content.createdBy ?? 'usr-org-1',
      confirmedBy: content.isConfirmed ? 'usr-org-1' : null,
      confirmedAt: content.isConfirmed ? (content.confirmedAt ?? now) : null,
      updatedAt: now,
      createdAt: content.createdAt ?? now,
    );
    _store[eventId] = saved;
    return Result.ok(saved);
  }

  @override
  Future<Result<EventReportContent?>> getReportContent(String eventId) async {
    return Result.ok(_store[eventId]);
  }

  @override
  Future<Result<String>> generateReportDocx(String eventId) async {
    final report = _store[eventId];
    if (report == null || !report.isConfirmed) {
      return Result.err(const ValidationFailure(
          'Event report must be reviewed and confirmed as final before downloading.'));
    }
    return Result.err(const ValidationFailure(
        'Report download is only available when connected to the live backend.'));
  }
}
