import 'package:campus_event_hub/core/demo/demo_data_store.dart';
import 'package:campus_event_hub/core/result/result.dart';
import 'package:campus_event_hub/features/notifications/domain/notification_repository.dart';

class DemoNotificationRepository implements NotificationRepository {
  final DemoDataStore _store = DemoDataStore.instance;

  String get _uid => _store.currentUserId ?? 'demo-student-1';

  List<NotificationModel> get _mine =>
      _store.notificationsByUser.putIfAbsent(_uid, () => []);

  @override
  Future<Result<List<NotificationModel>>> myNotifications() async {
    final sorted = [..._mine]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Result.ok(sorted);
  }

  @override
  Future<Result<void>> markRead(String id) async {
    final list = _mine;
    final i = list.indexWhere((n) => n.id == id);
    if (i != -1) list[i] = list[i].copyWith(isRead: true);
    return Result.ok(null);
  }

  @override
  Future<Result<void>> markAllRead() async {
    final list = _mine;
    for (var i = 0; i < list.length; i++) {
      list[i] = list[i].copyWith(isRead: true);
    }
    return Result.ok(null);
  }
}
