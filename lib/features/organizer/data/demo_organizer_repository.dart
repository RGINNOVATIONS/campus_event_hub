import 'package:campus_event_hub/core/demo/demo_data_store.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/core/errors/app_failure.dart';
import 'package:campus_event_hub/core/result/result.dart';
import 'package:campus_event_hub/features/attendance/domain/scan_result.dart';
import 'package:campus_event_hub/features/certificates/domain/certificate_repository.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';
import 'package:campus_event_hub/features/organizer/domain/organizer_repository.dart';

/// Demo mode has one organizer account tied to `club-robotics`.
const _demoOrganizerClubId = 'club-robotics';

class DemoOrganizerRepository implements OrganizerRepository {
  final DemoDataStore _store = DemoDataStore.instance;

  String get _uid => _store.currentUserId ?? 'demo-organizer-1';

  @override
  Future<Result<OrganizerDashboardCounts>> dashboardCounts() async {
    final myEvents =
        _store.events.where((e) => e.clubId == _demoOrganizerClubId).toList();
    var totalReg = 0;
    var totalAttended = 0;
    for (final e in myEvents) {
      final regs = _store.registrationsByEvent[e.id] ?? [];
      totalReg += regs.length;
      totalAttended += regs
          .where((r) => r.attendanceStatus == AttendanceStatus.attended)
          .length;
    }
    return Result.ok(OrganizerDashboardCounts(
      totalEvents: myEvents.length,
      pendingApprovals:
          myEvents.where((e) => e.status == EventStatus.pendingApproval).length,
      published:
          myEvents.where((e) => e.status == EventStatus.published).length,
      completed:
          myEvents.where((e) => e.status == EventStatus.completed).length,
      totalRegistrations: totalReg,
      totalAttendees: totalAttended,
    ));
  }

  @override
  Future<Result<List<EventModel>>> myClubEvents() async => Result.ok(
      _store.events.where((e) => e.clubId == _demoOrganizerClubId).toList());

  @override
  Future<Result<EventModel>> saveDraft(DraftEventInput input) async {
    final validation = EventDateValidator.validate(
      start: input.startAt,
      end: input.endAt,
      registrationDeadline: input.registrationDeadline,
      now: DateTime.now(),
    );
    if (validation != null) {
      return Result.err(ValidationFailure(validation));
    }
    final category = _store.categories.firstWhere(
      (c) => c.id == input.categoryId,
      orElse: () => _store.categories.first,
    );
    final event = EventModel(
      id: input.id ?? _store.newEventId(),
      clubId: _demoOrganizerClubId,
      clubName: 'Robotics & Automation Club',
      categoryId: category.id,
      categoryName: category.name,
      title: input.title,
      shortDescription: input.shortDescription,
      fullDescription: input.fullDescription,
      posterPath: input.posterPath,
      venue: input.venue,
      startAt: input.startAt,
      endAt: input.endAt,
      registrationDeadline: input.registrationDeadline,
      eligibility: input.eligibility,
      rules: input.rules,
      feeText: input.feeText,
      contactName: input.contactName,
      contactEmail: input.contactEmail,
      contactPhone: input.contactPhone,
      status: EventStatus.draft,
      createdByUserId: _uid,
    );
    _store.upsertEvent(event);
    return Result.ok(event);
  }

  @override
  Future<Result<void>> submitForApproval(String eventId) async {
    final e = _store.eventById(eventId);
    if (e == null) return Result.err(const UnknownFailure('Event not found.'));
    _store.upsertEvent(_withStatus(e, EventStatus.pendingApproval));
    return Result.ok(null);
  }

  @override
  Future<Result<void>> deleteEvent(String eventId) async {
    final e = _store.eventById(eventId);
    if (e == null) return Result.err(const UnknownFailure('Event not found.'));
    if (e.clubId != _demoOrganizerClubId) {
      return Result.err(const AuthorizationFailure('You cannot delete this event.'));
    }
    if (e.status == EventStatus.published || e.status == EventStatus.completed || e.status == EventStatus.cancelled) {
      return Result.err(const AuthorizationFailure('Event cannot be deleted in its current state.'));
    }
    _store.events.removeWhere((x) => x.id == eventId);
    _store.registrationsByEvent.remove(eventId);
    _store.qrTokensByEvent.remove(eventId);
    return Result.ok(null);
  }

  @override
  Future<Result<List<RegistrationRow>>> registrationsFor(
          String eventId) async =>
      Result.ok([...(_store.registrationsByEvent[eventId] ?? [])]);

  @override
  Future<Result<ScanOutcome>> scanAttendance(
      {required String eventId, required String qrToken}) async {
    final event = _store.eventById(eventId);
    if (event == null || event.clubId != _demoOrganizerClubId) {
      return Result.ok(ScanOutcome.notAuthorized);
    }
    final studentId = _store.qrTokensByEvent[eventId]?[qrToken];
    if (studentId == null) return Result.ok(ScanOutcome.invalidToken);

    final list = _store.registrationsByEvent[eventId];
    if (list == null) return Result.ok(ScanOutcome.wrongEvent);
    final idx = list.indexWhere((r) => r.userId == studentId);
    if (idx == -1) return Result.ok(ScanOutcome.wrongEvent);
    if (list[idx].attendanceStatus == AttendanceStatus.attended) {
      return Result.ok(ScanOutcome.alreadyCheckedIn);
    }
    list[idx] = RegistrationRow(
      userId: list[idx].userId,
      studentName: list[idx].studentName,
      attendanceStatus: AttendanceStatus.attended,
    );
    return Result.ok(ScanOutcome.success);
  }

  @override
  Future<Result<void>> markEventCompleted(String eventId) async {
    final e = _store.eventById(eventId);
    if (e == null) return Result.err(const UnknownFailure('Event not found.'));
    _store.upsertEvent(_withStatus(e, EventStatus.completed));
    return Result.ok(null);
  }

  @override
  Future<Result<int>> issueCertificates(String eventId) async {
    final event = _store.eventById(eventId);
    if (event == null) {
      return Result.err(const UnknownFailure('Event not found.'));
    }
    if (event.status != EventStatus.completed) {
      return Result.err(const CertificateFailure(
          'Event must be completed before issuing certificates.'));
    }
    final regs = _store.registrationsByEvent[eventId] ?? [];
    var issued = 0;
    for (final r in regs) {
      if (r.attendanceStatus != AttendanceStatus.attended) continue;
      final existing =
          _store.certificatesByUser.putIfAbsent(r.userId, () => []);
      if (existing.any((c) => c.eventId == eventId)) continue; // idempotent
      final code =
          'CP${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      existing.add(CertificateModel(
        id: 'demo-cert-$eventId-${r.userId}',
        eventId: eventId,
        eventTitle: event.title,
        certificateCode: code,
        issuedAt: DateTime.now(),
      ));
      issued++;
    }
    return Result.ok(issued);
  }

  EventModel _withStatus(EventModel e, EventStatus status) => EventModel(
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
        rejectionReason: e.rejectionReason,
        createdByUserId: e.createdByUserId,
      );

  @override
  Future<Result<String>> uploadPoster(
      {required List<int> bytes, required String fileExtension}) async {
    // Demo mode never touches network storage. The organizer form still
    // gets a real preview from the picked bytes (rendered client-side);
    // this marker path just stands in for what would be a Supabase
    // Storage path in production, so saveDraft() has something to store.
    return Result.ok(
        'demo-poster-${DateTime.now().millisecondsSinceEpoch}.$fileExtension');
  }
}
