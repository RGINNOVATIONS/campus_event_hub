import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/core/result/result.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';

class ClubModel {
  final String id;
  final String name;
  final String description;
  final String? logoPath;
  final String contactEmail;
  final ClubStatus status;
  const ClubModel({
    required this.id,
    required this.name,
    required this.description,
    this.logoPath,
    required this.contactEmail,
    required this.status,
  });
}

abstract class ClubRepository {
  /// Only verified clubs, per spec section 3 ("Only verified clubs
  /// should be visible to ordinary students").
  Future<Result<List<ClubModel>>> verifiedClubs();

  Future<Result<ClubModel>> clubById(String id);
  Future<Result<List<EventModel>>> upcomingEventsForClub(String clubId);

  Future<Result<Set<String>>> followedClubIds();
  Future<Result<void>> followClub(String clubId);
  Future<Result<void>> unfollowClub(String clubId);

  Future<Result<Set<String>>> followedCategoryIds();
  Future<Result<void>> followCategory(String categoryId);
  Future<Result<void>> unfollowCategory(String categoryId);
}
