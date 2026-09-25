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

  Future<Result<String>> polishOrganizerNotes({
    required String eventId,
    required String organizerNotes,
  });

  Future<Result<EventReportContent>> saveReportContent(
    String eventId,
    EventReportContent content,
  );

  Future<Result<EventReportContent?>> getReportContent(String eventId);

  Future<Result<String>> generateReportDocx(String eventId);
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
  Future<Result<String>> polishOrganizerNotes({
    required String eventId,
    required String organizerNotes,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'draft-report-content',
        body: {
          'mode': 'polish_notes',
          'event_id': eventId,
          'organizer_notes': organizerNotes,
        },
      );

      final data = response.data;
      if (data is Map) {
        if (data.containsKey('error')) {
          return Result.err(ValidationFailure(data['error'].toString()));
        }
        return Result.ok(data['polished_notes'] as String? ?? '');
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
          : (fe.reasonPhrase ?? 'AI polishing failed.');
      return Result.err(ValidationFailure(msg));
    } catch (e) {
      return Result.err(mapExceptionToFailure(e,
          fallbackMessage: 'AI polishing service unavailable.'));
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

  @override
  Future<Result<String>> generateReportDocx(String eventId) async {
    try {
      final response = await _client.functions.invoke(
        'generate-event-report-docx',
        body: {
          'event_id': eventId,
        },
      );

      final data = response.data;
      if (data is Map) {
        if (data.containsKey('error')) {
          return Result.err(ValidationFailure(data['error'].toString()));
        }
        final signedUrl = data['signed_url'] as String?;
        if (signedUrl == null || signedUrl.isEmpty) {
          return Result.err(
              const UnknownFailure('Download URL was not returned.'));
        }
        return Result.ok(signedUrl);
      }
      return Result.err(const UnknownFailure(
          'Invalid response from report document service.'));
    } on FunctionException catch (fe) {
      if (fe.status == 401 || fe.status == 403) {
        return Result.err(const AuthorizationFailure(
            'Not authorized to download report for this event.'));
      }
      final msg = fe.details is Map && fe.details['error'] != null
          ? fe.details['error'].toString()
          : (fe.reasonPhrase ?? 'Report generation failed.');
      return Result.err(ValidationFailure(msg));
    } catch (e) {
      return Result.err(mapExceptionToFailure(e,
          fallbackMessage: 'Report generation service unavailable.'));
    }
  }
}
