import 'package:campus_event_hub/core/demo/demo_data_store.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/features/organizer/data/demo_organizer_repository.dart';
import 'package:campus_event_hub/features/organizer/domain/organizer_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DemoDataStore store;
  late DemoOrganizerRepository repo;

  setUp(() {
    store = DemoDataStore.instance;
    repo = DemoOrganizerRepository();
  });

  group('DemoOrganizerRepository — Event Edit & Postpone', () {
    test('saveDraft creates a new event with poster path', () async {
      final now = DateTime.now();
      final start = now.add(const Duration(days: 10));
      final end = start.add(const Duration(hours: 3));
      final deadline = start.subtract(const Duration(days: 2));

      final result = await repo.saveDraft(DraftEventInput(
        categoryId: store.categories.first.id,
        title: 'New Hackathon 2026',
        shortDescription: 'Exciting hackathon',
        fullDescription: 'Detailed rules and tracks for hackathon',
        posterPath: 'demo-poster-123.jpg',
        venue: 'Auditorium 1',
        startAt: start,
        endAt: end,
        registrationDeadline: deadline,
        eligibility: 'All students',
        rules: 'Teams of 4',
        feeText: 'Free',
        contactName: 'Organizer Alex',
        contactEmail: 'alex@nmims.edu',
      ));

      expect(result.isOk, isTrue);
      final created = result.valueOrNull!;
      expect(created.title, equals('New Hackathon 2026'));
      expect(created.posterPath, equals('demo-poster-123.jpg'));
      expect(created.status, equals(EventStatus.draft));
      expect(store.events.any((e) => e.id == created.id), isTrue);
    });

    test('saveDraft updates existing event and replaces poster cleanly', () async {
      final existing = store.events.first;
      final newTitle = 'Updated ${existing.title}';
      const newPoster = 'demo-new-poster-456.jpg';

      final result = await repo.saveDraft(DraftEventInput(
        id: existing.id,
        categoryId: existing.categoryId,
        title: newTitle,
        shortDescription: existing.shortDescription,
        fullDescription: existing.fullDescription,
        posterPath: newPoster,
        venue: 'New Lab 301',
        startAt: existing.startAt,
        endAt: existing.endAt,
        registrationDeadline: existing.registrationDeadline,
        eligibility: existing.eligibility,
        rules: existing.rules,
        feeText: existing.feeText,
        contactName: existing.contactName,
        contactEmail: existing.contactEmail,
      ));

      expect(result.isOk, isTrue);
      final updated = result.valueOrNull!;
      expect(updated.id, equals(existing.id));
      expect(updated.title, equals(newTitle));
      expect(updated.posterPath, equals(newPoster));
      expect(updated.venue, equals('New Lab 301'));
      expect(updated.status, equals(existing.status)); // preserves status
    });

    test('postponeEvent updates dates, postponementReason, and sets status to postponed', () async {
      final event = store.events.first;
      final newStart = DateTime.now().add(const Duration(days: 20));
      final newEnd = newStart.add(const Duration(hours: 4));
      final newDeadline = newStart.subtract(const Duration(days: 3));
      const reason = 'Rescheduled due to semester exam schedule overlap.';

      final result = await repo.postponeEvent(
        eventId: event.id,
        startAt: newStart,
        endAt: newEnd,
        registrationDeadline: newDeadline,
        reason: reason,
      );

      expect(result.isOk, isTrue);
      final updated = store.eventById(event.id);
      expect(updated, isNotNull);
      expect(updated!.status, equals(EventStatus.postponed));
      expect(updated.startAt, equals(newStart));
      expect(updated.endAt, equals(newEnd));
      expect(updated.registrationDeadline, equals(newDeadline));
      expect(updated.postponementReason, equals(reason));
    });

    test('postponeEvent rejects invalid dates where deadline is after start', () async {
      final event = store.events.first;
      final newStart = DateTime.now().add(const Duration(days: 20));
      final newEnd = newStart.add(const Duration(hours: 4));
      final invalidDeadline = newStart.add(const Duration(days: 1)); // Invalid: after start

      final result = await repo.postponeEvent(
        eventId: event.id,
        startAt: newStart,
        endAt: newEnd,
        registrationDeadline: invalidDeadline,
        reason: 'Valid reason here',
      );

      expect(result.isErr, isTrue);
      final errMsg = result.when(ok: (_) => '', err: (f) => f.message);
      expect(errMsg, contains('deadline'));
    });
  });
}
