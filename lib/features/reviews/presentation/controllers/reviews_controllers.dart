import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/features/reviews/domain/review.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final myReviewsProvider = FutureProvider<List<ReviewModel>>((ref) async {
  final repo = ref.watch(reviewRepositoryProvider);
  final res = await repo.myReviews();
  return res.when(
    ok: (data) => data,
    err: (failure) => throw failure,
  );
});

final myReviewForEventProvider =
    FutureProvider.family<ReviewModel?, String>((ref, eventId) async {
  final repo = ref.watch(reviewRepositoryProvider);
  final res = await repo.myReviewForEvent(eventId);
  return res.when(
    ok: (data) => data,
    err: (failure) => throw failure,
  );
});

final eventFeedbackProvider =
    FutureProvider.family<EventFeedbackSummary, String>((ref, eventId) async {
  final repo = ref.watch(reviewRepositoryProvider);
  final res = await repo.eventFeedbackSummary(eventId);
  return res.when(
    ok: (data) => data,
    err: (failure) => throw failure,
  );
});
