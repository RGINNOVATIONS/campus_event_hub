import 'package:campus_event_hub/core/result/result.dart';

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final String? eventId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.eventId,
    required this.isRead,
    required this.createdAt,
  });

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        type: type,
        title: title,
        body: body,
        eventId: eventId,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}

abstract class NotificationRepository {
  Future<Result<List<NotificationModel>>> myNotifications();
  Future<Result<void>> markRead(String id);
  Future<Result<void>> markAllRead();
}
