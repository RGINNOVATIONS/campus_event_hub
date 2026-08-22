import 'package:flutter_test/flutter_test.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';

EventModel _event(
    {required EventStatus status, DateTime? deadline, DateTime? start}) {
  return EventModel(
    id: 'e1',
    clubId: 'c1',
    clubName: 'Robotics Club',
    categoryId: 'cat1',
    categoryName: 'Technical',
    title: 'RoboWars',
    shortDescription: 'short',
    fullDescription: 'full',
    venue: 'Auditorium',
    startAt: start ?? DateTime(2026, 9, 10),
    endAt: DateTime(2026, 9, 10, 18),
    registrationDeadline: deadline ?? DateTime(2026, 9, 5),
    eligibility: 'All years',
    rules: 'No rules',
    contactName: 'Organizer',
    contactEmail: 'organizer@nmims.edu.in',
    status: status,
  );
}

void main() {
  final now = DateTime(2026, 8, 1);

  group('EnrolmentEligibility.buttonStateFor', () {
    test('published, not enrolled, before deadline -> enroll', () {
      final state = EnrolmentEligibility.buttonStateFor(
          event: _event(status: EventStatus.published),
          isEnrolled: false,
          now: now);
      expect(state, EnrollButtonState.enroll);
    });

    test('already enrolled -> viewQr regardless of deadline', () {
      final state = EnrolmentEligibility.buttonStateFor(
          event: _event(status: EventStatus.published),
          isEnrolled: true,
          now: now);
      expect(state, EnrollButtonState.viewQr);
    });

    test('past deadline, not enrolled -> registrationClosed', () {
      final state = EnrolmentEligibility.buttonStateFor(
        event: _event(
            status: EventStatus.published, deadline: DateTime(2026, 7, 1)),
        isEnrolled: false,
        now: now,
      );
      expect(state, EnrollButtonState.registrationClosed);
    });

    test('cancelled event -> eventCancelled even if enrolled', () {
      final state = EnrolmentEligibility.buttonStateFor(
          event: _event(status: EventStatus.cancelled),
          isEnrolled: true,
          now: now);
      expect(state, EnrollButtonState.eventCancelled);
    });

    test('completed event -> completed', () {
      final state = EnrolmentEligibility.buttonStateFor(
          event: _event(status: EventStatus.completed),
          isEnrolled: false,
          now: now);
      expect(state, EnrollButtonState.completed);
    });
  });

  group('EnrolmentEligibility.canEnrol', () {
    test('draft event cannot be enrolled in', () {
      expect(
        EnrolmentEligibility.canEnrol(
            event: _event(status: EventStatus.draft), now: now),
        isFalse,
      );
    });

    test('published event before deadline can be enrolled in', () {
      expect(
        EnrolmentEligibility.canEnrol(
            event: _event(status: EventStatus.published), now: now),
        isTrue,
      );
    });

    test('postponed event before new deadline can be enrolled in', () {
      expect(
        EnrolmentEligibility.canEnrol(
            event: _event(status: EventStatus.postponed), now: now),
        isTrue,
      );
    });
  });
}
