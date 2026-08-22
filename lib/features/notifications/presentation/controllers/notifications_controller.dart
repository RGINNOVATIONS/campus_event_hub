import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/features/notifications/domain/notification_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationsController
    extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final Ref _ref;
  NotificationsController(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    final repo = _ref.read(notificationRepositoryProvider);
    final result = await repo.myNotifications();
    state = result.when(
      ok: (v) => AsyncValue.data(v),
      err: (f) => AsyncValue.error(f, StackTrace.current),
    );
  }

  Future<void> refresh() => _load();

  Future<void> markRead(String id) async {
    final repo = _ref.read(notificationRepositoryProvider);
    await repo.markRead(id);
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data([
      for (final n in current) n.id == id ? n.copyWith(isRead: true) : n,
    ]);
  }

  Future<void> markAllRead() async {
    final repo = _ref.read(notificationRepositoryProvider);
    await repo.markAllRead();
    final current = state.valueOrNull;
    if (current == null) return;
    state =
        AsyncValue.data([for (final n in current) n.copyWith(isRead: true)]);
  }
}

final notificationsControllerProvider = StateNotifierProvider.autoDispose<
    NotificationsController,
    AsyncValue<List<NotificationModel>>>((ref) => NotificationsController(ref));

final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final list = ref.watch(notificationsControllerProvider).valueOrNull ?? [];
  return list.where((n) => !n.isRead).length;
});
