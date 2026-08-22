import 'package:flutter_test/flutter_test.dart';
import 'package:campus_event_hub/features/notifications/domain/notification_dedup.dart';

void main() {
  test('a user following both club and category is only notified once', () {
    final result = NotificationDedup.dedupeRecipients(
      clubFollowerIds: ['u1', 'u2'],
      categoryFollowerIds: ['u2', 'u3'],
    );
    expect(result.toSet(), {'u1', 'u2', 'u3'});
    expect(result.where((id) => id == 'u2').length, 1);
  });
}
