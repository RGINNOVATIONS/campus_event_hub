import 'package:campus_event_hub/core/result/result.dart';
import 'package:campus_event_hub/features/reviews/domain/review.dart';

abstract class ReviewRepository {
  Future<Result<ReviewModel>> submitReview({
    required String eventId,
    required int rating,
    required String comment,
  });

  Future<Result<List<ReviewModel>>> myReviews();

  Future<Result<ReviewModel?>> myReviewForEvent(String eventId);

  Future<Result<EventFeedbackSummary>> eventFeedbackSummary(String eventId);
}
