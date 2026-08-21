enum UserRole { student, organizer, admin }

extension UserRoleX on UserRole {
  static UserRole fromDb(String value) => UserRole.values.firstWhere(
        (r) => r.name == value,
        orElse: () => UserRole.student,
      );
}

enum ClubStatus { pending, verified, rejected, suspended }

extension ClubStatusX on ClubStatus {
  static ClubStatus fromDb(String value) => ClubStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => ClubStatus.pending,
      );
}

enum EventStatus {
  draft,
  pendingApproval,
  published,
  rejected,
  cancelled,
  completed
}

extension EventStatusX on EventStatus {
  static EventStatus fromDb(String value) {
    switch (value) {
      case 'pending_approval':
        return EventStatus.pendingApproval;
      default:
        return EventStatus.values.firstWhere(
          (s) => s.name == value,
          orElse: () => EventStatus.draft,
        );
    }
  }

  String get toDb {
    switch (this) {
      case EventStatus.pendingApproval:
        return 'pending_approval';
      default:
        return name;
    }
  }
}

enum AttendanceStatus { registered, attended, absent }

extension AttendanceStatusX on AttendanceStatus {
  static AttendanceStatus fromDb(String value) =>
      AttendanceStatus.values.firstWhere((s) => s.name == value,
          orElse: () => AttendanceStatus.registered);
}
