import 'package:campus_event_hub/core/demo/demo_data_store.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/features/admin/data/demo_admin_repository.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';
import 'package:campus_event_hub/features/organizer/data/demo_organizer_repository.dart';
import 'package:campus_event_hub/features/organizer/domain/organizer_repository.dart';
import 'package:campus_event_hub/features/reviews/domain/review.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventReportAggregator & Calculations', () {
    final baseEvent = EventModel(
      id: 'evt-test-1',
      clubId: 'club-test',
      clubName: 'Test Club',
      categoryId: 'cat-test',
      categoryName: 'Technical',
      title: 'Test Hackathon',
      shortDescription: 'Short desc',
      fullDescription: 'Full description of the hackathon',
      venue: 'Main Auditorium',
      startAt: DateTime(2026, 3, 10, 9, 0),
      endAt: DateTime(2026, 3, 10, 18, 0),
      registrationDeadline: DateTime(2026, 3, 9, 23, 59),
      eligibility: 'Open to all students',
      rules: 'Standard campus rules apply',
      contactName: 'Test Organizer',
      contactEmail: 'organizer@college.edu',
      contactPhone: '9876543210',
      status: EventStatus.completed,
      guests: const [
        EventGuest(
          name: 'Dr. Jane Smith',
          designation: 'Keynote Speaker',
          organization: 'AI Labs',
        ),
      ],
    );

    final mockFeedback = EventFeedbackSummary(
      eventId: 'evt-test-1',
      averageRating: 4.5,
      reviewCount: 2,
      ratingDistribution: {1: 0, 2: 0, 3: 0, 4: 1, 5: 1},
      reviews: [
        ReviewModel(
          id: 'rev-1',
          eventId: 'evt-test-1',
          userId: 'u1',
          rating: 5,
          comment: 'Great event!',
          createdAt: DateTime(2026, 3, 11),
          updatedAt: DateTime(2026, 3, 11),
          studentName: 'Student One',
        ),
        ReviewModel(
          id: 'rev-2',
          eventId: 'evt-test-1',
          userId: 'u2',
          rating: 4,
          comment: 'Well organized',
          createdAt: DateTime(2026, 3, 11),
          updatedAt: DateTime(2026, 3, 11),
          studentName: 'Student Two',
        ),
      ],
    );

    test('aggregates participation and demographics accurately', () {
      final registrations = [
        const RegistrationRow(
          userId: 'u1',
          studentName: 'Alice',
          programme: 'B.Tech',
          branch: 'Computer Engineering',
          academicYear: 'Third Year',
          attendanceStatus: AttendanceStatus.attended,
        ),
        const RegistrationRow(
          userId: 'u2',
          studentName: 'Bob',
          programme: 'B.Tech',
          branch: 'Information Technology',
          academicYear: 'Third Year',
          attendanceStatus: AttendanceStatus.attended,
        ),
        const RegistrationRow(
          userId: 'u3',
          studentName: 'Charlie',
          programme: 'B.Pharm',
          branch: 'Pharmacy',
          academicYear: 'First Year',
          attendanceStatus: AttendanceStatus.attended,
        ),
        const RegistrationRow(
          userId: 'u4',
          studentName: 'David',
          programme: 'B.Tech',
          branch: 'Computer Engineering',
          academicYear: 'Second Year',
          attendanceStatus: AttendanceStatus.registered, // absent
        ),
      ];

      final report = EventReportAggregator.aggregate(
        event: baseEvent,
        registrations: registrations,
        feedback: mockFeedback,
      );

      // Participation Summary
      expect(report.registrationsCount, 4);
      expect(report.attendanceCount, 3);
      expect(report.attendancePercentage, 75.0); // 3 / 4 * 100

      // Demographics Breakdown (only attended students: u1, u2, u3)
      // Programme: B.Tech (2 -> 66.7%), B.Pharm (1 -> 33.3%)
      expect(report.programmeBreakdown.length, 2);
      expect(report.programmeBreakdown[0].label, 'B.Tech');
      expect(report.programmeBreakdown[0].count, 2);
      expect(report.programmeBreakdown[0].percentage, 66.7);
      expect(report.programmeBreakdown[1].label, 'B.Pharm');
      expect(report.programmeBreakdown[1].count, 1);
      expect(report.programmeBreakdown[1].percentage, 33.3);

      // Branch: Computer Engineering (1), Information Technology (1), Pharmacy (1)
      expect(report.branchBreakdown.length, 3);
      // Equal counts sorted alphabetically
      expect(report.branchBreakdown.map((b) => b.label).toList(), [
        'Computer Engineering',
        'Information Technology',
        'Pharmacy',
      ]);
      expect(report.branchBreakdown.every((b) => b.percentage == 33.3), isTrue);

      // Academic Year: Third Year (2 -> 66.7%), First Year (1 -> 33.3%)
      expect(report.academicYearBreakdown.length, 2);
      expect(report.academicYearBreakdown[0].label, 'Third Year');
      expect(report.academicYearBreakdown[0].count, 2);
      expect(report.academicYearBreakdown[0].percentage, 66.7);
      expect(report.academicYearBreakdown[1].label, 'First Year');
      expect(report.academicYearBreakdown[1].count, 1);
      expect(report.academicYearBreakdown[1].percentage, 33.3);

      // Guests
      expect(report.guests.length, 1);
      expect(report.guests.first.name, 'Dr. Jane Smith');

      // Feedback Summary reused without duplication
      expect(identical(report.feedback, mockFeedback), isTrue);
      expect(report.feedback.averageRating, 4.5);
      expect(report.feedback.reviewCount, 2);

      // Organizer details
      expect(report.organizer.name, 'Test Organizer');
      expect(report.organizer.clubName, 'Test Club');
      expect(report.organizer.contactEmail, 'organizer@college.edu');
      expect(report.organizer.contactPhone, '9876543210');
    });

    test('handles zero registrations and zero attendees safely', () {
      final report = EventReportAggregator.aggregate(
        event: baseEvent,
        registrations: const [],
        feedback: EventFeedbackSummary.empty('evt-test-1'),
      );

      expect(report.registrationsCount, 0);
      expect(report.attendanceCount, 0);
      expect(report.attendancePercentage, 0.0);
      expect(report.programmeBreakdown, isEmpty);
      expect(report.branchBreakdown, isEmpty);
      expect(report.academicYearBreakdown, isEmpty);
      expect(report.feedback.reviewCount, 0);
      expect(report.feedback.averageRating, 0.0);
    });

    test('handles registrations where no one attended', () {
      final registrations = [
        const RegistrationRow(
          userId: 'u1',
          studentName: 'Alice',
          programme: 'B.Tech',
          branch: 'CE',
          academicYear: 'Third Year',
          attendanceStatus: AttendanceStatus.registered,
        ),
      ];

      final report = EventReportAggregator.aggregate(
        event: baseEvent,
        registrations: registrations,
        feedback: EventFeedbackSummary.empty('evt-test-1'),
      );

      expect(report.registrationsCount, 1);
      expect(report.attendanceCount, 0);
      expect(report.attendancePercentage, 0.0);
      expect(report.programmeBreakdown, isEmpty);
      expect(report.branchBreakdown, isEmpty);
      expect(report.academicYearBreakdown, isEmpty);
    });

    test('maps empty strings in demographic fields to N/A', () {
      final registrations = [
        const RegistrationRow(
          userId: 'u1',
          studentName: 'Alice',
          programme: '',
          branch: '  ',
          academicYear: '',
          attendanceStatus: AttendanceStatus.attended,
        ),
      ];

      final report = EventReportAggregator.aggregate(
        event: baseEvent,
        registrations: registrations,
        feedback: mockFeedback,
      );

      expect(report.programmeBreakdown.first.label, 'N/A');
      expect(report.branchBreakdown.first.label, 'N/A');
      expect(report.academicYearBreakdown.first.label, 'N/A');
    });
  });

  group('DemoOrganizerRepository eventReportData', () {
    late DemoDataStore store;
    late DemoOrganizerRepository repo;

    setUp(() {
      store = DemoDataStore.instance;
      store.resetForTests();
      repo = DemoOrganizerRepository();
    });

    test('returns ValidationFailure if event is not completed', () async {
      // evt-1 is published, not completed
      final result = await repo.eventReportData('evt-1');
      expect(result.isErr, isTrue);
      expect(result.failureOrNull?.message,
          'Reports are only available for completed events.');
    });

    test('returns AuthorizationFailure if organizer does not own the event', () async {
      // evt-2 belongs to club-cultural, demo organizer belongs to club-robotics
      // Mark evt-2 completed to pass status gate
      final e2 = store.eventById('evt-2')!;
      store.upsertEvent(EventModel(
        id: e2.id,
        clubId: e2.clubId,
        clubName: e2.clubName,
        categoryId: e2.categoryId,
        categoryName: e2.categoryName,
        title: e2.title,
        shortDescription: e2.shortDescription,
        fullDescription: e2.fullDescription,
        venue: e2.venue,
        startAt: e2.startAt,
        endAt: e2.endAt,
        registrationDeadline: e2.registrationDeadline,
        eligibility: e2.eligibility,
        rules: e2.rules,
        contactName: e2.contactName,
        contactEmail: e2.contactEmail,
        status: EventStatus.completed,
      ));

      final result = await repo.eventReportData('evt-2');
      expect(result.isErr, isTrue);
      expect(result.failureOrNull?.message,
          'You are not authorized to view reports for this event.');
    });

    test('returns UnknownFailure for non-existent event', () async {
      final result = await repo.eventReportData('evt-nonexistent');
      expect(result.isErr, isTrue);
      expect(result.failureOrNull?.message, 'Event not found.');
    });

    test('generates accurate report for completed evt-past-hackathon', () async {
      final result = await repo.eventReportData('evt-past-hackathon');
      expect(result.isOk, isTrue);

      final report = result.valueOrNull!;
      expect(report.eventId, 'evt-past-hackathon');
      expect(report.title, 'Winter Hackathon 2025');
      expect(report.clubName, 'Robotics & Automation Club');
      expect(report.registrationsCount, 4);
      expect(report.attendanceCount, 3);
      expect(report.attendancePercentage, 75.0);

      // Feedback stats
      expect(report.feedback.reviewCount, 3);
      expect(report.feedback.averageRating, 4.7);
      expect(report.feedback.ratingDistribution, {1: 0, 2: 0, 3: 0, 4: 1, 5: 2});
      expect(report.feedback.reviews.length, 3);

      // Demographic Breakdown
      // Attended: Aisha (B.Tech, CE, Third Year), Karan (B.Tech, IT, Second Year), Neha (B.Pharm, N/A, First Year)
      expect(report.programmeBreakdown.length, 2);
      expect(report.programmeBreakdown[0].label, 'B.Tech');
      expect(report.programmeBreakdown[0].count, 2);
      expect(report.programmeBreakdown[0].percentage, 66.7);
      expect(report.programmeBreakdown[1].label, 'B.Pharm');
      expect(report.programmeBreakdown[1].count, 1);
      expect(report.programmeBreakdown[1].percentage, 33.3);

      // Guests
      expect(report.guests.length, 2);
      expect(report.guests.map((g) => g.name).toList(),
          containsAll(['Dr. Aris Thorne', 'Priya Sundaram']));
    });
  });

  group('DemoAdminRepository eventReportData (Admin Parity)', () {
    late DemoDataStore store;
    late DemoAdminRepository adminRepo;

    setUp(() {
      store = DemoDataStore.instance;
      store.resetForTests();
      adminRepo = DemoAdminRepository();
    });

    test('admin can generate report for completed event', () async {
      final result = await adminRepo.eventReportData('evt-past-hackathon');
      expect(result.isOk, isTrue);

      final report = result.valueOrNull!;
      expect(report.eventId, 'evt-past-hackathon');
      expect(report.registrationsCount, 4);
      expect(report.attendanceCount, 3);
      expect(report.attendancePercentage, 75.0);
      expect(report.feedback.reviewCount, 3);
      expect(report.feedback.averageRating, 4.7);
    });

    test('admin is gated to completed events only', () async {
      final result = await adminRepo.eventReportData('evt-1');
      expect(result.isErr, isTrue);
      expect(result.failureOrNull?.message,
          'Reports are only available for completed events.');
    });

    test('admin receives UnknownFailure for non-existent event', () async {
      final result = await adminRepo.eventReportData('evt-nonexistent');
      expect(result.isErr, isTrue);
      expect(result.failureOrNull?.message, 'Event not found.');
    });
  });
}
