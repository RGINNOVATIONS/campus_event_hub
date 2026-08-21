import 'package:campus_pulse/core/domain/enums.dart';
import 'package:campus_pulse/core/errors/app_failure.dart';
import 'package:campus_pulse/core/result/result.dart';
import 'package:campus_pulse/features/events/domain/event.dart';
import 'package:campus_pulse/features/events/domain/event_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseEventRepository implements EventRepository {
  final SupabaseClient _client;
  SupabaseEventRepository(this._client);

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
              .createSignedUrl(event.posterPath!, 60 * 60 * 24 * 7); // 7 days
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
  Future<Result<List<EventModel>>> upcomingPublishedEvents() async {
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
      return Result.err(
          mapExceptionToFailure(e, fallbackMessage: 'Could not load events.'));
    }
  }

  @override
  Future<Result<List<CategoryModel>>> categories() async {
    try {
      final rows =
          await _client.from('categories').select().eq('is_active', true);
      return Result.ok((rows as List)
          .map((r) => CategoryModel(
                id: r['id'] as String,
                name: r['name'] as String,
                iconName: r['icon_name'] as String,
                colourHex: r['colour_hex'] as String,
              ))
          .toList());
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<EventModel>> eventById(String id) async {
    try {
      final row = await _client
          .from('events')
          .select(_eventSelect)
          .eq('id', id)
          .single();
      final resolved = await _resolvePosters([_mapRow(row)]);
      return Result.ok(resolved.first);
    } catch (e) {
      return Result.err(
          mapExceptionToFailure(e, fallbackMessage: 'Event not found.'));
    }
  }

  @override
  Future<Result<Set<String>>> favouriteEventIds() async {
    try {
      final uid = _client.auth.currentUser!.id;
      final rows = await _client
          .from('favourites')
          .select('event_id')
          .eq('user_id', uid);
      return Result.ok(
          (rows as List).map((r) => r['event_id'] as String).toSet());
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> addFavourite(String eventId) async {
    try {
      final uid = _client.auth.currentUser!.id;
      await _client
          .from('favourites')
          .insert({'user_id': uid, 'event_id': eventId});
      return Result.ok(null);
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> removeFavourite(String eventId) async {
    try {
      final uid = _client.auth.currentUser!.id;
      await _client
          .from('favourites')
          .delete()
          .eq('user_id', uid)
          .eq('event_id', eventId);
      return Result.ok(null);
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<Map<String, EnrolmentModel>>> myEnrolments() async {
    try {
      final uid = _client.auth.currentUser!.id;
      final rows = await _client
          .from('enrolments')
          .select('id, event_id, qr_token, attendance_status')
          .eq('user_id', uid);
      final map = <String, EnrolmentModel>{};
      for (final r in rows as List) {
        final m = EnrolmentModel(
          id: r['id'] as String,
          eventId: r['event_id'] as String,
          qrToken: r['qr_token'] as String,
          attendanceStatus:
              AttendanceStatusX.fromDb(r['attendance_status'] as String),
        );
        map[m.eventId] = m;
      }
      return Result.ok(map);
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<EnrolmentModel>> enrol(String eventId) async {
    try {
      // Calls the atomic, server-side enrol_in_event() Postgres function —
      // never inserts into `enrolments` directly from the client.
      final row = await _client
          .rpc('enrol_in_event', params: {'target_event_id': eventId});
      final map = row as Map<String, dynamic>;
      return Result.ok(EnrolmentModel(
        id: map['id'] as String,
        eventId: map['event_id'] as String,
        qrToken: map['qr_token'] as String,
        attendanceStatus:
            AttendanceStatusX.fromDb(map['attendance_status'] as String),
      ));
    } catch (e) {
      return Result.err(mapExceptionToFailure(e,
          fallbackMessage: 'Could not enrol in this event.'));
    }
  }
}
