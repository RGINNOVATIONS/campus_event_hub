import 'package:flutter_test/flutter_test.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/core/domain/permissions.dart';

void main() {
  test('only admin can approve events', () {
    expect(Permissions.canApproveEvents(UserRole.admin), isTrue);
    expect(Permissions.canApproveEvents(UserRole.organizer), isFalse);
    expect(Permissions.canApproveEvents(UserRole.student), isFalse);
  });

  test('organizer and admin can scan attendance, student cannot', () {
    expect(Permissions.canScanAttendance(UserRole.organizer), isTrue);
    expect(Permissions.canScanAttendance(UserRole.admin), isTrue);
    expect(Permissions.canScanAttendance(UserRole.student), isFalse);
  });

  test('only admin can edit a role', () {
    expect(Permissions.canEditRole(UserRole.admin), isTrue);
    expect(Permissions.canEditRole(UserRole.student), isFalse);
  });
}
