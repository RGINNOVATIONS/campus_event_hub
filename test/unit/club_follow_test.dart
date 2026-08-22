import 'package:flutter_test/flutter_test.dart';
import 'package:campus_event_hub/core/demo/demo_data_store.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/features/clubs/data/demo_club_repository.dart';

void main() {
  setUp(() => DemoDataStore.instance.resetForTests());

  group('DemoClubRepository — club following', () {
    test('verifiedClubs only returns verified clubs (pending club excluded)',
        () async {
      final repo = DemoClubRepository();
      final result = await repo.verifiedClubs();
      final clubs = result.valueOrNull!;
      expect(clubs.every((c) => c.status == ClubStatus.verified), isTrue);
      expect(clubs.any((c) => c.name == 'Photography Society'), isFalse);
    });

    test('follow then unfollow round-trips cleanly', () async {
      final repo = DemoClubRepository();
      DemoDataStore.instance.currentUserId = 'demo-student-1';

      await repo.followClub('club-ecell');
      var followed = (await repo.followedClubIds()).valueOrNull!;
      expect(followed.contains('club-ecell'), isTrue);

      await repo.unfollowClub('club-ecell');
      followed = (await repo.followedClubIds()).valueOrNull!;
      expect(followed.contains('club-ecell'), isFalse);
    });

    test('following the same club twice enforces one record (set semantics)',
        () async {
      final repo = DemoClubRepository();
      DemoDataStore.instance.currentUserId = 'demo-student-1';

      await repo.followClub('club-ecell');
      await repo.followClub('club-ecell');
      final followed = (await repo.followedClubIds()).valueOrNull!;
      expect(followed.where((id) => id == 'club-ecell').length, 1);
    });

    test('club details expose upcoming published events only', () async {
      final repo = DemoClubRepository();
      final events =
          (await repo.upcomingEventsForClub('club-robotics')).valueOrNull!;
      expect(events.every((e) => e.status.name == 'published'), isTrue);
      expect(events.any((e) => e.title == 'RoboWars 2026'), isTrue);
    });
  });

  group('DemoClubRepository — category following', () {
    test('follow then unfollow a category round-trips', () async {
      final repo = DemoClubRepository();
      DemoDataStore.instance.currentUserId = 'demo-student-1';

      await repo.followCategory('cat-sports');
      var followed = (await repo.followedCategoryIds()).valueOrNull!;
      expect(followed.contains('cat-sports'), isTrue);

      await repo.unfollowCategory('cat-sports');
      followed = (await repo.followedCategoryIds()).valueOrNull!;
      expect(followed.contains('cat-sports'), isFalse);
    });
  });
}
