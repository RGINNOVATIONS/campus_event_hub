import 'dart:typed_data';

import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/core/errors/app_failure.dart';
import 'package:campus_event_hub/core/result/result.dart';
import 'package:campus_event_hub/features/attendance/domain/scan_result.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';
import 'package:campus_event_hub/features/organizer/domain/organizer_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseOrganizerRepository implements OrganizerRepository {
  final SupabaseClient _client;
  SupabaseOrganizerRepository(this._client);

  static const _eventSelect =
      'id, club_id, category_id, title, short_description, full_description, poster_path, '
      'venue, start_at, end_at, registration_deadline, eligibility, rules, fee_text, '
      'contact_name, contact_email, contact_phone, status, rejection_reason, '
      'clubs(name), categories(name)';

  EventModel _mapRow(Map<String, dynamic> row) => EventModel(
        id: row['id'] as String,
        clubId: row['club_id'] as String,
        clubName: (row['clubs']?['name'] as String?) ?? '',
        categoryId: row['category_id'] as String,
        categoryName: (row['categories']?['name'] as String?) ?? '',
        title: row['title'] as String,
        shortDescription: row['short_description'] as String,
        fullDescription: row['full_description'] as String,
        posterPath: row['poster_path'] as String?,
        venue: row['venue'] as String,
        startAt: DateTime.parse(row['start_at'] as String),
        endAt: DateTime.parse(row['end_at'] as String),
        registrationDeadline:
            DateTime.parse(row['registration_deadline'] as String),
        eligibility: row['eligibility'] as String? ?? '',
        rules: row['rules'] as String? ?? '',
        feeText: row['fee_text'] as String?,
        contactName: row['contact_name'] as String,
        contactEmail: row['contact_email'] as String,
        contactPhone: row['contact_phone'] as String?,
        status: EventStatusX.fromDb(row['status'] as String),
        rejectionReason: row['rejection_reason'] as String?,
      );

  Future<List<EventModel>> _resolvePosters(List<EventModel> events) async {
    final resolved = <EventModel>[];
    for (final event in events) {
      if (event.posterPath != null &&
          event.posterPath!.isNotEmpty &&
          !event.posterPath!.startsWith('http')) {
        try {
          final url = await _client.storage
              .from('event-posters')
              .createSignedUrl(event.posterPath!, 60 * 60 * 24 * 7);
          resolved.add(event.copyWith(posterPath: url));
        } catch (_) {
          resolved.add(event.copyWith(posterPath: null));
        }
      } else {
        resolved.add(event);
      }
    }
    return resolved;
  }

  @override
  Future<Result<List<EventModel>>> myClubEvents() async {
    try {
      final rows = await _client
          .from('events')
          .select(_eventSelect)
          .order('created_at', ascending: false);
      final mapped = (rows as List)
          .map((r) => _mapRow(r as Map<String, dynamic>))
          .toList();
      return Result.ok(await _resolvePosters(mapped));
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<OrganizerDashboardCounts>> dashboardCounts() async {
    final eventsResult = await myClubEvents();
    return eventsResult.when(
      ok: (events) => Result.ok(OrganizerDashboardCounts(
        totalEvents: events.length,
        pendingApprovals:
            events.where((e) => e.status == EventStatus.pendingApproval).length,
        published:
            events.where((e) => e.status == EventStatus.published).length,
        completed:
            events.where((e) => e.status == EventStatus.completed).length,
        totalRegistrations:
            0, // Summed lazily per-event via registrationsFor() in the UI.
        totalAttendees: 0,
      )),
      err: (f) => Result.err(f),
    );
  }

  @override
  Future<Result<EventModel>> saveDraft(DraftEventInput input) async {
    try {
      final uid = _client.auth.currentUser!.id;
      final clubId = await _callerClubId();
      if (clubId == null) {
        return Result.err(const AuthorizationFailure(
            'You are not a verified organizer for any club.'));
      }
      final payload = {
        'club_id': clubId,
        'category_id': input.categoryId,
        'title': input.title,
        'short_description': input.shortDescription,
        'full_description': input.fullDescription,
        'poster_path': input.posterPath,
        'venue': input.venue,
        'start_at': input.startAt.toIso8601String(),
        'end_at': input.endAt.toIso8601String(),
        'registration_deadline': input.registrationDeadline.toIso8601String(),
        'eligibility': input.eligibility,
        'rules': input.rules,
        'fee_text': input.feeText,
        'contact_name': input.contactName,
        'contact_email': input.contactEmail,
        'contact_phone': input.contactPhone,
        'created_by': uid,
        'status': 'draft',
      };
      final row = input.id == null
          ? await _client
              .from('events')
              .insert(payload)
              .select(_eventSelect)
              .single()
          : await _client
              .from('events')
              .update(payload)
              .eq('id', input.id!)
              .select(_eventSelect)
              .single();
      final resolved = await _resolvePosters([_mapRow(row)]);
      return Result.ok(resolved.first);
    } catch (e) {
      return Result.err(
          mapExceptionToFailure(e, fallbackMessage: 'Could not save draft.'));
    }
  }

  @override
  Future<Result<void>> submitForApproval(String eventId) async {
    try {
      await _client
          .rpc('submit_event_for_approval', params: {'p_event_id': eventId});
      return Result.ok(null);
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteEvent(String eventId) async {
    try {
      final clubId = await _callerClubId();
      if (clubId == null) {
        return Result.err(const AuthorizationFailure(
            'You are not a verified organizer for any club.'));
      }
      // Note: This relies on the 'events_delete_organizer' RLS policy
      // which safely enforces club ownership and status restrictions.
      final rows = await _client.from('events').delete().eq('id', eventId).select('id');
      if (rows.isEmpty) {
        return Result.err(const AuthorizationFailure('Event could not be deleted. It may be locked or you lack permission.'));
      }
      return Result.ok(null);
    } catch (e) {
      return Result.err(
          mapExceptionToFailure(e, fallbackMessage: 'Could not delete event.'));
    }
  }

  @override
  Future<Result<List<RegistrationRow>>> registrationsFor(String eventId) async {
    try {
      final rows = await _client
          .from('enrolments')
          .select('user_id, attendance_status, profiles(full_name)')
          .eq('event_id', eventId);
      return Result.ok((rows as List)
          .map((r) => RegistrationRow(
                userId: r['user_id'] as String,
                studentName: (r['profiles']?['full_name'] as String?) ?? '',
                attendanceStatus:
                    AttendanceStatusX.fromDb(r['attendance_status'] as String),
              ))
          .toList());
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ScanOutcome>> scanAttendance(
      {required String eventId, required String qrToken}) async {
    try {
      final code = await _client.rpc('mark_event_attendance', params: {
        'p_qr_token': qrToken,
        'p_event_id': eventId,
      });
      return Result.ok(ScanResultMapper.fromBackendCode(code as String));
    } catch (e) {
      return Result.err(
          mapExceptionToFailure(e, fallbackMessage: 'Scan failed.'));
    }
  }

  @override
  Future<Result<void>> markEventCompleted(String eventId) async {
    try {
      await _client
          .from('events')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', eventId)
          .select('id')
          .single();
      return Result.ok(null);
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<int>> issueCertificates(String eventId) async {
    try {
      final response = await _client.functions
          .invoke('issue-certificates', body: {'event_id': eventId});
      final results = (response.data as Map)['results'] as List? ?? [];
      final issued = results.where((r) => r['status'] == 'issued').length;
      return Result.ok(issued);
    } catch (e) {
      return Result.err(
          const CertificateFailure('Could not issue certificates.'));
    }
  }

  @override
  Future<Result<String>> uploadPoster(
      {required List<int> bytes, required String fileExtension}) async {
    try {
      // Path convention matches the `event_posters_organizer_write`
      // storage policy, which checks `(storage.foldername(name))[1]` is
      // a club the caller is a verified organizer for.
      final clubId = await _callerClubId();
      if (clubId == null) {
        return Result.err(const AuthorizationFailure(
            'You are not a verified organizer for any club.'));
      }
      final path =
          '$clubId/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      await _client.storage.from('event-posters').uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions:
                FileOptions(contentType: 'image/$fileExtension', upsert: true),
          );
      return Result.ok(path);
    } catch (e) {
      return Result.err(StorageFailure('Could not upload the poster.', e));
    }
  }

  Future<String?> _callerClubId() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await _client
        .from('club_members')
        .select('club_id')
        .eq('user_id', uid)
        .eq('is_verified', true)
        .limit(1)
        .maybeSingle();
    return row?['club_id'] as String?;
  }
}
