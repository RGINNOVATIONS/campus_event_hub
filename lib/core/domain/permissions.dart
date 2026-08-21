import 'package:campus_pulse/core/domain/enums.dart';

/// Client-side permission checks used only to decide what UI to show.
/// These are NOT the source of truth — every action they gate is also
/// enforced by Postgres RLS / SECURITY DEFINER functions server-side,
/// per spec section 7 ("hiding a button is not authorization").
class Permissions {
  Permissions._();

  static bool canAccessOrganizerArea(UserRole role) =>
      role == UserRole.organizer || role == UserRole.admin;

  static bool canAccessAdminArea(UserRole role) => role == UserRole.admin;

  static bool canApproveEvents(UserRole role) => role == UserRole.admin;

  static bool canScanAttendance(UserRole role) =>
      role == UserRole.organizer || role == UserRole.admin;

  static bool canEditRole(UserRole actingRole) => actingRole == UserRole.admin;
}
