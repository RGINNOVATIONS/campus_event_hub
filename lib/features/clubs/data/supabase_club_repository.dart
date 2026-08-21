import 'package:campus_pulse/core/domain/enums.dart';
import 'package:campus_pulse/core/errors/app_failure.dart';
import 'package:campus_pulse/core/result/result.dart';
import 'package:campus_pulse/features/clubs/domain/club_repository.dart';
import 'package:campus_pulse/features/events/domain/event.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClubRepository implements ClubRepository {
  final SupabaseClient _client;
  SupabaseClubRepository(this._client);

  ClubModel _mapClub(Map<String, dynamic> r) => ClubModel(
        id: r['id'] as String,
        name: r['name'] as String,
        description: r['description'] as String? ?? '',
        logoPath: r['logo_path'] as String?,
        contactEmail: r['contact_email'] as String,
        status: ClubStatusX.fromDb(r['verification_status'] as String),
      );

  static const _eventSelect =
      'id, club_id, category_id, title, short_description, full_description, poster_path, '
      'venue, start_at, end_at, registration_deadline, eligibility, rules, fee_text, '
      'contact_name, contact_email, contact_phone, status, rejection_reason, '
      'clubs(name), categories(name)';

  EventModel _mapEvent(Map<String, dynamic> row) => EventModel(
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

  @override
  Future<Result<List<ClubModel>>> verifiedClubs() async {
    try {
      final rows = await _client
          .from('clubs')
          .select()
          .eq('verification_status', 'verified');
      return Result.ok((rows as List)
          .map((r) => _mapClub(r as Map<String, dynamic>))
          .toList());
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ClubModel>> clubById(String id) async {
    try {
      final row = await _client.from('clubs').select().eq('id', id).single();
      return Result.ok(_mapClub(row));
    } catch (e) {
      return Result.err(
          mapExceptionToFailure(e, fallbackMessage: 'Club not found.'));
    }
  }

  @override
  Future<Result<List<EventModel>>> upcomingEventsForClub(String clubId) async {
    try {
      final rows = await _client
          .from('events')
          .select(_eventSelect)
          .eq('club_id', clubId)
          .eq('status', 'published')
          .order('start_at');
      return Result.ok((rows as List)
          .map((r) => _mapEvent(r as Map<String, dynamic>))
          .toList());
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<Set<String>>> followedClubIds() async {
    try {
      final uid = _client.auth.currentUser!.id;
      final rows = await _client
          .from('club_follows')
          .select('club_id')
          .eq('user_id', uid);
      return Result.ok(
          (rows as List).map((r) => r['club_id'] as String).toSet());
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> followClub(String clubId) async {
    try {
      final uid = _client.auth.currentUser!.id;
      await _client
          .from('club_follows')
          .insert({'user_id': uid, 'club_id': clubId});
      return Result.ok(null);
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> unfollowClub(String clubId) async {
    try {
      final uid = _client.auth.currentUser!.id;
      await _client
          .from('club_follows')
          .delete()
          .eq('user_id', uid)
          .eq('club_id', clubId);
      return Result.ok(null);
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<Set<String>>> followedCategoryIds() async {
    try {
      final uid = _client.auth.currentUser!.id;
      final rows = await _client
          .from('category_follows')
          .select('category_id')
          .eq('user_id', uid);
      return Result.ok(
          (rows as List).map((r) => r['category_id'] as String).toSet());
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> followCategory(String categoryId) async {
    try {
      final uid = _client.auth.currentUser!.id;
      await _client
          .from('category_follows')
          .insert({'user_id': uid, 'category_id': categoryId});
      return Result.ok(null);
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> unfollowCategory(String categoryId) async {
    try {
      final uid = _client.auth.currentUser!.id;
      await _client
          .from('category_follows')
          .delete()
          .eq('user_id', uid)
          .eq('category_id', categoryId);
      return Result.ok(null);
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }
}
