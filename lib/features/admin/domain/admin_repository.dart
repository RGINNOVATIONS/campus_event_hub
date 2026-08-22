import 'package:campus_event_hub/core/result/result.dart';
import 'package:campus_event_hub/features/clubs/domain/club_repository.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';

export 'package:campus_event_hub/features/clubs/domain/club_repository.dart'
    show ClubModel;

class AdminDashboardCounts {
  final int pendingEvents;
  final int publishedEvents;
  final int verifiedClubs;
  final int totalStudents;
  const AdminDashboardCounts({
    required this.pendingEvents,
    required this.publishedEvents,
    required this.verifiedClubs,
    required this.totalStudents,
  });
}

abstract class AdminRepository {
  Future<Result<AdminDashboardCounts>> dashboardCounts();
  Future<Result<List<EventModel>>> pendingEvents();
  Future<Result<List<EventModel>>> allEventsForCalendar();
  Future<Result<void>> approveEvent(String eventId);
  Future<Result<void>> rejectEvent(String eventId, String reason);
  Future<Result<void>> cancelEvent(String eventId);
  Future<Result<List<ClubModel>>> clubs();
  Future<Result<void>> verifyClub(String clubId);
  Future<Result<void>> rejectClub(String clubId);
}
