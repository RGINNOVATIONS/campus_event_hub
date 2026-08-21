import 'package:campus_pulse/core/domain/enums.dart';
import 'package:campus_pulse/core/result/result.dart';
import 'package:campus_pulse/features/attendance/domain/scan_result.dart';
import 'package:campus_pulse/features/events/domain/event.dart';

class OrganizerDashboardCounts {
  final int totalEvents;
  final int pendingApprovals;
  final int published;
  final int completed;
  final int totalRegistrations;
  final int totalAttendees;
  const OrganizerDashboardCounts({
    required this.totalEvents,
    required this.pendingApprovals,
    required this.published,
    required this.completed,
    required this.totalRegistrations,
    required this.totalAttendees,
  });
}

class RegistrationRow {
  final String userId;
  final String studentName;
  final AttendanceStatus attendanceStatus;
  const RegistrationRow({
    required this.userId,
    required this.studentName,
    required this.attendanceStatus,
  });
}

class DraftEventInput {
  final String? id;
  final String categoryId;
  final String title;
  final String shortDescription;
  final String fullDescription;
  final String? posterPath;
  final String venue;
  final DateTime startAt;
  final DateTime endAt;
  final DateTime registrationDeadline;
  final String eligibility;
  final String rules;
  final String? feeText;
  final String contactName;
  final String contactEmail;
  final String? contactPhone;

  const DraftEventInput({
    this.id,
    required this.categoryId,
    required this.title,
    required this.shortDescription,
    required this.fullDescription,
    this.posterPath,
    required this.venue,
    required this.startAt,
    required this.endAt,
    required this.registrationDeadline,
    required this.eligibility,
    required this.rules,
    this.feeText,
    required this.contactName,
    required this.contactEmail,
    this.contactPhone,
  });
}

abstract class OrganizerRepository {
  Future<Result<OrganizerDashboardCounts>> dashboardCounts();
  Future<Result<List<EventModel>>> myClubEvents();
  Future<Result<EventModel>> saveDraft(DraftEventInput input);
  Future<Result<void>> submitForApproval(String eventId);
  Future<Result<void>> deleteEvent(String eventId);
  Future<Result<List<RegistrationRow>>> registrationsFor(String eventId);
  Future<Result<ScanOutcome>> scanAttendance(
      {required String eventId, required String qrToken});
  Future<Result<void>> markEventCompleted(String eventId);
  Future<Result<int>> issueCertificates(String eventId);

  /// Uploads poster bytes and returns the storage path to store on the
  /// event's `poster_path`. [fileExtension] should be one of jpg/png/webp
  /// (validated by the caller before this is invoked — see
  /// `CreateEventScreen._pickPoster`). Demo mode never touches network
  /// storage; it returns a synthetic local marker path instead so the
  /// preview/flow is still fully exercisable offline.
  Future<Result<String>> uploadPoster({
    required List<int> bytes,
    required String fileExtension,
  });
}
