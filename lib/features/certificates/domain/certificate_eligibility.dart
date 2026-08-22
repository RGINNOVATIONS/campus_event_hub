import 'package:campus_event_hub/core/domain/enums.dart';

class CertificateEligibility {
  CertificateEligibility._();

  /// Only attended students, for a completed event, are eligible.
  /// Mirrors the server-side check inside the `issue-certificates`
  /// Edge Function — this copy exists so the organizer UI can grey out
  /// ineligible rows before even calling the backend.
  static bool isEligible({
    required EventStatus eventStatus,
    required AttendanceStatus attendanceStatus,
  }) {
    return eventStatus == EventStatus.completed &&
        attendanceStatus == AttendanceStatus.attended;
  }
}
