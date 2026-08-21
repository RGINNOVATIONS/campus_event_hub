import 'package:campus_pulse/core/domain/enums.dart';
import 'package:campus_pulse/features/certificates/domain/certificate_repository.dart';
import 'package:campus_pulse/features/events/domain/event.dart';
import 'package:campus_pulse/features/events/domain/event_repository.dart';
import 'package:campus_pulse/features/notifications/domain/notification_repository.dart';
import 'package:campus_pulse/features/organizer/domain/organizer_repository.dart';
import 'package:campus_pulse/features/clubs/domain/club_repository.dart';

/// Single shared in-memory demo dataset for the whole app session.
///
/// Fixes a real gap from the previous build: each demo repository used to
/// carry its own private, disconnected copy of "the same" data, so e.g.
/// an admin approving an event in `DemoAdminRepository` never showed up
/// as published in `DemoEventRepository`'s student feed. Every demo
/// repository now reads/writes through this one store instead.
class DemoDataStore {
  DemoDataStore._internal() {
    _seed();
  }
  static final DemoDataStore instance = DemoDataStore._internal();

  /// Set by DemoAuthRepository on login/register, cleared on logout.
  /// Lets student-scoped demo repos (favourites, enrolments, follows,
  /// notifications, certificates) know "whose" data to read/write without
  /// each repository needing its own auth dependency.
  String? currentUserId;

  late List<ClubModel> clubs;
  late List<CategoryModel> categories;
  late List<EventModel> events;

  /// eventId -> registrations for that event (organizer/admin view).
  late Map<String, List<RegistrationRow>> registrationsByEvent;

  /// eventId -> qrToken -> userId, used by the attendance scanner to
  /// resolve a scanned token back to a registration row.
  late Map<String, Map<String, String>> qrTokensByEvent;

  /// userId -> set of favourited event ids.
  final Map<String, Set<String>> favouritesByUser = {};

  /// userId -> set of followed club ids.
  final Map<String, Set<String>> clubFollowsByUser = {};

  /// userId -> set of followed category ids.
  final Map<String, Set<String>> categoryFollowsByUser = {};

  /// userId -> notifications.
  final Map<String, List<NotificationModel>> notificationsByUser = {};

  /// userId -> issued certificates.
  final Map<String, List<CertificateModel>> certificatesByUser = {};

  /// Resets all seeded/mutated state. Call this from `setUp()` in any
  /// test that mutates the store, since it's a process-wide singleton
  /// and `flutter test` can run multiple tests from the same file in
  /// one isolate.
  void resetForTests() {
    currentUserId = null;
    favouritesByUser.clear();
    clubFollowsByUser.clear();
    categoryFollowsByUser.clear();
    notificationsByUser.clear();
    certificatesByUser.clear();
    nextEventSuffix = 1000;
    _seed();
    // Strip posterPath in tests to prevent CachedNetworkImage from causing
    // pumpAndSettle() to time out due to infinite loading animations.
    events = events.map((e) => EventModel(
      id: e.id,
      clubId: e.clubId,
      clubName: e.clubName,
      categoryId: e.categoryId,
      categoryName: e.categoryName,
      title: e.title,
      shortDescription: e.shortDescription,
      fullDescription: e.fullDescription,
      posterPath: null, // explicitly null
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
      status: e.status,
      rejectionReason: e.rejectionReason,
      createdByUserId: e.createdByUserId,
    )).toList();
  }

  void _seed() {
    categories = [
      const CategoryModel(
          id: 'cat-technical',
          name: 'Technical',
          iconName: 'memory',
          colourHex: '#D4AF37'),
      const CategoryModel(
          id: 'cat-cultural',
          name: 'Cultural',
          iconName: 'theater_comedy',
          colourHex: '#F5C451'),
      const CategoryModel(
          id: 'cat-sports',
          name: 'Sports',
          iconName: 'sports_soccer',
          colourHex: '#39B980'),
      const CategoryModel(
          id: 'cat-workshop',
          name: 'Workshop',
          iconName: 'build',
          colourHex: '#A8872A'),
    ];

    clubs = [
      const ClubModel(
        id: 'club-robotics',
        name: 'Robotics & Automation Club',
        description:
            'Builds and competes with autonomous robots. Weekly build sessions every Thursday.',
        logoPath: null,
        contactEmail: 'robotics.club@college.edu.example',
        status: ClubStatus.verified,
      ),
      const ClubModel(
        id: 'club-cultural',
        name: 'Cultural Committee',
        description:
            'Runs the annual cultural festival and performance nights.',
        logoPath: null,
        contactEmail: 'cultural.committee@college.edu.example',
        status: ClubStatus.verified,
      ),
      const ClubModel(
        id: 'club-ecell',
        name: 'Entrepreneurship Cell',
        description:
            'Workshops, pitch nights and startup mentoring for student founders.',
        logoPath: null,
        contactEmail: 'ecell@college.edu.example',
        status: ClubStatus.verified,
      ),
      const ClubModel(
        id: 'club-photography',
        name: 'Photography Society',
        description: 'Newly formed — awaiting administrator verification.',
        logoPath: null,
        contactEmail: 'photo.soc@college.edu.example',
        status: ClubStatus.pending,
      ),
    ];

    final now = DateTime.now();

    events = [
      EventModel(
        id: 'evt-1',
        clubId: 'club-robotics',
        clubName: 'Robotics & Automation Club',
        categoryId: 'cat-technical',
        categoryName: 'Technical',
        title: 'RoboWars 2026',
        shortDescription: 'Autonomous bot combat, single elimination.',
        posterPath: 'https://picsum.photos/seed/robowars/800/400',
        fullDescription:
            'Design, build and battle your own combat robot in a single-elimination bracket. '
            'Open to teams of up to four students from any department.',
        venue: 'Main Auditorium',
        startAt: now.add(const Duration(days: 5, hours: 3)),
        endAt: now.add(const Duration(days: 5, hours: 7)),
        registrationDeadline: now.add(const Duration(days: 3)),
        eligibility: 'Open to all years and departments.',
        rules:
            'Max team size 4. Bots must weigh under 3kg. No projectile weapons.',
        contactName: 'Rahul Verma',
        contactEmail: 'demo.organizer@college.edu.example',
        status: EventStatus.published,
      ),
      EventModel(
        id: 'evt-2',
        clubId: 'club-cultural',
        clubName: 'Cultural Committee',
        categoryId: 'cat-cultural',
        categoryName: 'Cultural',
        title: 'Spring Fest — Battle of Bands',
        shortDescription: 'Live college band competition.',
        posterPath: 'https://picsum.photos/seed/springfest/800/400',
        fullDescription:
            'Six college bands compete live for the Spring Fest trophy. Food stalls and open '
            'mic slots run alongside the main stage all evening.',
        venue: 'Open Air Theatre',
        startAt: now.add(const Duration(days: 12, hours: 18)),
        endAt: now.add(const Duration(days: 12, hours: 22)),
        registrationDeadline: now.add(const Duration(days: 10)),
        eligibility: 'Open to all students; bands must pre-register.',
        rules:
            'Each band gets a 15-minute slot. Original or cover songs allowed.',
        contactName: 'Priya Nair',
        contactEmail: 'cultural.committee@college.edu.example',
        status: EventStatus.published,
      ),
      EventModel(
        id: 'evt-3',
        clubId: 'club-ecell',
        clubName: 'Entrepreneurship Cell',
        categoryId: 'cat-workshop',
        categoryName: 'Workshop',
        title: 'Pitch Night: Idea to MVP',
        shortDescription: 'Hands-on workshop on validating a startup idea.',
        posterPath: 'https://picsum.photos/seed/pitchnight/800/400',
        fullDescription:
            'A three-hour hands-on session on turning a rough idea into a testable MVP, '
            'followed by a mini pitch round with feedback from student mentors.',
        venue: 'Seminar Hall 2',
        startAt: now.add(const Duration(days: 2, hours: 5)),
        endAt: now.add(const Duration(days: 2, hours: 8)),
        registrationDeadline: now.add(const Duration(days: 1, hours: 12)),
        eligibility: 'Open to all years.',
        rules: 'Bring a laptop. Teams of up to 3.',
        contactName: 'Ecell Team',
        contactEmail: 'ecell@college.edu.example',
        status: EventStatus.published,
      ),
      EventModel(
        id: 'evt-pending-1',
        clubId: 'club-robotics',
        clubName: 'Robotics & Automation Club',
        categoryId: 'cat-technical',
        categoryName: 'Technical',
        title: 'Drone Racing Trials',
        shortDescription: 'Indoor FPV drone racing trials.',
        posterPath: 'https://picsum.photos/seed/droneracing/800/400',
        fullDescription:
            'Trials to select the college drone racing team for the inter-college meet.',
        venue: 'Sports Complex',
        startAt: now.add(const Duration(days: 20)),
        endAt: now.add(const Duration(days: 20, hours: 3)),
        registrationDeadline: now.add(const Duration(days: 18)),
        eligibility: 'Open to all years.',
        rules: 'Bring your own FPV goggles if available; spares provided.',
        contactName: 'Rahul Verma',
        contactEmail: 'demo.organizer@college.edu.example',
        status: EventStatus.pendingApproval,
      ),
      EventModel(
        id: 'evt-rejected-1',
        clubId: 'club-cultural',
        clubName: 'Cultural Committee',
        categoryId: 'cat-cultural',
        categoryName: 'Cultural',
        title: 'Midnight Movie Marathon',
        shortDescription: 'Overnight screening on campus grounds.',
        posterPath: 'https://picsum.photos/seed/moviemarathon/800/400',
        fullDescription:
            'An overnight open-air screening of student-picked films.',
        venue: 'Cricket Ground',
        startAt: now.add(const Duration(days: 8)),
        endAt: now.add(const Duration(days: 8, hours: 8)),
        registrationDeadline: now.add(const Duration(days: 6)),
        eligibility: 'Open to all.',
        rules: 'Campus quiet-hours policy applies.',
        contactName: 'Priya Nair',
        contactEmail: 'cultural.committee@college.edu.example',
        status: EventStatus.rejected,
        rejectionReason:
            'Overnight outdoor events on the cricket ground require Estate Office '
            'sign-off, which was not attached. Please resubmit with approval attached.',
      ),
      EventModel(
        id: 'evt-past-hackathon',
        clubId: 'club-robotics',
        clubName: 'Robotics & Automation Club',
        categoryId: 'cat-technical',
        categoryName: 'Technical',
        title: 'Winter Hackathon 2025',
        shortDescription: 'Overnight build competition.',
        posterPath: 'https://picsum.photos/seed/hackathon/800/400',
        fullDescription: 'A 24-hour overnight hackathon across three tracks.',
        venue: 'Innovation Lab',
        startAt: now.subtract(const Duration(days: 25)),
        endAt: now.subtract(const Duration(days: 24)),
        registrationDeadline: now.subtract(const Duration(days: 27)),
        eligibility: 'All years.',
        rules: 'Teams of up to 4.',
        contactName: 'Rahul Verma',
        contactEmail: 'demo.organizer@college.edu.example',
        status: EventStatus.completed,
      ),
    ];

    registrationsByEvent = {
      'evt-1': [
        const RegistrationRow(
            userId: 'demo-student-1',
            studentName: 'Aisha Sharma',
            attendanceStatus: AttendanceStatus.registered),
        const RegistrationRow(
            userId: 's2',
            studentName: 'Karan Mehta',
            attendanceStatus: AttendanceStatus.attended),
        const RegistrationRow(
            userId: 's3',
            studentName: 'Neha Joshi',
            attendanceStatus: AttendanceStatus.registered),
      ],
      'evt-past-hackathon': [
        const RegistrationRow(
            userId: 'demo-student-1',
            studentName: 'Aisha Sharma',
            attendanceStatus: AttendanceStatus.attended),
      ],
    };

    qrTokensByEvent = {
      'evt-1': {'DEMO-QR-TOKEN-EVT1-AISHA': 'demo-student-1'},
      'evt-past-hackathon': {'DEMO-QR-TOKEN-HACKATHON-AISHA': 'demo-student-1'},
    };

    favouritesByUser['demo-student-1'] = {'evt-2'};
    clubFollowsByUser['demo-student-1'] = {'club-cultural'};
    categoryFollowsByUser['demo-student-1'] = {'cat-technical'};

    notificationsByUser['demo-student-1'] = [
      NotificationModel(
        id: 'n1',
        type: 'event_published',
        title: 'New event: RoboWars 2026',
        body:
            'Robotics & Automation Club just published a new event you might like.',
        eventId: 'evt-1',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      NotificationModel(
        id: 'n2',
        type: 'event_reminder_24h',
        title: 'Pitch Night starts in ~24 hours',
        body: "Don't forget: Seminar Hall 2, tomorrow around this time.",
        eventId: 'evt-3',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      NotificationModel(
        id: 'n3',
        type: 'certificate_issued',
        title: 'Certificate ready',
        body:
            'Your certificate for Winter Hackathon 2025 is ready to download.',
        eventId: 'evt-past-hackathon',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];

    certificatesByUser['demo-student-1'] = [
      CertificateModel(
        id: 'cert-demo-1',
        eventId: 'evt-past-hackathon',
        eventTitle: 'Winter Hackathon 2025',
        certificateCode: 'CP2025WH0421',
        issuedAt: now.subtract(const Duration(days: 20)),
      ),
    ];
  }

  // --- helpers shared across repositories -----------------------------

  int nextEventSuffix = 1000;

  String newEventId() => 'evt-demo-${nextEventSuffix++}';

  void upsertEvent(EventModel event) {
    final i = events.indexWhere((e) => e.id == event.id);
    if (i == -1) {
      events.add(event);
    } else {
      events[i] = event;
    }
  }

  EventModel? eventById(String id) {
    for (final e in events) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Publishing/approving/rejecting/cancelling an event also fires the
  /// same notification fan-out the real Postgres triggers would, so demo
  /// mode's notification centre reflects admin actions — mirrors
  /// `notify_event_published()` / `notify_event_decision()`.
  void notifyFollowersOfPublish(EventModel event) {
    final recipients = <String>{};
    clubFollowsByUser.forEach((userId, clubIds) {
      if (clubIds.contains(event.clubId)) recipients.add(userId);
    });
    categoryFollowsByUser.forEach((userId, catIds) {
      if (catIds.contains(event.categoryId)) recipients.add(userId);
    });
    for (final userId in recipients) {
      _addNotification(
        userId,
        NotificationModel(
          id: 'demo-notif-${DateTime.now().microsecondsSinceEpoch}-$userId',
          type: 'event_published',
          title: 'New event: ${event.title}',
          body: 'A club or category you follow just published a new event.',
          eventId: event.id,
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  void notifyOrganizerOfDecision(EventModel event,
      {required bool approved, String? reason}) {
    _addNotification(
      event.createdByUserId ?? 'demo-organizer-1',
      NotificationModel(
        id: 'demo-notif-decision-${DateTime.now().microsecondsSinceEpoch}',
        type: approved ? 'event_approved' : 'event_rejected',
        title: approved ? 'Event approved' : 'Event needs changes',
        body: approved
            ? '${event.title} has been approved and published.'
            : '${event.title} was rejected: ${reason ?? ''}',
        eventId: event.id,
        isRead: false,
        createdAt: DateTime.now(),
      ),
    );
  }

  void notifyEnrolledOfCancellation(EventModel event) {
    final regs = registrationsByEvent[event.id] ?? [];
    for (final r in regs) {
      _addNotification(
        r.userId,
        NotificationModel(
          id: 'demo-notif-cancel-${DateTime.now().microsecondsSinceEpoch}-${r.userId}',
          type: 'event_cancelled',
          title: 'Event cancelled',
          body: '${event.title} has been cancelled.',
          eventId: event.id,
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  void _addNotification(String userId, NotificationModel n) {
    notificationsByUser.putIfAbsent(userId, () => []).insert(0, n);
  }
}
