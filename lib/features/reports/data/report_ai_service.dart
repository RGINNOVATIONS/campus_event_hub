import 'package:campus_event_hub/core/errors/app_failure.dart';
import 'package:campus_event_hub/core/result/result.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';
import 'package:campus_event_hub/features/reports/domain/event_report_ai_content.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ReportAiService {
  Future<Result<ObjectivesAndOutcomesDraft>> draftObjectivesAndOutcomes({
    required String eventId,
    required String organizerNotes,
    String? category,
    int? registrationsCount,
    int? attendanceCount,
    dynamic attendancePercentage,
    List<EventGuest>? guests,
  });

  Future<Result<String>> draftFeedbackNarrative(String eventId);

  Future<Result<EventReportContent>> saveReportContent(
    String eventId,
    EventReportContent content,
  );

  Future<Result<EventReportContent?>> getReportContent(String eventId);
}

class SupabaseReportAiService implements ReportAiService {
  final SupabaseClient _client;

  SupabaseReportAiService(this._client);

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
    try {
      final response = await _client.functions.invoke(
        'draft-report-content',
        body: {
          'mode': 'objectives_and_outcomes',
          'event_id': eventId,
          'organizer_notes': organizerNotes,
          if (category != null) 'category': category,
          if (registrationsCount != null)
            'registrations_count': registrationsCount,
          if (attendanceCount != null) 'attendance_count': attendanceCount,
          if (attendancePercentage != null)
            'attendance_percentage': attendancePercentage,
          if (guests != null)
            'guests': guests
                .map((g) => {
                      'name': g.name,
                      'designation': g.designation,
                      'organization': g.organization,
                    })
                .toList(),
        },
      );

      final data = response.data;
      if (data is Map) {
        if (data.containsKey('error')) {
          return Result.err(ValidationFailure(data['error'].toString()));
        }
        return Result.ok(ObjectivesAndOutcomesDraft(
          objectives: data['objectives'] as String? ?? '',
          outcomes: data['outcomes'] as String? ?? '',
          rawText: data['raw_text'] as String? ?? '',
        ));
      }
      return Result.err(const UnknownFailure(
          'Invalid response from AI drafting service.'));
    } on FunctionException catch (fe) {
      if (fe.status == 401 || fe.status == 403) {
        return Result.err(const AuthorizationFailure(
            'Not authorized to draft content for this event.'));
      }
      final msg = fe.details is Map && fe.details['error'] != null
          ? fe.details['error'].toString()
          : (fe.reasonPhrase ?? 'AI drafting failed.');
      return Result.err(ValidationFailure(msg));
    } catch (e) {
      return Result.err(mapExceptionToFailure(e,
          fallbackMessage: 'AI drafting service unavailable.'));
    }
  }

  @override
  Future<Result<String>> draftFeedbackNarrative(String eventId) async {
    try {
      final response = await _client.functions.invoke(
        'draft-report-content',
        body: {
          'mode': 'feedback_narrative',
          'event_id': eventId,
        },
      );

      final data = response.data;
      if (data is Map) {
        if (data.containsKey('error')) {
          return Result.err(ValidationFailure(data['error'].toString()));
        }
        return Result.ok(data['narrative'] as String? ?? '');
      }
      return Result.err(const UnknownFailure(
          'Invalid response from AI drafting service.'));
    } on FunctionException catch (fe) {
      if (fe.status == 401 || fe.status == 403) {
        return Result.err(const AuthorizationFailure(
            'Not authorized to draft content for this event.'));
      }
      final msg = fe.details is Map && fe.details['error'] != null
          ? fe.details['error'].toString()
          : (fe.reasonPhrase ?? 'AI drafting failed.');
      return Result.err(ValidationFailure(msg));
    } catch (e) {
      return Result.err(mapExceptionToFailure(e,
          fallbackMessage: 'AI drafting service unavailable.'));
    }
  }

  @override
  Future<Result<EventReportContent>> saveReportContent(
    String eventId,
    EventReportContent content,
  ) async {
    try {
      final payload = content.toMap();
      // Server-side PostgreSQL trigger enforces created_by, confirmed_by, confirmed_at, updated_at
      payload.remove('created_by');
      payload.remove('confirmed_by');
      payload.remove('confirmed_at');
      payload.remove('created_at');
      payload.remove('updated_at');

      final row = await _client
          .from('event_reports')
          .upsert(payload)
          .select()
          .single();

      return Result.ok(EventReportContent.fromMap(row));
    } catch (e) {
      return Result.err(mapExceptionToFailure(e,
          fallbackMessage: 'Could not save report content.'));
    }
  }

  @override
  Future<Result<EventReportContent?>> getReportContent(String eventId) async {
    try {
      final row = await _client
          .from('event_reports')
          .select()
          .eq('event_id', eventId)
          .maybeSingle();

      if (row == null) return Result.ok(null);
      return Result.ok(EventReportContent.fromMap(row));
    } catch (e) {
      return Result.err(mapExceptionToFailure(e,
          fallbackMessage: 'Could not load report content.'));
    }
  }
}

class DemoReportAiService implements ReportAiService {
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
}
