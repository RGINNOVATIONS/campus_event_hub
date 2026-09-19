class EventReportContent {
  final String eventId;
  final String organizerNotes;
  final String objectives;
  final String outcomes;
  final String feedbackNarrative;
  final String status; // 'draft' or 'confirmed'
  final String? createdBy;
  final String? confirmedBy;
  final DateTime? confirmedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EventReportContent({
    required this.eventId,
    this.organizerNotes = '',
    this.objectives = '',
    this.outcomes = '',
    this.feedbackNarrative = '',
    this.status = 'draft',
    this.createdBy,
    this.confirmedBy,
    this.confirmedAt,
    this.createdAt,
    this.updatedAt,
  });

  bool get isConfirmed => status == 'confirmed';

  EventReportContent copyWith({
    String? eventId,
    String? organizerNotes,
    String? objectives,
    String? outcomes,
    String? feedbackNarrative,
    String? status,
    String? createdBy,
    String? confirmedBy,
    DateTime? confirmedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventReportContent(
      eventId: eventId ?? this.eventId,
      organizerNotes: organizerNotes ?? this.organizerNotes,
      objectives: objectives ?? this.objectives,
      outcomes: outcomes ?? this.outcomes,
      feedbackNarrative: feedbackNarrative ?? this.feedbackNarrative,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'event_id': eventId,
        'organizer_notes': organizerNotes,
        'objectives': objectives,
        'outcomes': outcomes,
        'feedback_narrative': feedbackNarrative,
        'status': status,
        if (createdBy != null) 'created_by': createdBy,
        if (confirmedBy != null) 'confirmed_by': confirmedBy,
        if (confirmedAt != null) 'confirmed_at': confirmedAt!.toIso8601String(),
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  factory EventReportContent.fromMap(Map<String, dynamic> map) {
    return EventReportContent(
      eventId: map['event_id'] as String? ?? '',
      organizerNotes: map['organizer_notes'] as String? ?? '',
      objectives: map['objectives'] as String? ?? '',
      outcomes: map['outcomes'] as String? ?? '',
      feedbackNarrative: map['feedback_narrative'] as String? ?? '',
      status: map['status'] as String? ?? 'draft',
      createdBy: map['created_by'] as String?,
      confirmedBy: map['confirmed_by'] as String?,
      confirmedAt: map['confirmed_at'] != null
          ? DateTime.tryParse(map['confirmed_at'].toString())
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventReportContent &&
          runtimeType == other.runtimeType &&
          eventId == other.eventId &&
          organizerNotes == other.organizerNotes &&
          objectives == other.objectives &&
          outcomes == other.outcomes &&
          feedbackNarrative == other.feedbackNarrative &&
          status == other.status;

  @override
  int get hashCode => Object.hash(
        eventId,
        organizerNotes,
        objectives,
        outcomes,
        feedbackNarrative,
        status,
      );
}

class ObjectivesAndOutcomesDraft {
  final String objectives;
  final String outcomes;
  final String rawText;

  const ObjectivesAndOutcomesDraft({
    required this.objectives,
    required this.outcomes,
    required this.rawText,
  });
}
