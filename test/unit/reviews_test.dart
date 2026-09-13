import 'package:campus_event_hub/core/demo/demo_data_store.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/features/organizer/domain/organizer_repository.dart';
import 'package:campus_event_hub/features/reviews/data/demo_review_repository.dart';
import 'package:campus_event_hub/features/reviews/domain/review.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DemoDataStore store;
  late DemoReviewRepository repo;

  setUp(() {
    store = DemoDataStore.instance;
    store.resetForTests();
    repo = DemoReviewRepository();
  });

  group('Reviews Domain & Calculations', () {
    test('EventFeedbackSummary.empty returns zeroed stats', () {
      final summary = EventFeedbackSummary.empty('evt-test');
      expect(summary.eventId, 'evt-test');
      expect(summary.averageRating, 0.0);
      expect(summary.reviewCount, 0);
      expect(summary.ratingDistribution, {1: 0, 2: 0, 3: 0, 4: 0, 5: 0});
      expect(summary.reviews, isEmpty);
    });

    test('EventFeedbackSummary.fromReviews computes accurate stats and distribution', () {
      final reviews = [
        ReviewModel(
          id: '1',
          eventId: 'evt-1',
          userId: 'u1',
          rating: 5,
          comment: 'Outstanding!',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        ReviewModel(
          id: '2',
          eventId: 'evt-1',
          userId: 'u2',
          rating: 4,
          comment: 'Great session',
          createdAt: DateTime(2026, 1, 2),
          updatedAt: DateTime(2026, 1, 2),
        ),
        ReviewModel(
          id: '3',
          eventId: 'evt-1',
          userId: 'u3',
          rating: 5,
          comment: 'Loved it',
          createdAt: DateTime(2026, 1, 3),
          updatedAt: DateTime(2026, 1, 3),
        ),
      ];

      final summary =
          EventFeedbackSummary.fromReviews(eventId: 'evt-1', reviews: reviews);

      // (5 + 4 + 5) / 3 = 14 / 3 = 4.666... => 4.7
      expect(summary.averageRating, 4.7);
      expect(summary.reviewCount, 3);
      expect(summary.ratingDistribution, {1: 0, 2: 0, 3: 0, 4: 1, 5: 2});
      expect(summary.reviews.length, 3);
      // Newest first
      expect(summary.reviews.first.id, '3');
      expect(summary.reviews.last.id, '1');
    });
  });

  group('DemoReviewRepository Attendance-Gate Enforcement', () {
    test('attended student can submit and edit review (upsert)', () async {
      store.currentUserId = 'demo-student-1';

      // Submit review
      final res1 = await repo.submitReview(
        eventId: 'evt-past-hackathon',
        rating: 5,
        comment: 'Super fun hackathon!',
      );

      expect(res1.isOk, isTrue);
      final review1 = res1.valueOrNull!;
      expect(review1.rating, 5);
      expect(review1.comment, 'Super fun hackathon!');
      expect(review1.studentName, 'Aisha Sharma');

      // Edit the same review
      final res2 = await repo.submitReview(
        eventId: 'evt-past-hackathon',
        rating: 4,
        comment: 'Updated: Really fun hackathon with great food.',
      );

      expect(res2.isOk, isTrue);
      final review2 = res2.valueOrNull!;
      expect(review2.rating, 4);
      expect(review2.comment, 'Updated: Really fun hackathon with great food.');

      // Check summary reflects only 1 review from Aisha (no duplicate!)
      final summaryRes = await repo.eventFeedbackSummary('evt-past-hackathon');
      final summary = summaryRes.valueOrNull!;
      final aishaReviews =
          summary.reviews.where((r) => r.userId == 'demo-student-1').toList();
      expect(aishaReviews.length, 1);
      expect(aishaReviews.first.rating, 4);
    });

    test('enrolled student with registered status (NOT attended) is blocked',
        () async {
      store.currentUserId = 'demo-student-registered-only';
      // Enroll user in evt-past-hackathon but as 'registered' (absent)
      store.registrationsByEvent['evt-past-hackathon']!.add(
        const RegistrationRow(
          userId: 'demo-student-registered-only',
          studentName: 'Absent Student',
          attendanceStatus: AttendanceStatus.registered,
        ),
      );

      final res = await repo.submitReview(
        eventId: 'evt-past-hackathon',
        rating: 5,
        comment: 'I did not attend but want to rate',
      );

      expect(res.isErr, isTrue);
      expect(
        res.failureOrNull?.message,
        'Only students who attended this event can submit a review.',
      );
    });

    test('non-enrolled student is blocked', () async {
      store.currentUserId = 'random-stranger';

      final res = await repo.submitReview(
        eventId: 'evt-past-hackathon',
        rating: 5,
        comment: 'Not enrolled at all',
      );

      expect(res.isErr, isTrue);
      expect(
        res.failureOrNull?.message,
        'You are not enrolled in this event.',
      );
    });

    test('review on upcoming / active event that has NOT ended is blocked',
        () async {
      store.currentUserId = 'demo-student-1';

      // evt-1 is in the future and published
      final res = await repo.submitReview(
        eventId: 'evt-1',
        rating: 5,
        comment: 'Early review',
      );

      expect(res.isErr, isTrue);
      expect(
        res.failureOrNull?.message,
        'Reviews are only open after the event has ended.',
      );
    });

    test('invalid rating (< 1 or > 5) is rejected', () async {
      store.currentUserId = 'demo-student-1';

      final resZero = await repo.submitReview(
        eventId: 'evt-past-hackathon',
        rating: 0,
        comment: 'Zero star',
      );
      expect(resZero.isErr, isTrue);
      expect(resZero.failureOrNull?.message, 'Rating must be between 1 and 5.');

      final resSix = await repo.submitReview(
        eventId: 'evt-past-hackathon',
        rating: 6,
        comment: 'Six star',
      );
      expect(resSix.isErr, isTrue);
      expect(resSix.failureOrNull?.message, 'Rating must be between 1 and 5.');
    });

    test('comment exceeding 1000 characters is rejected', () async {
      store.currentUserId = 'demo-student-1';
      final longComment = 'a' * 1001;

      final res = await repo.submitReview(
        eventId: 'evt-past-hackathon',
        rating: 5,
        comment: longComment,
      );
      expect(res.isErr, isTrue);
      expect(res.failureOrNull?.message,
          'Comment cannot exceed 1000 characters.');
    });

    test('myReviewForEvent returns review when present, null when absent',
        () async {
      store.currentUserId = 'demo-student-1';

      final review = await repo.myReviewForEvent('evt-past-hackathon');
      expect(review.isOk, isTrue);
      expect(review.valueOrNull, isNotNull);
      expect(review.valueOrNull?.userId, 'demo-student-1');

      final noReview = await repo.myReviewForEvent('evt-1');
      expect(noReview.isOk, isTrue);
      expect(noReview.valueOrNull, isNull);
    });

    test('organizer sees seeded feedback summary for completed event', () async {
      final summaryRes = await repo.eventFeedbackSummary('evt-past-hackathon');
      expect(summaryRes.isOk, isTrue);
      final summary = summaryRes.valueOrNull!;

      expect(summary.reviewCount, 3);
      expect(summary.averageRating, greaterThanOrEqualTo(4.0));
      expect(summary.reviews.length, 3);
      expect(summary.reviews.any((r) => r.studentName == 'Aisha Sharma'), isTrue);
      expect(summary.reviews.any((r) => r.studentName == 'Karan Mehta'), isTrue);
      expect(summary.reviews.any((r) => r.studentName == 'Neha Joshi'), isTrue);
    });
  });
}
