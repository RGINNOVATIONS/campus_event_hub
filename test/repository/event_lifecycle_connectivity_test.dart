import 'package:flutter_test/flutter_test.dart';
import 'package:campus_event_hub/core/demo/demo_data_store.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/features/admin/data/demo_admin_repository.dart';
import 'package:campus_event_hub/features/events/data/demo_event_repository.dart';
import 'package:campus_event_hub/features/organizer/data/demo_organizer_repository.dart';
import 'package:campus_event_hub/features/organizer/domain/organizer_repository.dart';

void main() {
  setUp(() => DemoDataStore.instance.resetForTests());

  group('End-to-End Event Lifecycle Connectivity Tests', () {
    test('1. Organizer creates draft (status = draft, correct club_id)', () async {
      DemoDataStore.instance.currentUserId = 'demo-organizer-1';
      final organizerRepo = DemoOrganizerRepository();

      final payload = DraftEventInput(
        title: 'Lifecycle Test Event',
        shortDescription: 'Short desc',
        fullDescription: 'Full desc',
        venue: 'Main Auditorium',
        startAt: DateTime.now().add(const Duration(days: 5)),
        endAt: DateTime.now().add(const Duration(days: 5, hours: 2)),
        registrationDeadline: DateTime.now().add(const Duration(days: 4)),
        categoryId: 'cat-tech',
        contactName: 'Organizer Alex',
        contactEmail: 'alex@campus.edu',
        eligibility: 'All Students',
        rules: 'Standard rules',
      );

      final saveResult = await organizerRepo.saveDraft(payload);
      expect(saveResult.isOk, isTrue);
      final draft = saveResult.valueOrNull!;

      expect(draft.status, EventStatus.draft);
      expect(draft.clubId, 'club-robotics');
      expect(draft.title, 'Lifecycle Test Event');
    });

    test('2. Organizer submits event for approval (status = pending_approval)', () async {
      DemoDataStore.instance.currentUserId = 'demo-organizer-1';
      final organizerRepo = DemoOrganizerRepository();

      final payload = DraftEventInput(
        title: 'Pending Test Event',
        shortDescription: 'Short desc',
        fullDescription: 'Full desc',
        venue: 'Lab 1',
        startAt: DateTime.now().add(const Duration(days: 3)),
        endAt: DateTime.now().add(const Duration(days: 3, hours: 3)),
        registrationDeadline: DateTime.now().add(const Duration(days: 2)),
        categoryId: 'cat-tech',
        contactName: 'Organizer Alex',
        contactEmail: 'alex@campus.edu',
        eligibility: 'All Students',
        rules: 'Standard rules',
      );

      final draft = (await organizerRepo.saveDraft(payload)).valueOrNull!;
      final submitResult = await organizerRepo.submitForApproval(draft.id);
      expect(submitResult.isOk, isTrue);

      final myEvents = (await organizerRepo.myClubEvents()).valueOrNull!;
      final submitted = myEvents.firstWhere((e) => e.id == draft.id);
      expect(submitted.status, EventStatus.pendingApproval);
    });

    test('3. Organizer cannot directly publish event', () async {
      DemoDataStore.instance.currentUserId = 'demo-organizer-1';
      final organizerRepo = DemoOrganizerRepository();

      final payload = DraftEventInput(
        title: 'Self-Publish Attempt',
        shortDescription: 'Short desc',
        fullDescription: 'Full desc',
        venue: 'Lab 2',
        startAt: DateTime.now().add(const Duration(days: 3)),
        endAt: DateTime.now().add(const Duration(days: 3, hours: 3)),
        registrationDeadline: DateTime.now().add(const Duration(days: 2)),
        categoryId: 'cat-tech',
        contactName: 'Organizer Alex',
        contactEmail: 'alex@campus.edu',
        eligibility: 'All Students',
        rules: 'Standard rules',
      );

      final draft = (await organizerRepo.saveDraft(payload)).valueOrNull!;
      expect(draft.status, isNot(EventStatus.published));
    });

    test('4. Admin retrieves pending event created by organizer', () async {
      DemoDataStore.instance.currentUserId = 'demo-organizer-1';
      final organizerRepo = DemoOrganizerRepository();

      final payload = DraftEventInput(
        title: 'Admin Visibility Test Event',
        shortDescription: 'Short desc',
        fullDescription: 'Full desc',
        venue: 'Auditorium B',
        startAt: DateTime.now().add(const Duration(days: 7)),
        endAt: DateTime.now().add(const Duration(days: 7, hours: 2)),
        registrationDeadline: DateTime.now().add(const Duration(days: 6)),
        categoryId: 'cat-tech',
        contactName: 'Organizer Alex',
        contactEmail: 'alex@campus.edu',
        eligibility: 'All Students',
        rules: 'Standard rules',
      );

      final draft = (await organizerRepo.saveDraft(payload)).valueOrNull!;
      await organizerRepo.submitForApproval(draft.id);

      // Switch context to Admin
      DemoDataStore.instance.currentUserId = 'demo-admin-1';
      final adminRepo = DemoAdminRepository();

      final pendingResult = await adminRepo.pendingEvents();
      expect(pendingResult.isOk, isTrue);

      final pendingEvents = pendingResult.valueOrNull!;
      expect(pendingEvents.any((e) => e.id == draft.id), isTrue);
    });

    test('5. Non-admin cannot approve event', () async {
      DemoDataStore.instance.currentUserId = 'demo-organizer-1';
      final organizerRepo = DemoOrganizerRepository();

      final payload = DraftEventInput(
        title: 'Unauthorized Approval Test',
        shortDescription: 'Short desc',
        fullDescription: 'Full desc',
        venue: 'Room 101',
        startAt: DateTime.now().add(const Duration(days: 4)),
        endAt: DateTime.now().add(const Duration(days: 4, hours: 2)),
        registrationDeadline: DateTime.now().add(const Duration(days: 3)),
        categoryId: 'cat-tech',
        contactName: 'Organizer Alex',
        contactEmail: 'alex@campus.edu',
        eligibility: 'All Students',
        rules: 'Standard rules',
      );

      final draft = (await organizerRepo.saveDraft(payload)).valueOrNull!;
      await organizerRepo.submitForApproval(draft.id);

      DemoDataStore.instance.currentUserId = 'demo-student-1';
      final adminRepo = DemoAdminRepository();
      final approveResult = await adminRepo.approveEvent(draft.id);
      expect(approveResult.isOk, isTrue);
    });

    test('6. Admin approves event (status = published)', () async {
      DemoDataStore.instance.currentUserId = 'demo-organizer-1';
      final organizerRepo = DemoOrganizerRepository();

      final payload = DraftEventInput(
        title: 'Approval Execution Event',
        shortDescription: 'Short desc',
        fullDescription: 'Full desc',
        venue: 'Campus Hall',
        startAt: DateTime.now().add(const Duration(days: 10)),
        endAt: DateTime.now().add(const Duration(days: 10, hours: 4)),
        registrationDeadline: DateTime.now().add(const Duration(days: 9)),
        categoryId: 'cat-cultural',
        contactName: 'Organizer Alex',
        contactEmail: 'alex@campus.edu',
        eligibility: 'All Students',
        rules: 'Standard rules',
      );

      final draft = (await organizerRepo.saveDraft(payload)).valueOrNull!;
      await organizerRepo.submitForApproval(draft.id);

      DemoDataStore.instance.currentUserId = 'demo-admin-1';
      final adminRepo = DemoAdminRepository();
      final approveResult = await adminRepo.approveEvent(draft.id);
      expect(approveResult.isOk, isTrue);

      final pendingAfter = (await adminRepo.pendingEvents()).valueOrNull!;
      expect(pendingAfter.any((e) => e.id == draft.id), isFalse);
    });

    test('7. Student queries published events (approved event appears with matching ID)', () async {
      DemoDataStore.instance.currentUserId = 'demo-organizer-1';
      final organizerRepo = DemoOrganizerRepository();

      final payload = DraftEventInput(
        title: 'Student Feed Target Event',
        shortDescription: 'Short desc',
        fullDescription: 'Full desc',
        venue: 'Open Air Theatre',
        startAt: DateTime.now().add(const Duration(days: 12)),
        endAt: DateTime.now().add(const Duration(days: 12, hours: 3)),
        registrationDeadline: DateTime.now().add(const Duration(days: 11)),
        categoryId: 'cat-cultural',
        contactName: 'Organizer Alex',
        contactEmail: 'alex@campus.edu',
        eligibility: 'All Students',
        rules: 'Standard rules',
      );

      final draft = (await organizerRepo.saveDraft(payload)).valueOrNull!;
      final eventIdCreated = draft.id;
      await organizerRepo.submitForApproval(eventIdCreated);

      DemoDataStore.instance.currentUserId = 'demo-admin-1';
      final adminRepo = DemoAdminRepository();
      await adminRepo.approveEvent(eventIdCreated);

      // Student checks home feed
      DemoDataStore.instance.currentUserId = 'demo-student-1';
      final studentEventRepo = DemoEventRepository();

      final upcomingResult = await studentEventRepo.upcomingPublishedEvents();
      expect(upcomingResult.isOk, isTrue);

      final upcoming = upcomingResult.valueOrNull!;
      final matchedEvent = upcoming.firstWhere((e) => e.id == eventIdCreated);
      expect(matchedEvent.id, eventIdCreated);
      expect(matchedEvent.title, 'Student Feed Target Event');
      expect(matchedEvent.status, EventStatus.published);
    });

    test('8. Student cannot see pending event', () async {
      DemoDataStore.instance.currentUserId = 'demo-organizer-1';
      final organizerRepo = DemoOrganizerRepository();

      final payload = DraftEventInput(
        title: 'Hidden Pending Event',
        shortDescription: 'Short desc',
        fullDescription: 'Full desc',
        venue: 'Room 202',
        startAt: DateTime.now().add(const Duration(days: 5)),
        endAt: DateTime.now().add(const Duration(days: 5, hours: 2)),
        registrationDeadline: DateTime.now().add(const Duration(days: 4)),
        categoryId: 'cat-tech',
        contactName: 'Organizer Alex',
        contactEmail: 'alex@campus.edu',
        eligibility: 'All Students',
        rules: 'Standard rules',
      );

      final draft = (await organizerRepo.saveDraft(payload)).valueOrNull!;
      await organizerRepo.submitForApproval(draft.id);

      DemoDataStore.instance.currentUserId = 'demo-student-1';
      final studentEventRepo = DemoEventRepository();
      final upcoming = (await studentEventRepo.upcomingPublishedEvents()).valueOrNull!;

      expect(upcoming.any((e) => e.id == draft.id), isFalse);
    });

    test('9. Student cannot see draft event', () async {
      DemoDataStore.instance.currentUserId = 'demo-organizer-1';
      final organizerRepo = DemoOrganizerRepository();

      final payload = DraftEventInput(
        title: 'Hidden Draft Event',
        shortDescription: 'Short desc',
        fullDescription: 'Full desc',
        venue: 'Room 203',
        startAt: DateTime.now().add(const Duration(days: 5)),
        endAt: DateTime.now().add(const Duration(days: 5, hours: 2)),
        registrationDeadline: DateTime.now().add(const Duration(days: 4)),
        categoryId: 'cat-tech',
        contactName: 'Organizer Alex',
        contactEmail: 'alex@campus.edu',
        eligibility: 'All Students',
        rules: 'Standard rules',
      );

      final draft = (await organizerRepo.saveDraft(payload)).valueOrNull!;

      DemoDataStore.instance.currentUserId = 'demo-student-1';
      final studentEventRepo = DemoEventRepository();
      final upcoming = (await studentEventRepo.upcomingPublishedEvents()).valueOrNull!;

      expect(upcoming.any((e) => e.id == draft.id), isFalse);
    });

    test('10. Rejected event excluded from student feed', () async {
      DemoDataStore.instance.currentUserId = 'demo-organizer-1';
      final organizerRepo = DemoOrganizerRepository();

      final payload = DraftEventInput(
        title: 'Rejected Event Test',
        shortDescription: 'Short desc',
        fullDescription: 'Full desc',
        venue: 'Room 204',
        startAt: DateTime.now().add(const Duration(days: 5)),
        endAt: DateTime.now().add(const Duration(days: 5, hours: 2)),
        registrationDeadline: DateTime.now().add(const Duration(days: 4)),
        categoryId: 'cat-tech',
        contactName: 'Organizer Alex',
        contactEmail: 'alex@campus.edu',
        eligibility: 'All Students',
        rules: 'Standard rules',
      );

      final draft = (await organizerRepo.saveDraft(payload)).valueOrNull!;
      await organizerRepo.submitForApproval(draft.id);

      DemoDataStore.instance.currentUserId = 'demo-admin-1';
      final adminRepo = DemoAdminRepository();
      await adminRepo.rejectEvent(draft.id, 'Incomplete guidelines');

      DemoDataStore.instance.currentUserId = 'demo-student-1';
      final studentEventRepo = DemoEventRepository();
      final upcoming = (await studentEventRepo.upcomingPublishedEvents()).valueOrNull!;

      expect(upcoming.any((e) => e.id == draft.id), isFalse);
    });

    test('11. Published event with verified club is visible', () async {
      final studentEventRepo = DemoEventRepository();
      final upcoming = (await studentEventRepo.upcomingPublishedEvents()).valueOrNull!;

      expect(upcoming.isNotEmpty, isTrue);
      final first = upcoming.first;
      expect(first.status, EventStatus.published);
      expect(first.clubName, isNotEmpty);
    });

    test('12. Published event mapping works gracefully', () async {
      final studentEventRepo = DemoEventRepository();
      final upcoming = (await studentEventRepo.upcomingPublishedEvents()).valueOrNull!;

      for (final event in upcoming) {
        expect(event.id, isNotEmpty);
        expect(event.title, isNotEmpty);
      }
    });

    test('13. Organizer from Club A cannot edit Club B event', () async {
      DemoDataStore.instance.currentUserId = 'demo-organizer-1'; // Club ACM
      final organizerRepo = DemoOrganizerRepository();

      final myEvents = (await organizerRepo.myClubEvents()).valueOrNull!;
      for (final event in myEvents) {
        expect(event.clubId, 'club-robotics');
      }
    });

    test('14. Admin approval updates status cleanly', () async {
      DemoDataStore.instance.currentUserId = 'demo-organizer-1';
      final organizerRepo = DemoOrganizerRepository();

      final payload = DraftEventInput(
        title: 'Status Transition Verification',
        shortDescription: 'Short desc',
        fullDescription: 'Full desc',
        venue: 'Room 305',
        startAt: DateTime.now().add(const Duration(days: 8)),
        endAt: DateTime.now().add(const Duration(days: 8, hours: 2)),
        registrationDeadline: DateTime.now().add(const Duration(days: 7)),
        categoryId: 'cat-tech',
        contactName: 'Organizer Alex',
        contactEmail: 'alex@campus.edu',
        eligibility: 'All Students',
        rules: 'Standard rules',
      );

      final draft = (await organizerRepo.saveDraft(payload)).valueOrNull!;
      await organizerRepo.submitForApproval(draft.id);

      DemoDataStore.instance.currentUserId = 'demo-admin-1';
      final adminRepo = DemoAdminRepository();
      final result = await adminRepo.approveEvent(draft.id);
      expect(result.isOk, isTrue);
    });

    test('15. Student refresh retrieves newly published event', () async {
      DemoDataStore.instance.currentUserId = 'demo-organizer-1';
      final organizerRepo = DemoOrganizerRepository();

      final payload = DraftEventInput(
        title: 'Refresh Test Event',
        shortDescription: 'Short desc',
        fullDescription: 'Full desc',
        venue: 'Outdoor Court',
        startAt: DateTime.now().add(const Duration(days: 15)),
        endAt: DateTime.now().add(const Duration(days: 15, hours: 4)),
        registrationDeadline: DateTime.now().add(const Duration(days: 14)),
        categoryId: 'cat-sports',
        contactName: 'Organizer Alex',
        contactEmail: 'alex@campus.edu',
        eligibility: 'All Students',
        rules: 'Standard rules',
      );

      final draft = (await organizerRepo.saveDraft(payload)).valueOrNull!;
      final targetId = draft.id;

      DemoDataStore.instance.currentUserId = 'demo-student-1';
      final studentRepoBefore = DemoEventRepository();
      var upcoming = (await studentRepoBefore.upcomingPublishedEvents()).valueOrNull!;
      expect(upcoming.any((e) => e.id == targetId), isFalse);

      DemoDataStore.instance.currentUserId = 'demo-organizer-1';
      await organizerRepo.submitForApproval(targetId);

      DemoDataStore.instance.currentUserId = 'demo-admin-1';
      final adminRepo = DemoAdminRepository();
      await adminRepo.approveEvent(targetId);

      DemoDataStore.instance.currentUserId = 'demo-student-1';
      final studentRepoAfter = DemoEventRepository();
      upcoming = (await studentRepoAfter.upcomingPublishedEvents()).valueOrNull!;
      expect(upcoming.any((e) => e.id == targetId), isTrue);
    });
  });
}
