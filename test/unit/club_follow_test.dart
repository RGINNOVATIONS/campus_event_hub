import 'package:flutter_test/flutter_test.dart';
import '../fakes/fakes.dart';
import 'package:campus_event_hub/core/domain/enums.dart';

void main() {
  setUp(() => FakeDataStore.instance.resetForTests());

  group('FakeClubRepository — club following', () {
    test('verifiedClubs only returns verified clubs (pending club excluded)',
        () async {
      final repo = FakeClubRepository();
      final result = await repo.verifiedClubs();
      final clubs = result.valueOrNull!;
      expect(clubs.every((c) => c.status == ClubStatus.verified), isTrue);
      expect(clubs.any((c) => c.name == 'Photography Society'), isFalse);
    });

    test('follow then unfollow round-trips cleanly', () async {
      final repo = FakeClubRepository();
      FakeDataStore.instance.currentUserId = 'demo-student-1';

      await repo.followClub('club-ecell');
      var followed = (await repo.followedClubIds()).valueOrNull!;
      expect(followed.contains('club-ecell'), isTrue);

      await repo.unfollowClub('club-ecell');
      followed = (await repo.followedClubIds()).valueOrNull!;
      expect(followed.contains('club-ecell'), isFalse);
    });

    test('following the same club twice enforces one record (set semantics)',
        () async {
      final repo = FakeClubRepository();
      FakeDataStore.instance.currentUserId = 'demo-student-1';

      await repo.followClub('club-ecell');
      await repo.followClub('club-ecell');
      final followed = (await repo.followedClubIds()).valueOrNull!;
      expect(followed.where((id) => id == 'club-ecell').length, 1);
    });

    test('club details expose upcoming published events only', () async {
      final repo = FakeClubRepository();
      final events =
          (await repo.upcomingEventsForClub('club-robotics')).valueOrNull!;
      expect(events.every((e) => e.status.name == 'published'), isTrue);
      expect(events.any((e) => e.title == 'RoboWars 2026'), isTrue);
    });
  });

  group('FakeClubRepository — category following', () {
    test('follow then unfollow a category round-trips', () async {
      final repo = FakeClubRepository();
      FakeDataStore.instance.currentUserId = 'demo-student-1';

      await repo.followCategory('cat-sports');
      var followed = (await repo.followedCategoryIds()).valueOrNull!;
      expect(followed.contains('cat-sports'), isTrue);

      await repo.unfollowCategory('cat-sports');
      followed = (await repo.followedCategoryIds()).valueOrNull!;
      expect(followed.contains('cat-sports'), isFalse);
    });
  });
}
