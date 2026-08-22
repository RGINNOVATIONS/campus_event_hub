import 'package:campus_event_hub/core/demo/demo_data_store.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/core/errors/app_failure.dart';
import 'package:campus_event_hub/core/result/result.dart';
import 'package:campus_event_hub/features/admin/domain/admin_repository.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';

class DemoAdminRepository implements AdminRepository {
  final DemoDataStore _store = DemoDataStore.instance;

  @override
  Future<Result<AdminDashboardCounts>> dashboardCounts() async =>
      Result.ok(AdminDashboardCounts(
        pendingEvents: _store.events
            .where((e) => e.status == EventStatus.pendingApproval)
            .length,
        publishedEvents: _store.events
            .where((e) => e.status == EventStatus.published)
            .length,
        verifiedClubs:
            _store.clubs.where((c) => c.status == ClubStatus.verified).length,
        totalStudents: 1240,
      ));

  @override
  Future<Result<List<EventModel>>> pendingEvents() async =>
      Result.ok(_store.events
          .where((e) => e.status == EventStatus.pendingApproval)
          .toList());

  @override
  Future<Result<List<EventModel>>> allEventsForCalendar() async => Result.ok(
      _store.events.where((e) => e.status == EventStatus.published).toList()
        ..sort((a, b) => a.startAt.compareTo(b.startAt)));

  @override
  Future<Result<void>> approveEvent(String eventId) async {
    final e = _store.eventById(eventId);
    if (e == null) return Result.err(const UnknownFailure('Event not found.'));
    final updated = _withStatus(e, EventStatus.published);
    _store.upsertEvent(updated);
    _store.notifyFollowersOfPublish(updated);
    _store.notifyOrganizerOfDecision(updated, approved: true);
    return Result.ok(null);
  }

  @override
  Future<Result<void>> rejectEvent(String eventId, String reason) async {
    final e = _store.eventById(eventId);
    if (e == null) return Result.err(const UnknownFailure('Event not found.'));
    final updated =
        _withStatus(e, EventStatus.rejected, rejectionReason: reason);
    _store.upsertEvent(updated);
    _store.notifyOrganizerOfDecision(updated, approved: false, reason: reason);
    return Result.ok(null);
  }

  @override
  Future<Result<void>> cancelEvent(String eventId) async {
    final e = _store.eventById(eventId);
    if (e == null) return Result.err(const UnknownFailure('Event not found.'));
    final updated = _withStatus(e, EventStatus.cancelled);
    _store.upsertEvent(updated);
    _store.notifyEnrolledOfCancellation(updated);
    return Result.ok(null);
  }

  @override
  Future<Result<List<ClubModel>>> clubs() async => Result.ok([..._store.clubs]);

  @override
  Future<Result<void>> verifyClub(String clubId) async {
    _replaceClubStatus(clubId, ClubStatus.verified);
    return Result.ok(null);
  }

  @override
  Future<Result<void>> rejectClub(String clubId) async {
    _replaceClubStatus(clubId, ClubStatus.rejected);
    return Result.ok(null);
  }

  void _replaceClubStatus(String clubId, ClubStatus status) {
    final i = _store.clubs.indexWhere((c) => c.id == clubId);
    if (i == -1) return;
    final c = _store.clubs[i];
    _store.clubs[i] = ClubModel(
      id: c.id,
      name: c.name,
      description: c.description,
      logoPath: c.logoPath,
      contactEmail: c.contactEmail,
      status: status,
    );
  }

  EventModel _withStatus(EventModel e, EventStatus status,
          {String? rejectionReason}) =>
      EventModel(
        id: e.id,
        clubId: e.clubId,
        clubName: e.clubName,
        categoryId: e.categoryId,
        categoryName: e.categoryName,
        title: e.title,
        shortDescription: e.shortDescription,
        fullDescription: e.fullDescription,
        posterPath: e.posterPath,
        venue: e.venue,
        startAt: e.startAt,
        endAt: e.endAt,
        registrationDeadline: e.registrationDeadline,
        eligibility: e.eligibility,
        rules: e.rules,
        feeText: e.feeText,
        contactName: e.contactName,
        contactEmail: e.contactEmail,
        contactPhone: e.contactPhone,
        status: status,
        rejectionReason: rejectionReason ?? e.rejectionReason,
        createdByUserId: e.createdByUserId,
      );
}
