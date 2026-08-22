import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/features/clubs/domain/club_repository.dart';
import 'package:campus_event_hub/features/favourites/domain/favourite_toggle.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final verifiedClubsProvider =
    FutureProvider.autoDispose<List<ClubModel>>((ref) async {
  final repo = ref.watch(clubRepositoryProvider);
  final result = await repo.verifiedClubs();
  return result.when(ok: (v) => v, err: (f) => throw f);
});

final clubByIdProvider =
    FutureProvider.autoDispose.family<ClubModel, String>((ref, id) async {
  final repo = ref.watch(clubRepositoryProvider);
  final result = await repo.clubById(id);
  return result.when(ok: (v) => v, err: (f) => throw f);
});

final clubUpcomingEventsProvider =
    FutureProvider.autoDispose.family((ref, String clubId) async {
  final repo = ref.watch(clubRepositoryProvider);
  final result = await repo.upcomingEventsForClub(clubId);
  return result.when(ok: (v) => v, err: (f) => throw f);
});

class FollowedClubsController extends StateNotifier<AsyncValue<Set<String>>> {
  final Ref _ref;
  FollowedClubsController(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    final repo = _ref.read(clubRepositoryProvider);
    final result = await repo.followedClubIds();
    state = result.when(
      ok: (v) => AsyncValue.data(v),
      err: (f) => AsyncValue.error(f, StackTrace.current),
    );
  }

  Future<void> toggle(String clubId) async {
    final current = state.valueOrNull ?? {};
    final wasFollowing = current.contains(clubId);
    final optimistic = {...current};
    if (FavouriteToggle.optimisticNextState(wasFollowing)) {
      optimistic.add(clubId);
    } else {
      optimistic.remove(clubId);
    }
    state = AsyncValue.data(optimistic);

    final repo = _ref.read(clubRepositoryProvider);
    final result = wasFollowing
        ? await repo.unfollowClub(clubId)
        : await repo.followClub(clubId);
    result.when(
      ok: (_) {},
      err: (_) {
        final rolledBack = {...optimistic};
        if (FavouriteToggle.rollback(wasFollowing)) {
          rolledBack.add(clubId);
        } else {
          rolledBack.remove(clubId);
        }
        state = AsyncValue.data(rolledBack);
      },
    );
  }
}

final followedClubsProvider = StateNotifierProvider.autoDispose<
    FollowedClubsController,
    AsyncValue<Set<String>>>((ref) => FollowedClubsController(ref));

class FollowedCategoriesController
    extends StateNotifier<AsyncValue<Set<String>>> {
  final Ref _ref;
  FollowedCategoriesController(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    final repo = _ref.read(clubRepositoryProvider);
    final result = await repo.followedCategoryIds();
    state = result.when(
      ok: (v) => AsyncValue.data(v),
      err: (f) => AsyncValue.error(f, StackTrace.current),
    );
  }

  Future<void> toggle(String categoryId) async {
    final current = state.valueOrNull ?? {};
    final wasFollowing = current.contains(categoryId);
    final optimistic = {...current};
    if (FavouriteToggle.optimisticNextState(wasFollowing)) {
      optimistic.add(categoryId);
    } else {
      optimistic.remove(categoryId);
    }
    state = AsyncValue.data(optimistic);

    final repo = _ref.read(clubRepositoryProvider);
    final result = wasFollowing
        ? await repo.unfollowCategory(categoryId)
        : await repo.followCategory(categoryId);
    result.when(
      ok: (_) {},
      err: (_) {
        final rolledBack = {...optimistic};
        if (FavouriteToggle.rollback(wasFollowing)) {
          rolledBack.add(categoryId);
        } else {
          rolledBack.remove(categoryId);
        }
        state = AsyncValue.data(rolledBack);
      },
    );
  }
}

final followedCategoriesProvider = StateNotifierProvider.autoDispose<
    FollowedCategoriesController,
    AsyncValue<Set<String>>>((ref) => FollowedCategoriesController(ref));
