import 'package:campus_event_hub/core/errors/app_failure.dart';
import 'package:campus_event_hub/core/result/result.dart';
import 'package:campus_event_hub/features/reviews/domain/review.dart';
import 'package:campus_event_hub/features/reviews/domain/review_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseReviewRepository implements ReviewRepository {
  final SupabaseClient _client;

  SupabaseReviewRepository(this._client);

  @override
  Future<Result<ReviewModel>> submitReview({
    required String eventId,
    required int rating,
    required String comment,
  }) async {
    try {
      final res = await _client.rpc('submit_event_review', params: {
        'p_event_id': eventId,
        'p_rating': rating,
        'p_comment': comment.trim(),
      });

      if (res is Map) {
        return Result.ok(ReviewModel.fromMap(Map<String, dynamic>.from(res)));
      }
      return Result.err(const UnknownFailure('Invalid response from server.'));
    } catch (e) {
      return Result.err(mapExceptionToFailure(e,
          fallbackMessage: 'Could not submit review.'));
    }
  }

  @override
  Future<Result<List<ReviewModel>>> myReviews() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return Result.ok(const []);
    try {
      final rows = await _client
          .from('reviews')
          .select('id, event_id, user_id, rating, comment, created_at, updated_at')
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      final list = (rows as List)
          .map((r) => ReviewModel.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList();
      return Result.ok(list);
    } catch (e) {
      return Result.err(mapExceptionToFailure(e,
          fallbackMessage: 'Could not load your reviews.'));
    }
  }

  @override
  Future<Result<ReviewModel?>> myReviewForEvent(String eventId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return Result.ok(null);
    try {
      final rows = await _client
          .from('reviews')
          .select('id, event_id, user_id, rating, comment, created_at, updated_at')
          .eq('event_id', eventId)
          .eq('user_id', uid)
          .limit(1);

      final list = rows as List;
      if (list.isEmpty) return Result.ok(null);
      return Result.ok(
          ReviewModel.fromMap(Map<String, dynamic>.from(list.first as Map)));
    } catch (e) {
      return Result.err(mapExceptionToFailure(e,
          fallbackMessage: 'Could not check your review.'));
    }
  }

  @override
  Future<Result<EventFeedbackSummary>> eventFeedbackSummary(
      String eventId) async {
    try {
      final rows = await _client
          .from('reviews')
          .select('''
            id,
            event_id,
            user_id,
            rating,
            comment,
            created_at,
            updated_at,
            profiles!user_id(full_name)
          ''')
          .eq('event_id', eventId);

      final reviews = (rows as List)
          .map((r) => ReviewModel.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList();

      return Result.ok(EventFeedbackSummary.fromReviews(
        eventId: eventId,
        reviews: reviews,
      ));
    } catch (e) {
      return Result.err(mapExceptionToFailure(e,
          fallbackMessage: 'Could not load feedback summary.'));
    }
  }
}
