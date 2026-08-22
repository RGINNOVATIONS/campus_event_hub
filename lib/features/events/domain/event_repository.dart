import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/core/result/result.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';

class CategoryModel {
  final String id;
  final String name;
  final String iconName;
  final String colourHex;
  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colourHex,
  });
}

class EnrolmentModel {
  final String id;
  final String eventId;
  final String qrToken;
  final AttendanceStatus attendanceStatus;
  const EnrolmentModel({
    required this.id,
    required this.eventId,
    required this.qrToken,
    required this.attendanceStatus,
  });
}

abstract class EventRepository {
  Future<Result<List<EventModel>>> upcomingPublishedEvents();
  Future<Result<List<CategoryModel>>> categories();
  Future<Result<EventModel>> eventById(String id);

  Future<Result<Set<String>>> favouriteEventIds();
  Future<Result<void>> addFavourite(String eventId);
  Future<Result<void>> removeFavourite(String eventId);

  Future<Result<Map<String, EnrolmentModel>>> myEnrolments();
  Future<Result<EnrolmentModel>> enrol(String eventId);
}
