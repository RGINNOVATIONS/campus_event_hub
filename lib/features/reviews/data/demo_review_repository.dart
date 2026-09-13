import 'package:campus_event_hub/core/demo/demo_data_store.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/core/errors/app_failure.dart';
import 'package:campus_event_hub/core/result/result.dart';
import 'package:campus_event_hub/features/reviews/domain/review.dart';
import 'package:campus_event_hub/features/reviews/domain/review_repository.dart';

class DemoReviewRepository implements ReviewRepository {
  final DemoDataStore _store = DemoDataStore.instance;

  String get _uid => _store.currentUserId ?? 'demo-student-1';

  @override
  Future<Result<ReviewModel>> submitReview({
    required String eventId,
    required int rating,
    required String comment,
  }) async {
    final uid = _uid;

    if (rating < 1 || rating > 5) {
      return Result.err(
          const ValidationFailure('Rating must be between 1 and 5.'));
    }

    if (comment.length > 1000) {
      return Result.err(const ValidationFailure(
          'Comment cannot exceed 1000 characters.'));
    }

    final event = _store.eventById(eventId);
    if (event == null) {
      return Result.err(const UnknownFailure('Event not found.'));
    }

    if (event.status == EventStatus.draft ||
        event.status == EventStatus.pendingApproval ||
        event.status == EventStatus.rejected ||
        event.status == EventStatus.cancelled) {
      return Result.err(const ValidationFailure(
          'Reviews cannot be submitted for this event.'));
    }

    final isEnded = event.endAt.isBefore(DateTime.now()) ||
        event.status == EventStatus.completed;
    if (!isEnded) {
      return Result.err(const ValidationFailure(
          'Reviews are only open after the event has ended.'));
    }

    // Attendance check
    final regs = _store.registrationsByEvent[eventId] ?? [];
    final userReg = regs.where((r) => r.userId == uid).firstOrNull;

    if (userReg == null) {
      return Result.err(
          const ValidationFailure('You are not enrolled in this event.'));
    }

    if (userReg.attendanceStatus != AttendanceStatus.attended) {
      return Result.err(const ValidationFailure(
          'Only students who attended this event can submit a review.'));
    }

    // Idempotent upsert
    final existingList = _store.reviewsByEvent.putIfAbsent(eventId, () => []);
    final idx = existingList.indexWhere((r) => r.userId == uid);

    final ReviewModel savedReview;
    final now = DateTime.now();

    if (idx != -1) {
      final old = existingList[idx];
      savedReview = old.copyWith(
        rating: rating,
        comment: comment.trim(),
        updatedAt: now,
        studentName: userReg.studentName,
      );
      existingList[idx] = savedReview;
    } else {
      savedReview = ReviewModel(
        id: 'rev-${now.millisecondsSinceEpoch}',
        eventId: eventId,
        userId: uid,
        rating: rating,
        comment: comment.trim(),
        createdAt: now,
        updatedAt: now,
        studentName: userReg.studentName,
      );
      existingList.add(savedReview);
    }

    return Result.ok(savedReview);
  }

  @override
  Future<Result<List<ReviewModel>>> myReviews() async {
    final uid = _uid;
    final my = <ReviewModel>[];
    for (final list in _store.reviewsByEvent.values) {
      for (final r in list) {
        if (r.userId == uid) my.add(r);
      }
    }
    my.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Result.ok(my);
  }

  @override
  Future<Result<ReviewModel?>> myReviewForEvent(String eventId) async {
    final uid = _uid;
    final list = _store.reviewsByEvent[eventId] ?? [];
    final review = list.where((r) => r.userId == uid).firstOrNull;
    return Result.ok(review);
  }

  @override
  Future<Result<EventFeedbackSummary>> eventFeedbackSummary(
      String eventId) async {
    final list = _store.reviewsByEvent[eventId] ?? [];
    return Result.ok(EventFeedbackSummary.fromReviews(
      eventId: eventId,
      reviews: list,
    ));
  }
}
