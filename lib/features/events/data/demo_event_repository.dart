import 'package:campus_event_hub/core/demo/demo_data_store.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/core/errors/app_failure.dart';
import 'package:campus_event_hub/core/result/result.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';
import 'package:campus_event_hub/features/events/domain/event_repository.dart';
import 'package:campus_event_hub/features/organizer/domain/organizer_repository.dart';

class DemoEventRepository implements EventRepository {
  final DemoDataStore _store = DemoDataStore.instance;

  String get _uid => _store.currentUserId ?? 'demo-student-1';

  @override
  Future<Result<List<EventModel>>> upcomingPublishedEvents() async {
    final published = _store.events
        .where((e) =>
            e.status == EventStatus.published ||
            e.status == EventStatus.postponed)
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    return Result.ok(published);
  }

  @override
  Future<Result<List<CategoryModel>>> categories() async =>
      Result.ok([..._store.categories]);

  @override
  Future<Result<EventModel>> eventById(String id) async {
    final match = _store.eventById(id);
    if (match == null) {
      return Result.err(const UnknownFailure('Event not found.'));
    }
    return Result.ok(match);
  }

  @override
  Future<Result<Set<String>>> favouriteEventIds() async =>
      Result.ok({...(_store.favouritesByUser[_uid] ?? {})});

  @override
  Future<Result<void>> addFavourite(String eventId) async {
    _store.favouritesByUser.putIfAbsent(_uid, () => {}).add(eventId);
    return Result.ok(null);
  }

  @override
  Future<Result<void>> removeFavourite(String eventId) async {
    _store.favouritesByUser[_uid]?.remove(eventId);
    return Result.ok(null);
  }

  @override
  Future<Result<Map<String, EnrolmentModel>>> myEnrolments() async {
    final map = <String, EnrolmentModel>{};
    _store.registrationsByEvent.forEach((eventId, regs) {
      for (final r in regs) {
        if (r.userId != _uid) continue;
        final tokens = _store.qrTokensByEvent[eventId] ?? {};
        String? token;
        for (final entry in tokens.entries) {
          if (entry.value == _uid) {
            token = entry.key;
            break;
          }
        }
        map[eventId] = EnrolmentModel(
          id: 'enr-$eventId-$_uid',
          eventId: eventId,
          qrToken: token ?? 'DEMO-QR-TOKEN-$eventId-$_uid',
          attendanceStatus: r.attendanceStatus,
        );
      }
    });
    return Result.ok(map);
  }

  @override
  Future<Result<EnrolmentModel>> enrol(String eventId) async {
    final event = _store.eventById(eventId);
    if (event == null) {
      return Result.err(const UnknownFailure('Event not found.'));
    }
    if (!EnrolmentEligibility.canEnrol(event: event, now: DateTime.now())) {
      return Result.err(
          const ValidationFailure('Registration is not open for this event.'));
    }
    final regs = _store.registrationsByEvent.putIfAbsent(eventId, () => []);
    if (regs.any((r) => r.userId == _uid)) {
      return Result.err(
          const ValidationFailure('You are already enrolled in this event.'));
    }
    regs.add(RegistrationRow(
        userId: _uid,
        studentName: 'You',
        attendanceStatus: AttendanceStatus.registered));
    final token =
        'DEMO-QR-TOKEN-$eventId-${DateTime.now().millisecondsSinceEpoch}';
    _store.qrTokensByEvent.putIfAbsent(eventId, () => {})[token] = _uid;
    return Result.ok(EnrolmentModel(
      id: 'enr-$eventId-$_uid',
      eventId: eventId,
      qrToken: token,
      attendanceStatus: AttendanceStatus.registered,
    ));
  }
}
