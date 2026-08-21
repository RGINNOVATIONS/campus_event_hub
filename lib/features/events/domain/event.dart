import 'package:campus_pulse/core/domain/enums.dart';

class EventModel {
  final String id;
  final String clubId;
  final String clubName;
  final String categoryId;
  final String categoryName;
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
  final EventStatus status;
  final String? rejectionReason;
  final String? createdByUserId;

  const EventModel({
    required this.id,
    required this.clubId,
    required this.clubName,
    required this.categoryId,
    required this.categoryName,
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
    required this.status,
    this.rejectionReason,
    this.createdByUserId,
  });

  EventModel copyWith({
    String? id,
    String? clubId,
    String? clubName,
    String? categoryId,
    String? categoryName,
    String? title,
    String? shortDescription,
    String? fullDescription,
    String? posterPath,
    String? venue,
    DateTime? startAt,
    DateTime? endAt,
    DateTime? registrationDeadline,
    String? eligibility,
    String? rules,
    String? feeText,
    String? contactName,
    String? contactEmail,
    String? contactPhone,
    EventStatus? status,
    String? rejectionReason,
    String? createdByUserId,
  }) {
    return EventModel(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      clubName: clubName ?? this.clubName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      title: title ?? this.title,
      shortDescription: shortDescription ?? this.shortDescription,
      fullDescription: fullDescription ?? this.fullDescription,
      posterPath: posterPath ?? this.posterPath,
      venue: venue ?? this.venue,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      eligibility: eligibility ?? this.eligibility,
      rules: rules ?? this.rules,
      feeText: feeText ?? this.feeText,
      contactName: contactName ?? this.contactName,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdByUserId: createdByUserId ?? this.createdByUserId,
    );
  }
}

/// What the persistent Enroll button on the Event Details screen should
/// show. Pure function of event + enrolment state — kept out of the widget
/// tree so it's directly unit-testable per spec section 25.
enum EnrollButtonState {
  enroll,
  viewQr,
  registrationClosed,
  eventCancelled,
  completed
}

class EnrolmentEligibility {
  EnrolmentEligibility._();

  static EnrollButtonState buttonStateFor({
    required EventModel event,
    required bool isEnrolled,
    required DateTime now,
  }) {
    if (event.status == EventStatus.cancelled) {
      return EnrollButtonState.eventCancelled;
    }
    if (event.status == EventStatus.completed) {
      return EnrollButtonState.completed;
    }
    if (isEnrolled) return EnrollButtonState.viewQr;
    if (now.isAfter(event.registrationDeadline)) {
      return EnrollButtonState.registrationClosed;
    }
    if (now.isAfter(event.startAt)) {
      return EnrollButtonState.registrationClosed;
    }
    return EnrollButtonState.enroll;
  }

  /// Whether a new enrolment may be created at all right now.
  static bool canEnrol({required EventModel event, required DateTime now}) {
    return event.status == EventStatus.published &&
        now.isBefore(event.registrationDeadline) &&
        now.isBefore(event.startAt);
  }
}

/// Logical date validation for the organizer event form (spec section 16).
class EventDateValidator {
  EventDateValidator._();

  static String? validate({
    required DateTime start,
    required DateTime end,
    required DateTime registrationDeadline,
    required DateTime now,
  }) {
    if (start.isBefore(now)) return 'Event cannot start in the past.';
    if (!end.isAfter(start)) return 'End time must be later than start time.';
    if (!registrationDeadline.isBefore(start)) {
      return 'Registration deadline must be before the event start time.';
    }
    return null;
  }
}
