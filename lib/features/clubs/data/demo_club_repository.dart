import 'package:campus_event_hub/core/demo/demo_data_store.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/core/errors/app_failure.dart';
import 'package:campus_event_hub/core/result/result.dart';
import 'package:campus_event_hub/features/clubs/domain/club_repository.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';

class DemoClubRepository implements ClubRepository {
  final DemoDataStore _store = DemoDataStore.instance;

  String get _uid => _store.currentUserId ?? 'demo-student-1';

  @override
  Future<Result<List<ClubModel>>> verifiedClubs() async => Result.ok(
      _store.clubs.where((c) => c.status == ClubStatus.verified).toList());

  @override
  Future<Result<ClubModel>> clubById(String id) async {
    for (final c in _store.clubs) {
      if (c.id == id) return Result.ok(c);
    }
    return Result.err(const UnknownFailure('Club not found.'));
  }

  @override
  Future<Result<List<EventModel>>> upcomingEventsForClub(String clubId) async {
    final events = _store.events
        .where((e) => e.clubId == clubId && e.status == EventStatus.published)
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    return Result.ok(events);
  }

  @override
  Future<Result<Set<String>>> followedClubIds() async =>
      Result.ok({...(_store.clubFollowsByUser[_uid] ?? {})});

  @override
  Future<Result<void>> followClub(String clubId) async {
    _store.clubFollowsByUser.putIfAbsent(_uid, () => {}).add(clubId);
    return Result.ok(null);
  }

  @override
  Future<Result<void>> unfollowClub(String clubId) async {
    _store.clubFollowsByUser[_uid]?.remove(clubId);
    return Result.ok(null);
  }

  @override
  Future<Result<Set<String>>> followedCategoryIds() async =>
      Result.ok({...(_store.categoryFollowsByUser[_uid] ?? {})});

  @override
  Future<Result<void>> followCategory(String categoryId) async {
    _store.categoryFollowsByUser.putIfAbsent(_uid, () => {}).add(categoryId);
    return Result.ok(null);
  }

  @override
  Future<Result<void>> unfollowCategory(String categoryId) async {
    _store.categoryFollowsByUser[_uid]?.remove(categoryId);
    return Result.ok(null);
  }
}
