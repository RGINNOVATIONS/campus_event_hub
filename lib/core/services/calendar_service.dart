import 'package:campus_event_hub/core/errors/app_failure.dart';
import 'package:campus_event_hub/core/result/result.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';
import 'package:device_calendar/device_calendar.dart' hide Result;
import 'package:timezone/data/latest.dart' as tz;

class CalendarEventMapper {
  CalendarEventMapper._();

  static Event toDeviceEvent({
    required String calendarId,
    required EventModel event,
  }) {
    tz.initializeTimeZones();

    return Event(
      calendarId,
      title: event.title,
      description: event.fullDescription,
      location: event.venue,
      start: TZDateTime.from(event.startAt, local),
      end: TZDateTime.from(event.endAt, local),
      allDay: false,
      availability: Availability.Busy,
      status: EventStatus.Confirmed,
    );
  }
}

class CalendarService {
  final DeviceCalendarPlugin _plugin;

  CalendarService({DeviceCalendarPlugin? plugin})
      : _plugin = plugin ?? DeviceCalendarPlugin();

  Future<Result<void>> addEventToCalendar(EventModel event) async {
    final permissionCheck = await _plugin.hasPermissions();
    final hasPermission = permissionCheck.data == true;

    if (!hasPermission) {
      final permissionRequest = await _plugin.requestPermissions();
      if (!permissionRequest.isSuccess || permissionRequest.data != true) {
        return Result.err(
          const UnknownFailure('Calendar access was not granted.'),
        );
      }
    }

    final calendarsResult = await _plugin.retrieveCalendars();
    if (!calendarsResult.isSuccess || calendarsResult.data == null) {
      return Result.err(
        const UnknownFailure('No calendars are available on this device.'),
      );
    }

    final calendar = calendarsResult.data!.firstWhere(
      (candidate) => candidate.isReadOnly == false,
      orElse: () => calendarsResult.data!.first,
    );

    final calendarId = calendar.id;
    if (calendarId == null || calendarId.isEmpty) {
      return Result.err(
        const UnknownFailure('This device has no writable calendar available.'),
      );
    }

    final deviceEvent = CalendarEventMapper.toDeviceEvent(
      calendarId: calendarId,
      event: event,
    );

    final created = await _plugin.createOrUpdateEvent(deviceEvent);
    if (created == null || !created.isSuccess || created.data == null) {
      return Result.err(
        const UnknownFailure('The event could not be added to your calendar.'),
      );
    }

    return Result.ok(null);
  }
}
