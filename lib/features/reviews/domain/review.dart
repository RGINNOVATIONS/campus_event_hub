class ReviewModel {
  final String id;
  final String eventId;
  final String userId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? studentName;

  const ReviewModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.studentName,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    String? name;
    if (map['profiles'] is Map) {
      name = map['profiles']['full_name'] as String?;
    } else if (map['student_name'] is String) {
      name = map['student_name'] as String?;
    }

    return ReviewModel(
      id: map['id'] as String,
      eventId: map['event_id'] as String,
      userId: map['user_id'] as String,
      rating: map['rating'] as int,
      comment: (map['comment'] as String?)?.trim() ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
      studentName: name,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'event_id': eventId,
        'user_id': userId,
        'rating': rating,
        'comment': comment,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        if (studentName != null) 'student_name': studentName,
      };

  ReviewModel copyWith({
    String? id,
    String? eventId,
    String? userId,
    int? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? studentName,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      studentName: studentName ?? this.studentName,
    );
  }
}

class EventFeedbackSummary {
  final String eventId;
  final double averageRating;
  final int reviewCount;
  final Map<int, int> ratingDistribution; // 1 to 5
  final List<ReviewModel> reviews;

  const EventFeedbackSummary({
    required this.eventId,
    required this.averageRating,
    required this.reviewCount,
    required this.ratingDistribution,
    required this.reviews,
  });

  factory EventFeedbackSummary.empty(String eventId) => EventFeedbackSummary(
        eventId: eventId,
        averageRating: 0.0,
        reviewCount: 0,
        ratingDistribution: const {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        reviews: const [],
      );

  factory EventFeedbackSummary.fromReviews({
    required String eventId,
    required List<ReviewModel> reviews,
  }) {
    if (reviews.isEmpty) return EventFeedbackSummary.empty(eventId);

    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    var sum = 0;
    for (final r in reviews) {
      sum += r.rating;
      distribution[r.rating] = (distribution[r.rating] ?? 0) + 1;
    }

    final avg = double.parse((sum / reviews.length).toStringAsFixed(1));
    final sortedReviews = List<ReviewModel>.from(reviews)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return EventFeedbackSummary(
      eventId: eventId,
      averageRating: avg,
      reviewCount: reviews.length,
      ratingDistribution: distribution,
      reviews: sortedReviews,
    );
  }
}
