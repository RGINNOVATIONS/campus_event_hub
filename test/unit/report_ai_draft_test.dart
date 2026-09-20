import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/core/errors/app_failure.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';
import 'package:campus_event_hub/features/reports/data/report_ai_service.dart';
import 'package:campus_event_hub/features/reports/domain/event_report_ai_content.dart';
import 'package:campus_event_hub/features/reports/domain/event_report_data.dart';
import 'package:campus_event_hub/features/reviews/domain/review.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventReportContent Domain Model', () {
    test('round-trip serialization toMap and fromMap', () {
      final now = DateTime(2026, 9, 19, 15, 30);
      final content = EventReportContent(
        eventId: 'evt-123',
        organizerNotes: 'Organizer raw notes here',
        objectives: '• Objective 1\n• Objective 2',
        outcomes: '• Outcome 1\n• Outcome 2',
        feedbackNarrative: 'Positive sentiment across attendees.',
        status: 'confirmed',
        createdBy: 'usr-org-1',
        confirmedBy: 'usr-org-1',
        confirmedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final map = content.toMap();
      expect(map['event_id'], 'evt-123');
      expect(map['organizer_notes'], 'Organizer raw notes here');
      expect(map['objectives'], '• Objective 1\n• Objective 2');
      expect(map['outcomes'], '• Outcome 1\n• Outcome 2');
      expect(map['feedback_narrative'], 'Positive sentiment across attendees.');
      expect(map['status'], 'confirmed');
      expect(map['created_by'], 'usr-org-1');
      expect(map['confirmed_by'], 'usr-org-1');
      expect(map['confirmed_at'], now.toIso8601String());

      final restored = EventReportContent.fromMap(map);
      expect(restored.eventId, content.eventId);
      expect(restored.organizerNotes, content.organizerNotes);
      expect(restored.objectives, content.objectives);
      expect(restored.outcomes, content.outcomes);
      expect(restored.feedbackNarrative, content.feedbackNarrative);
      expect(restored.status, 'confirmed');
      expect(restored.isConfirmed, isTrue);
      expect(restored.confirmedBy, 'usr-org-1');
      expect(restored.confirmedAt, now);
    });

    test('isConfirmed getter returns true only for status "confirmed"', () {
      const draft = EventReportContent(
        eventId: 'evt-1',
        status: 'draft',
      );
      expect(draft.isConfirmed, isFalse);

      const confirmed = EventReportContent(
        eventId: 'evt-1',
        status: 'confirmed',
      );
      expect(confirmed.isConfirmed, isTrue);
    });

    test('copyWith properly updates specific fields', () {
      const initial = EventReportContent(
        eventId: 'evt-1',
        objectives: 'Initial Obj',
        status: 'draft',
      );

      final updated = initial.copyWith(
        objectives: 'Updated Obj',
        status: 'confirmed',
      );

      expect(updated.eventId, 'evt-1');
      expect(updated.objectives, 'Updated Obj');
      expect(updated.status, 'confirmed');
      expect(updated.isConfirmed, isTrue);
    });
  });

  group('DemoReportAiService Tests', () {
    late DemoReportAiService service;

    setUp(() {
      DemoReportAiService.reset();
      service = DemoReportAiService();
    });

    test('draftObjectivesAndOutcomes rejects empty notes with ValidationFailure',
        () async {
      final res = await service.draftObjectivesAndOutcomes(
        eventId: 'evt-test',
        organizerNotes: '   ',
      );

      expect(res.isErr, isTrue);
      expect(res.failureOrNull, isA<ValidationFailure>());
      expect(res.failureOrNull!.message, contains('Organizer notes are required'));
    });

    test('draftObjectivesAndOutcomes generates grounded objectives and outcomes',
        () async {
      final res = await service.draftObjectivesAndOutcomes(
        eventId: 'evt-test',
        organizerNotes: 'Conducted a 24-hr robotic arms build workshop.',
        category: 'Workshop',
        registrationsCount: 40,
        attendanceCount: 30,
        attendancePercentage: 75.0,
      );

      expect(res.isOk, isTrue);
      final draft = res.valueOrNull!;
      expect(draft.objectives, contains('Conducted a 24-hr robotic arms build workshop.'));
      expect(draft.outcomes, contains('30 participating students'));
      expect(draft.outcomes, contains('75.0%'));
      expect(draft.rawText, contains('## Objectives'));
      expect(draft.rawText, contains('## Key Outcomes & Impact'));
    });

    test('draftFeedbackNarrative produces professional summary without PII',
        () async {
      final res = await service.draftFeedbackNarrative('evt-test');

      expect(res.isOk, isTrue);
      final narrative = res.valueOrNull!;
      expect(narrative, isNotEmpty);
      expect(narrative, contains('student feedback was overwhelmingly positive'));
      // Verify zero student names or personal identifiers exist in narrative
      expect(narrative.contains('@'), isFalse);
      expect(narrative.contains('Student One'), isFalse);
    });

    test('polishOrganizerNotes rejects empty notes with ValidationFailure',
        () async {
      final res = await service.polishOrganizerNotes(
        eventId: 'evt-test',
        organizerNotes: '   ',
      );

      expect(res.isErr, isTrue);
      expect(res.failureOrNull, isA<ValidationFailure>());
      expect(res.failureOrNull!.message, contains('Organizer notes are required to polish'));
    });

    test('polishOrganizerNotes cleans grammar and phrasing while preserving account facts',
        () async {
      final res = await service.polishOrganizerNotes(
        eventId: 'evt-test',
        organizerNotes: 'ran 4 mentoring rounds and 8 teams submitted prototypes',
      );

      expect(res.isOk, isTrue);
      final polished = res.valueOrNull!;
      expect(polished, contains('ran 4 mentoring rounds and 8 teams submitted prototypes'));
      expect(polished, contains('Successfully organized and executed'));
    });

    test('saveReportContent saves draft and confirmed states with attribution',
        () async {
      const draftContent = EventReportContent(
        eventId: 'evt-test',
        organizerNotes: 'My notes',
        objectives: 'Obj 1',
        outcomes: 'Out 1',
        status: 'draft',
      );

      final saveDraftRes =
          await service.saveReportContent('evt-test', draftContent);
      expect(saveDraftRes.isOk, isTrue);
      final savedDraft = saveDraftRes.valueOrNull!;
      expect(savedDraft.status, 'draft');
      expect(savedDraft.isConfirmed, isFalse);
      expect(savedDraft.confirmedBy, isNull);
      expect(savedDraft.confirmedAt, isNull);

      // Confirm as final
      final confirmRes = await service.saveReportContent(
        'evt-test',
        savedDraft.copyWith(status: 'confirmed'),
      );
      expect(confirmRes.isOk, isTrue);
      final confirmed = confirmRes.valueOrNull!;
      expect(confirmed.status, 'confirmed');
      expect(confirmed.isConfirmed, isTrue);
      expect(confirmed.confirmedBy, isNotNull);
      expect(confirmed.confirmedAt, isNotNull);

      // Verify retrieval
      final loadRes = await service.getReportContent('evt-test');
      expect(loadRes.isOk, isTrue);
      expect(loadRes.valueOrNull?.status, 'confirmed');
      expect(loadRes.valueOrNull?.objectives, 'Obj 1');
    });

    test('reverting confirmed report to draft clears confirmed attribution',
        () async {
      // First save confirmed
      const confirmedContent = EventReportContent(
        eventId: 'evt-test',
        objectives: 'Obj 1',
        outcomes: 'Out 1',
        status: 'confirmed',
      );
      final confirmed =
          (await service.saveReportContent('evt-test', confirmedContent))
              .valueOrNull!;
      expect(confirmed.isConfirmed, isTrue);

      // Organizer edits content -> status reverts to draft
      final editedDraft = confirmed.copyWith(
        objectives: 'Obj 1 (edited)',
        status: 'draft',
      );
      final savedEdit =
          (await service.saveReportContent('evt-test', editedDraft))
              .valueOrNull!;
      expect(savedEdit.status, 'draft');
      expect(savedEdit.isConfirmed, isFalse);
      expect(savedEdit.confirmedBy, isNull);
      expect(savedEdit.confirmedAt, isNull);
    });
  });

  group('EventReportData Integration with EventReportContent', () {
    test('EventReportAggregator attaches EventReportContent when supplied', () {
      final event = EventModel(
        id: 'evt-comp',
        clubId: 'club-1',
        clubName: 'Robotics Club',
        categoryId: 'cat-1',
        categoryName: 'Tech',
        title: 'Robotics Expo',
        shortDescription: 'Expo',
        fullDescription: 'Full Expo description',
        venue: 'Hall A',
        startAt: DateTime(2026, 3, 10, 10, 0),
        endAt: DateTime(2026, 3, 10, 16, 0),
        registrationDeadline: DateTime(2026, 3, 9),
        eligibility: 'All',
        rules: 'Rules',
        contactName: 'Jane Organizer',
        contactEmail: 'jane@college.edu',
        status: EventStatus.completed,
      );

      const feedback = EventFeedbackSummary(
        eventId: 'evt-comp',
        averageRating: 4.8,
        reviewCount: 5,
        ratingDistribution: {5: 4, 4: 1},
        reviews: [],
      );

      const content = EventReportContent(
        eventId: 'evt-comp',
        objectives: '• Showcase robotics innovations.',
        outcomes: '• 15 working robot demonstrations completed.',
        status: 'confirmed',
      );

      final report = EventReportAggregator.aggregate(
        event: event,
        registrations: [],
        feedback: feedback,
        content: content,
      );

      expect(report.content, isNotNull);
      expect(report.content!.objectives, contains('Showcase robotics'));
      expect(report.content!.outcomes, contains('15 working robot'));
      expect(report.content!.isConfirmed, isTrue);
      // Feedback remains single source of truth
      expect(report.feedback.averageRating, 4.8);
      expect(report.feedback.reviewCount, 5);
    });
  });
}
