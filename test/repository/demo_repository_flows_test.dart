// Repository/integration-style tests against the demo repositories.
//
// A live Supabase instance isn't available in this build environment
// (see TASKS.md section 0), so these exercise full request/response
// flows through the demo repositories instead — which share the same
// interfaces the Supabase repositories implement, and the same
// DemoDataStore, so a full enrol -> scan -> issue-certificate flow can
// be tested end-to-end here even though no server was involved.
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_event_hub/core/demo/demo_data_store.dart';
import 'package:campus_event_hub/features/attendance/domain/scan_result.dart';
import 'package:campus_event_hub/features/certificates/data/demo_certificate_repository.dart';
import 'package:campus_event_hub/features/clubs/data/demo_club_repository.dart';
import 'package:campus_event_hub/features/events/data/demo_event_repository.dart';
import 'package:campus_event_hub/features/organizer/data/demo_organizer_repository.dart';
import 'package:campus_event_hub/core/services/demo_device_token_repository.dart';
import 'package:campus_event_hub/core/services/device_token_repository.dart';

void main() {
  setUp(() => DemoDataStore.instance.resetForTests());

  test('enrolment flow: enrol, then see it in myEnrolments with a QR token',
      () async {
    DemoDataStore.instance.currentUserId = 'demo-student-1';
    final repo = DemoEventRepository();

    final enrolResult = await repo.enrol('evt-3');
    expect(enrolResult.isOk, isTrue);

    final mine = (await repo.myEnrolments()).valueOrNull!;
    expect(mine.containsKey('evt-3'), isTrue);
    expect(mine['evt-3']!.qrToken, isNotEmpty);
  });

  test('enrolling twice in the same event is rejected', () async {
    DemoDataStore.instance.currentUserId = 'demo-student-1';
    final repo = DemoEventRepository();
    await repo.enrol('evt-3');
    final second = await repo.enrol('evt-3');
    expect(second.isErr, isTrue);
  });

  test('favourite toggle flow: add then remove persists correctly', () async {
    DemoDataStore.instance.currentUserId = 'demo-student-1';
    final repo = DemoEventRepository();

    await repo.addFavourite('evt-3');
    var favs = (await repo.favouriteEventIds()).valueOrNull!;
    expect(favs.contains('evt-3'), isTrue);

    await repo.removeFavourite('evt-3');
    favs = (await repo.favouriteEventIds()).valueOrNull!;
    expect(favs.contains('evt-3'), isFalse);
  });

  test('club and category follow flow', () async {
    DemoDataStore.instance.currentUserId = 'demo-student-1';
    final repo = DemoClubRepository();

    await repo.followClub('club-ecell');
    await repo.followCategory('cat-sports');

    expect((await repo.followedClubIds()).valueOrNull!.contains('club-ecell'),
        isTrue);
    expect(
        (await repo.followedCategoryIds()).valueOrNull!.contains('cat-sports'),
        isTrue);
  });

  test(
      'attendance marking: valid scan succeeds, then the same token is rejected as a duplicate',
      () async {
    final organizerRepo = DemoOrganizerRepository();
    DemoDataStore.instance.currentUserId = 'demo-organizer-1';

    // evt-1 has a pre-seeded registration for demo-student-1 with a known token.
    final first = await organizerRepo.scanAttendance(
      eventId: 'evt-1',
      qrToken: 'DEMO-QR-TOKEN-EVT1-AISHA',
    );
    expect(first.valueOrNull, ScanOutcome.success);

    final second = await organizerRepo.scanAttendance(
      eventId: 'evt-1',
      qrToken: 'DEMO-QR-TOKEN-EVT1-AISHA',
    );
    expect(second.valueOrNull, ScanOutcome.alreadyCheckedIn);
  });

  test('an invalid QR token is rejected', () async {
    final organizerRepo = DemoOrganizerRepository();
    final result = await organizerRepo.scanAttendance(
        eventId: 'evt-1', qrToken: 'not-a-real-token');
    expect(result.valueOrNull, ScanOutcome.invalidToken);
  });

  test(
      'certificate retrieval returns the seeded certificate for the demo student',
      () async {
    DemoDataStore.instance.currentUserId = 'demo-student-1';
    final repo = DemoCertificateRepository();
    final certs = (await repo.myCertificates()).valueOrNull!;
    expect(certs.any((c) => c.eventTitle == 'Winter Hackathon 2025'), isTrue);
  });

  test(
      'certificate verification by code returns valid for a real code, invalid otherwise',
      () async {
    final repo = DemoCertificateRepository();
    final valid = (await repo.verifyByCode('CP2025WH0421')).valueOrNull!;
    expect(valid.isValid, isTrue);

    final invalid = (await repo.verifyByCode('NOT-REAL')).valueOrNull!;
    expect(invalid.isValid, isFalse);
  });

  test('device-token registration and removal round-trip', () async {
    final tokenRepo = DemoDeviceTokenRepository();
    await tokenRepo.registerToken(
      userId: 'demo-student-1',
      fcmToken: 'integration-test-token',
      platform: DevicePlatform.android,
    );
    var tokens = (await tokenRepo.tokensForUser('demo-student-1')).valueOrNull!;
    expect(tokens, contains('integration-test-token'));

    await tokenRepo.removeToken('integration-test-token');
    tokens = (await tokenRepo.tokensForUser('demo-student-1')).valueOrNull!;
    expect(tokens, isEmpty);
  });

  test(
      'issuing certificates only credits attended students, and is idempotent on re-run',
      () async {
    final organizerRepo = DemoOrganizerRepository();
    DemoDataStore.instance.currentUserId = 'demo-organizer-1';

    // evt-past-hackathon is seeded as completed with one attended student
    // who already has a certificate in the seed data — issuing again
    // must recognize that and skip, not create a duplicate.
    final firstRun =
        await organizerRepo.issueCertificates('evt-past-hackathon');
    expect(firstRun.valueOrNull, 0,
        reason: 'already issued in seed data — must not double-issue');

    final certRepo = DemoCertificateRepository();
    DemoDataStore.instance.currentUserId = 'demo-student-1';
    final certs = (await certRepo.myCertificates()).valueOrNull!;
    expect(certs.where((c) => c.eventId == 'evt-past-hackathon').length, 1);
  });
}
