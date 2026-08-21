import 'package:campus_pulse/core/errors/app_failure.dart';
import 'package:campus_pulse/core/result/result.dart';
import 'package:campus_pulse/features/notifications/domain/notification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseNotificationRepository implements NotificationRepository {
  final SupabaseClient _client;
  SupabaseNotificationRepository(this._client);

  NotificationModel _map(Map<String, dynamic> r) => NotificationModel(
        id: r['id'] as String,
        type: r['type'] as String,
        title: r['title'] as String,
        body: r['body'] as String,
        eventId: r['event_id'] as String?,
        isRead: r['is_read'] as bool? ?? false,
        createdAt: DateTime.parse(r['created_at'] as String),
      );

  @override
  Future<Result<List<NotificationModel>>> myNotifications() async {
    try {
      final uid = _client.auth.currentUser!.id;
      final rows = await _client
          .from('notifications')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);
      return Result.ok(
          (rows as List).map((r) => _map(r as Map<String, dynamic>)).toList());
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> markRead(String id) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true}).eq('id', id);
      return Result.ok(null);
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> markAllRead() async {
    try {
      final uid = _client.auth.currentUser!.id;
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', uid)
          .eq('is_read', false);
      return Result.ok(null);
    } catch (e) {
      return Result.err(mapExceptionToFailure(e));
    }
  }
}
