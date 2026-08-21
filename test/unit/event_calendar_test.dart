import 'package:flutter_test/flutter_test.dart';
import 'package:campus_pulse/core/domain/enums.dart';
import 'package:campus_pulse/core/services/calendar_service.dart';
import 'package:campus_pulse/features/events/domain/event.dart';

EventModel _event() => EventModel(
  id: 'e1',
  clubId: 'c1',
  clubName: 'Robotics Club',
  categoryId: 'cat1',
  categoryName: 'Technical',
  title: 'RoboWars',
  shortDescription: 'short',
  fullDescription: 'full',
  venue: 'Main Auditorium',
  startAt: DateTime(2026, 9, 10, 14, 30),
  endAt: DateTime(2026, 9, 10, 18, 0),
  registrationDeadline: DateTime(2026, 9, 5),
  eligibility: 'All years',
  rules: 'No rules',
  contactName: 'Organizer',
  contactEmail: 'organizer@college.edu.example',
  status: EventStatus.published,
);

void main() {
  test('Calendar mapper keeps the event title, location, and timing intact', () {
    final mapped = CalendarEventMapper.toDeviceEvent(
      calendarId: 'calendar-123',
      event: _event(),
    );

    expect(mapped.calendarId, 'calendar-123');
    expect(mapped.title, 'RoboWars');
    expect(mapped.location, 'Main Auditorium');
    expect(mapped.start!.year, 2026);
    expect(mapped.end!.year, 2026);
  });
}
