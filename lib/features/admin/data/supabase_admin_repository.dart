import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/core/errors/app_failure.dart';
import 'package:campus_event_hub/core/result/result.dart';
import 'package:campus_event_hub/features/admin/domain/admin_repository.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAdminRepository implements AdminRepository {
  final SupabaseClient _client;
  SupabaseAdminRepository(this._client);

  static const _eventSelect =
      'id, club_id, category_id, title, short_description, full_description, poster_path, '
      'venue, start_at, end_at, registration_deadline, eligibility, rules, fee_text, '
      'contact_name, contact_email, contact_phone, status, rejection_reason, '
      'clubs!club_id(name), categories!category_id(name)';

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
          event.posterPath!.trim().isNotEmpty &&
          !event.posterPath!.startsWith('http')) {
        final cleanPath = event.posterPath!.startsWith('/')
            ? event.posterPath!.substring(1)
            : event.posterPath!;
        try {
          final url = await _client.storage
              .from('event-posters')
              .createSignedUrl(cleanPath, 60 * 60 * 24 * 7);
          resolved.add(event.copyWith(posterPath: url));
        } catch (_) {
          try {
            final publicUrl =
                _client.storage.from('event-posters').getPublicUrl(cleanPath);
            resolved.add(event.copyWith(posterPath: publicUrl));
          } catch (_) {
            resolved.add(event.copyWith(posterPath: null));
          }
        }
      } else {
        resolved.add(event);
      }
    }
    return resolved;
  }

  @override
  Future<Result<AdminDashboardCounts>> dashboardCounts() async {
    try {
      final pending = await _client
          .from('events')
          .select('id')
          .eq('status', 'pending_approval')
          .count();
      final published = await _client
          .from('events')
          .select('id')
          .eq('status', 'published')
          .count();
      final verifiedClubs = await _client
          .from('clubs')
          .select('id')
          .eq('verification_status', 'verified')
          .count();
      final students = await _client
          .from('profiles')
          .select('id')
          .eq('role', 'student')
          .count();
      return Result.ok(AdminDashboardCounts(
        pendingEvents: pending.count,
        publishedEvents: published.count,
        verifiedClubs: verifiedClubs.count,
        totalStudents: students.count,
      ));
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<EventModel>>> pendingEvents() async {
    try {
      final rows = await _client
          .from('events')
          .select(_eventSelect)
          .eq('status', 'pending_approval');
      final mapped = (rows as List)
          .map((r) => _mapRow(r as Map<String, dynamic>))
          .toList();
      return Result.ok(await _resolvePosters(mapped));
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<EventModel>>> allEventsForCalendar() async {
    try {
      final rows = await _client
          .from('events')
          .select(_eventSelect)
          .eq('status', 'published')
          .order('start_at');
      final mapped = (rows as List)
          .map((r) => _mapRow(r as Map<String, dynamic>))
          .toList();
      return Result.ok(await _resolvePosters(mapped));
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> approveEvent(String eventId) async {
    try {
      await _client
          .rpc('approve_event_by_admin', params: {'p_event_id': eventId});
      return Result.ok(null);
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> rejectEvent(String eventId, String reason) async {
    try {
      await _client.rpc('reject_event_by_admin', params: {
        'p_event_id': eventId,
        'p_rejection_reason': reason,
      });
      return Result.ok(null);
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> cancelEvent(String eventId) async {
    try {
      final rows = await _client
          .from('events')
          .update({'status': 'cancelled'})
          .eq('id', eventId)
          .select('id');
      if ((rows as List).isEmpty) {
        return Result.err(const AuthorizationFailure(
            'Event not found or not authorized to cancel.'));
      }
      return Result.ok(null);
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<ClubModel>>> clubs() async {
    try {
      final rows = await _client.from('clubs').select();
      return Result.ok((rows as List)
          .map((r) => ClubModel(
                id: r['id'] as String,
                name: r['name'] as String,
                description: r['description'] as String? ?? '',
                contactEmail: r['contact_email'] as String,
                status: ClubStatusX.fromDb(r['verification_status'] as String),
              ))
          .toList());
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> verifyClub(String clubId) async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) {
        return Result.err(const AuthFailure('User not authenticated.'));
      }
      final rows = await _client
          .from('clubs')
          .update({
            'verification_status': 'verified',
            'verified_by': uid,
            'verified_at': DateTime.now().toIso8601String(),
          })
          .eq('id', clubId)
          .select('id');
      if ((rows as List).isEmpty) {
        return Result.err(const AuthorizationFailure(
            'Club not found or not authorized to verify.'));
      }
      return Result.ok(null);
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> rejectClub(String clubId) async {
    try {
      final rows = await _client
          .from('clubs')
          .update({'verification_status': 'rejected'})
          .eq('id', clubId)
          .select('id');
      if ((rows as List).isEmpty) {
        return Result.err(const AuthorizationFailure(
            'Club not found or not authorized to reject.'));
      }
      return Result.ok(null);
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<RegistrationRow>>> registrationsFor(String eventId) async {
    try {
      final rows = await _client
          .from('enrolments')
          .select('''
            user_id,
            attendance_status,
            attended_at,
            profiles!user_id(*)
          ''')
          .eq('event_id', eventId);

      return Result.ok((rows as List).map((r) {
        final profile = r['profiles'] as Map<String, dynamic>?;
        final studentId = (profile?['student_id'] ?? profile?['college_id'] ?? 'N/A') as String;
        final branchVal = (profile?['branch'] as String?)?.trim();
        final deptVal = (profile?['department'] as String?)?.trim();
        final branch = (branchVal != null && branchVal.isNotEmpty)
            ? branchVal
            : (deptVal != null && deptVal.isNotEmpty ? deptVal : 'N/A');

        return RegistrationRow(
          userId: r['user_id'] as String,
          studentName: (profile?['full_name'] as String?) ?? '',
          studentId: studentId,
          rollNo: (profile?['roll_no'] as String?) ?? 'N/A',
          programme: (profile?['programme'] as String?) ?? 'N/A',
          branch: branch,
          academicYear: (profile?['academic_year'] as String?) ?? 'N/A',
          collegeEmail: (profile?['college_email'] as String?) ?? 'N/A',
          registrationStatus: 'registered',
          attendanceStatus:
              AttendanceStatusX.fromDb(r['attendance_status'] as String),
          attendedAt: r['attended_at'] != null
              ? DateTime.tryParse(r['attended_at'] as String)
              : null,
        );
      }).toList());
    } catch (e) {
      return Result.err(mapExceptionToFailure(e,
          fallbackMessage: 'Could not load registrations.'));
    }
  }
}
