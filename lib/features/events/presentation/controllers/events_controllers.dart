import 'package:campus_pulse/app/providers.dart';
import 'package:campus_pulse/features/events/domain/event.dart';
import 'package:campus_pulse/features/events/domain/event_repository.dart';
import 'package:campus_pulse/features/favourites/domain/favourite_toggle.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final upcomingEventsProvider =
    FutureProvider.autoDispose<List<EventModel>>((ref) async {
  final repo = ref.watch(eventRepositoryProvider);
  final result = await repo.upcomingPublishedEvents();
  return result.when(ok: (v) => v, err: (f) => throw f);
});

final categoriesProvider =
    FutureProvider.autoDispose<List<CategoryModel>>((ref) async {
  final repo = ref.watch(eventRepositoryProvider);
  final result = await repo.categories();
  return result.when(ok: (v) => v, err: (f) => throw f);
});

final eventByIdProvider =
    FutureProvider.autoDispose.family<EventModel, String>((ref, id) async {
  final repo = ref.watch(eventRepositoryProvider);
  final result = await repo.eventById(id);
  return result.when(ok: (v) => v, err: (f) => throw f);
});

/// Home-screen filter state: selected category id (null = all) and
/// whether the "Following" filter is active.
class FeedFilter {
  final String? categoryId;
  final bool followingOnly;
  const FeedFilter({this.categoryId, this.followingOnly = false});

  FeedFilter copyWith(
          {String? categoryId,
          bool clearCategory = false,
          bool? followingOnly}) =>
      FeedFilter(
        categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
        followingOnly: followingOnly ?? this.followingOnly,
      );
}

final feedFilterProvider =
    StateProvider.autoDispose<FeedFilter>((ref) => const FeedFilter());

class FavouritesController extends StateNotifier<AsyncValue<Set<String>>> {
  final Ref _ref;
  FavouritesController(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    final repo = _ref.read(eventRepositoryProvider);
    final result = await repo.favouriteEventIds();
    state = result.when(
      ok: (v) => AsyncValue.data(v),
      err: (f) => AsyncValue.error(f, StackTrace.current),
    );
  }

  Future<void> toggle(String eventId) async {
    final current = state.valueOrNull ?? {};
    final wasFavourite = current.contains(eventId);
    final optimistic = {...current};
    if (FavouriteToggle.optimisticNextState(wasFavourite)) {
      optimistic.add(eventId);
    } else {
      optimistic.remove(eventId);
    }
    state = AsyncValue.data(optimistic);

    final repo = _ref.read(eventRepositoryProvider);
    final result = wasFavourite
        ? await repo.removeFavourite(eventId)
        : await repo.addFavourite(eventId);
    result.when(
      ok: (_) {},
      err: (_) {
        // Roll back to the pre-tap state on failure.
        final rolledBack = {...optimistic};
        if (FavouriteToggle.rollback(wasFavourite)) {
          rolledBack.add(eventId);
        } else {
          rolledBack.remove(eventId);
        }
        state = AsyncValue.data(rolledBack);
      },
    );
  }
}

final favouritesProvider = StateNotifierProvider.autoDispose<
    FavouritesController,
    AsyncValue<Set<String>>>((ref) => FavouritesController(ref));

class EnrolmentsController
    extends StateNotifier<AsyncValue<Map<String, EnrolmentModel>>> {
  final Ref _ref;
  EnrolmentsController(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    final repo = _ref.read(eventRepositoryProvider);
    final result = await repo.myEnrolments();
    state = result.when(
      ok: (v) => AsyncValue.data(v),
      err: (f) => AsyncValue.error(f, StackTrace.current),
    );
  }

  Future<String?> enrol(String eventId) async {
    final repo = _ref.read(eventRepositoryProvider);
    final result = await repo.enrol(eventId);
    return result.when(
      ok: (enrolment) {
        final current = {...(state.valueOrNull ?? {})};
        current[eventId] = enrolment;
        state = AsyncValue.data(current);
        return null;
      },
      err: (f) => f.message,
    );
  }
}

final enrolmentsProvider = StateNotifierProvider.autoDispose<
        EnrolmentsController, AsyncValue<Map<String, EnrolmentModel>>>(
    (ref) => EnrolmentsController(ref));
