import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';
import 'package:campus_event_hub/features/organizer/domain/organizer_repository.dart';
import 'package:campus_event_hub/features/reports/domain/event_report_ai_content.dart';
import 'package:campus_event_hub/features/reviews/domain/review.dart';

class DemographicItem {
  final String label;
  final int count;
  final double percentage; // 0.0 to 100.0

  const DemographicItem({
    required this.label,
    required this.count,
    required this.percentage,
  });

  Map<String, dynamic> toMap() => {
        'label': label,
        'count': count,
        'percentage': percentage,
      };

  @override
  String toString() => '$label: $count ($percentage%)';
}

class ReportOrganizerDetails {
  final String name;
  final String clubName;
  final String contactEmail;
  final String? contactPhone;

  const ReportOrganizerDetails({
    required this.name,
    required this.clubName,
    required this.contactEmail,
    this.contactPhone,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'club_name': clubName,
        'contact_email': contactEmail,
        if (contactPhone != null) 'contact_phone': contactPhone,
      };
}

class EventReportData {
  // 1. Event Overview & Schedule
  final String eventId;
  final String title;
  final String categoryName;
  final String clubName;
  final String venue;
  final DateTime startAt;
  final DateTime endAt;
  final String fullDescription;

  // 2. Participation Summary
  final int registrationsCount;
  final int attendanceCount;
  final double attendancePercentage; // 0.0 to 100.0

  // 3. Participant Statistics (Breakdown of ATTENDED students)
  final List<DemographicItem> programmeBreakdown;
  final List<DemographicItem> branchBreakdown;
  final List<DemographicItem> academicYearBreakdown;

  // 4. Guest / Speaker Details
  final List<EventGuest> guests;

  // 5. Feedback Stats & Reviews (Single source of truth from Round 2)
  final EventFeedbackSummary feedback;

  // 6. Organizer Details
  final ReportOrganizerDetails organizer;

  // 7. Persisted AI & Report Content (Objectives, Outcomes, Narrative)
  final EventReportContent? content;

  // 8. Metadata
  final DateTime generatedAt;

  const EventReportData({
    required this.eventId,
    required this.title,
    required this.categoryName,
    required this.clubName,
    required this.venue,
    required this.startAt,
    required this.endAt,
    required this.fullDescription,
    required this.registrationsCount,
    required this.attendanceCount,
    required this.attendancePercentage,
    required this.programmeBreakdown,
    required this.branchBreakdown,
    required this.academicYearBreakdown,
    required this.guests,
    required this.feedback,
    required this.organizer,
    required this.generatedAt,
    this.content,
  });

  EventReportData copyWith({
    String? eventId,
    String? title,
    String? categoryName,
    String? clubName,
    String? venue,
    DateTime? startAt,
    DateTime? endAt,
    String? fullDescription,
    int? registrationsCount,
    int? attendanceCount,
    double? attendancePercentage,
    List<DemographicItem>? programmeBreakdown,
    List<DemographicItem>? branchBreakdown,
    List<DemographicItem>? academicYearBreakdown,
    List<EventGuest>? guests,
    EventFeedbackSummary? feedback,
    ReportOrganizerDetails? organizer,
    DateTime? generatedAt,
    EventReportContent? content,
  }) {
    return EventReportData(
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      categoryName: categoryName ?? this.categoryName,
      clubName: clubName ?? this.clubName,
      venue: venue ?? this.venue,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      fullDescription: fullDescription ?? this.fullDescription,
      registrationsCount: registrationsCount ?? this.registrationsCount,
      attendanceCount: attendanceCount ?? this.attendanceCount,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
      programmeBreakdown: programmeBreakdown ?? this.programmeBreakdown,
      branchBreakdown: branchBreakdown ?? this.branchBreakdown,
      academicYearBreakdown: academicYearBreakdown ?? this.academicYearBreakdown,
      guests: guests ?? this.guests,
      feedback: feedback ?? this.feedback,
      organizer: organizer ?? this.organizer,
      generatedAt: generatedAt ?? this.generatedAt,
      content: content ?? this.content,
    );
  }
}

class EventReportAggregator {
  EventReportAggregator._();

  static EventReportData aggregate({
    required EventModel event,
    required List<RegistrationRow> registrations,
    required EventFeedbackSummary feedback,
    EventReportContent? content,
    DateTime? generatedAt,
  }) {
    final regCount = registrations.length;
    final attendedList = registrations
        .where((r) => r.attendanceStatus == AttendanceStatus.attended)
        .toList();
    final attCount = attendedList.length;

    final attPct = regCount > 0
        ? double.parse(((attCount / regCount) * 100).toStringAsFixed(1))
        : 0.0;

    final programmeBreakdown = _computeBreakdown(
      attendedList.map((r) => r.programme).toList(),
      attCount,
    );

    final branchBreakdown = _computeBreakdown(
      attendedList.map((r) => r.branch).toList(),
      attCount,
    );

    final academicYearBreakdown = _computeBreakdown(
      attendedList.map((r) => r.academicYear).toList(),
      attCount,
    );

    return EventReportData(
      eventId: event.id,
      title: event.title,
      categoryName: event.categoryName,
      clubName: event.clubName,
      venue: event.venue,
      startAt: event.startAt,
      endAt: event.endAt,
      fullDescription: event.fullDescription,
      registrationsCount: regCount,
      attendanceCount: attCount,
      attendancePercentage: attPct,
      programmeBreakdown: programmeBreakdown,
      branchBreakdown: branchBreakdown,
      academicYearBreakdown: academicYearBreakdown,
      guests: List.unmodifiable(event.guests),
      feedback: feedback,
      organizer: ReportOrganizerDetails(
        name: event.contactName.isNotEmpty ? event.contactName : 'Organizer',
        clubName: event.clubName,
        contactEmail: event.contactEmail,
        contactPhone: event.contactPhone,
      ),
      content: content,
      generatedAt: generatedAt ?? DateTime.now(),
    );
  }

  static List<DemographicItem> _computeBreakdown(
    List<String> rawValues,
    int totalAttended,
  ) {
    if (totalAttended == 0 || rawValues.isEmpty) return const [];

    final counts = <String, int>{};
    for (final raw in rawValues) {
      final key = raw.trim().isEmpty ? 'N/A' : raw.trim();
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final items = counts.entries.map((e) {
      final pct = double.parse(((e.value / totalAttended) * 100).toStringAsFixed(1));
      return DemographicItem(
        label: e.key,
        count: e.value,
        percentage: pct,
      );
    }).toList();

    // Sort descending by count, then alphabetically by label
    items.sort((a, b) {
      final cmp = b.count.compareTo(a.count);
      if (cmp != 0) return cmp;
      return a.label.compareTo(b.label);
    });

    return List.unmodifiable(items);
  }
}
