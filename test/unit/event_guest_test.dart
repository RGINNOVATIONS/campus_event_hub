import 'package:flutter_test/flutter_test.dart';
import 'package:campus_event_hub/app/env.dart';
import 'package:campus_event_hub/core/demo/demo_data_store.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';
import 'package:campus_event_hub/features/organizer/data/demo_organizer_repository.dart';
import 'package:campus_event_hub/features/organizer/domain/organizer_repository.dart';

void main() {
  setUpAll(() async {
    await Env.load();
  });

  setUp(() {
    DemoDataStore.instance.resetForTests();
  });

  group('EventGuest Model', () {
    test('serializes to JSON correctly', () {
      const guest = EventGuest(
        name: 'Dr. Jane Doe',
        designation: 'Keynote Speaker',
        organization: 'MIT Media Lab',
      );

      final json = guest.toJson();
      expect(json, {
        'name': 'Dr. Jane Doe',
        'designation': 'Keynote Speaker',
        'organization': 'MIT Media Lab',
      });
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'name': 'Prof. Alan Turing',
        'designation': 'Chief Guest',
        'organization': 'Cambridge',
      };

      final guest = EventGuest.fromJson(json);
      expect(guest.name, 'Prof. Alan Turing');
      expect(guest.designation, 'Chief Guest');
      expect(guest.organization, 'Cambridge');
    });

    test('handles missing or null fields gracefully in fromJson', () {
      final json = <String, dynamic>{
        'name': 'Anonymous Guest',
      };

      final guest = EventGuest.fromJson(json);
      expect(guest.name, 'Anonymous Guest');
      expect(guest.designation, '');
      expect(guest.organization, '');
    });

    test('equality and hashCode work as expected', () {
      const g1 = EventGuest(name: 'A', designation: 'B', organization: 'C');
      const g2 = EventGuest(name: 'A', designation: 'B', organization: 'C');
      const g3 = EventGuest(name: 'X', designation: 'B', organization: 'C');

      expect(g1, equals(g2));
      expect(g1.hashCode, equals(g2.hashCode));
      expect(g1, isNot(equals(g3)));
    });

    test('copyWith updates fields correctly', () {
      const guest = EventGuest(name: 'A', designation: 'B', organization: 'C');
      final updated = guest.copyWith(designation: 'Updated Role');

      expect(updated.name, 'A');
      expect(updated.designation, 'Updated Role');
      expect(updated.organization, 'C');
    });
  });

  group('EventModel guests integration', () {
    test('evt-1 in DemoDataStore is seeded with 2 guests', () {
      final evt = DemoDataStore.instance.events.firstWhere((e) => e.id == 'evt-1');
      expect(evt.guests.length, 2);
      expect(evt.guests[0].name, 'Dr. Aris Thorne');
      expect(evt.guests[0].designation, 'Lead Robotics Researcher');
      expect(evt.guests[0].organization, 'Advanced Robotics Lab');
      expect(evt.guests[1].name, 'Elena Rostova');
    });

    test('EventModel defaults guests to empty list when absent', () {
      final now = DateTime.now();
      final event = EventModel(
        id: 'test-evt',
        clubId: 'club-1',
        clubName: 'Club 1',
        categoryId: 'cat-1',
        categoryName: 'Cat 1',
        title: 'Test Event',
        shortDescription: 'Short',
        fullDescription: 'Full',
        venue: 'Hall A',
        startAt: now,
        endAt: now.add(const Duration(hours: 2)),
        registrationDeadline: now,
        eligibility: 'All',
        rules: 'None',
        contactName: 'Admin',
        contactEmail: 'admin@test.com',
        status: EventStatus.draft,
      );

      expect(event.guests, isEmpty);
    });

    test('EventModel copyWith preserves and updates guests', () {
      final evt = DemoDataStore.instance.events.firstWhere((e) => e.id == 'evt-1');
      expect(evt.guests.length, 2);

      final withNewGuests = evt.copyWith(guests: const [
        EventGuest(name: 'Solo Guest', designation: 'Host', organization: 'Org'),
      ]);
      expect(withNewGuests.guests.length, 1);
      expect(withNewGuests.guests.first.name, 'Solo Guest');

      final preserved = evt.copyWith(title: 'New Title');
      expect(preserved.guests.length, 2);
      expect(preserved.title, 'New Title');
    });
  });

  group('DemoOrganizerRepository guests roundtrip', () {
    test('saves draft with guests and updates them', () async {
      final repo = DemoOrganizerRepository();
      final now = DateTime.now().add(const Duration(days: 2));

      final createResult = await repo.saveDraft(DraftEventInput(
        categoryId: 'cat-technical',
        title: 'AI Summit 2026',
        shortDescription: 'Exploring frontier models',
        fullDescription: 'Full description of the AI Summit',
        venue: 'Auditorium B',
        startAt: now.add(const Duration(days: 5)),
        endAt: now.add(const Duration(days: 5, hours: 4)),
        registrationDeadline: now.add(const Duration(days: 3)),
        eligibility: 'Open to all',
        rules: 'Standard conduct',
        contactName: 'Lead Organizer',
        contactEmail: 'lead@college.edu',
        guests: const [
          EventGuest(
            name: 'Dr. Geoffrey Hinton',
            designation: 'Professor Emeritus',
            organization: 'University of Toronto',
          ),
        ],
      ));

      expect(createResult.isOk, isTrue);
      final createdEvent = createResult.valueOrNull!;
      expect(createdEvent.guests.length, 1);
      expect(createdEvent.guests.first.name, 'Dr. Geoffrey Hinton');
      expect(createdEvent.guests.first.organization, 'University of Toronto');

      // Now edit the draft to add a second guest
      final updateResult = await repo.saveDraft(DraftEventInput(
        id: createdEvent.id,
        categoryId: 'cat-technical',
        title: 'AI Summit 2026 - Updated',
        shortDescription: 'Exploring frontier models',
        fullDescription: 'Full description of the AI Summit',
        venue: 'Auditorium B',
        startAt: now.add(const Duration(days: 5)),
        endAt: now.add(const Duration(days: 5, hours: 4)),
        registrationDeadline: now.add(const Duration(days: 3)),
        eligibility: 'Open to all',
        rules: 'Standard conduct',
        contactName: 'Lead Organizer',
        contactEmail: 'lead@college.edu',
        guests: const [
          EventGuest(
            name: 'Dr. Geoffrey Hinton',
            designation: 'Professor Emeritus',
            organization: 'University of Toronto',
          ),
          EventGuest(
            name: 'Dr. Yann LeCun',
            designation: 'Chief AI Scientist',
            organization: 'Meta AI',
          ),
        ],
      ));

      expect(updateResult.isOk, isTrue);
      final updatedEvent = updateResult.valueOrNull!;
      expect(updatedEvent.guests.length, 2);
      expect(updatedEvent.guests[1].name, 'Dr. Yann LeCun');

      // Verify the event in DemoDataStore is updated
      final inStore = DemoDataStore.instance.events.firstWhere((e) => e.id == createdEvent.id);
      expect(inStore.guests.length, 2);
      expect(inStore.guests[1].organization, 'Meta AI');
    });

    test('editing only the venue preserves the 2 guests', () async {
      final repo = DemoOrganizerRepository();
      final now = DateTime.now().add(const Duration(days: 2));

      // 1. Create an event with 2 guests
      final createResult = await repo.saveDraft(DraftEventInput(
        categoryId: 'cat-technical',
        title: 'Original Event',
        shortDescription: 'Short desc',
        fullDescription: 'Full desc',
        venue: 'Original Hall',
        startAt: now.add(const Duration(days: 5)),
        endAt: now.add(const Duration(days: 5, hours: 2)),
        registrationDeadline: now.add(const Duration(days: 3)),
        eligibility: 'All',
        rules: 'Standard',
        contactName: 'Organizer',
        contactEmail: 'org@college.edu',
        guests: const [
          EventGuest(name: 'Guest 1', designation: 'Role 1', organization: 'Org 1'),
          EventGuest(name: 'Guest 2', designation: 'Role 2', organization: 'Org 2'),
        ],
      ));

      expect(createResult.isOk, isTrue);
      final created = createResult.valueOrNull!;
      expect(created.guests.length, 2);
      expect(created.venue, 'Original Hall');

      // 2. Edit ONLY venue, passing the existing guests loaded from the event
      final updateResult = await repo.saveDraft(DraftEventInput(
        id: created.id,
        categoryId: created.categoryId,
        title: created.title,
        shortDescription: created.shortDescription,
        fullDescription: created.fullDescription,
        venue: 'Updated Hall 5',
        startAt: created.startAt,
        endAt: created.endAt,
        registrationDeadline: created.registrationDeadline,
        eligibility: created.eligibility,
        rules: created.rules,
        contactName: created.contactName,
        contactEmail: created.contactEmail,
        guests: created.guests, // Exactly what CreateEventScreen loads & re-passes
      ));

      expect(updateResult.isOk, isTrue);
      final updated = updateResult.valueOrNull!;
      expect(updated.venue, 'Updated Hall 5');
      expect(updated.guests.length, 2, reason: 'Guests must still be present');
      expect(updated.guests[0].name, 'Guest 1');
      expect(updated.guests[1].name, 'Guest 2');

      final inStore = DemoDataStore.instance.events.firstWhere((e) => e.id == created.id);
      expect(inStore.venue, 'Updated Hall 5');
      expect(inStore.guests.length, 2);
    });
  });
}
