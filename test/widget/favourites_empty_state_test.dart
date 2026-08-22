import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/core/result/result.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';
import 'package:campus_event_hub/features/events/domain/event_repository.dart';
import 'package:campus_event_hub/features/favourites/presentation/screens/favourites_screen.dart';

/// An EventRepository with events but zero favourites, to force the
/// Favourites screen's empty state regardless of the shared demo seed.
class _NoFavouritesRepo implements EventRepository {
  @override
  Future<Result<void>> addFavourite(String eventId) async => Result.ok(null);
  @override
  Future<Result<Set<String>>> favouriteEventIds() async =>
      Result.ok(<String>{});
  @override
  Future<Result<List<CategoryModel>>> categories() async => Result.ok([]);
  @override
  Future<Result<EventModel>> eventById(String id) async =>
      throw UnimplementedError();
  @override
  Future<Result<EnrolmentModel>> enrol(String eventId) async =>
      throw UnimplementedError();
  @override
  Future<Result<Map<String, EnrolmentModel>>> myEnrolments() async =>
      Result.ok({});
  @override
  Future<Result<void>> removeFavourite(String eventId) async => Result.ok(null);
  @override
  Future<Result<List<EventModel>>> upcomingPublishedEvents() async =>
      Result.ok([]);
}

void main() {
  testWidgets('Favourites screen shows an empty state with no favourites',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventRepositoryProvider.overrideWithValue(_NoFavouritesRepo())
        ],
        child:
            MaterialApp(theme: AppTheme.dark, home: const FavouritesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('No favourites yet'), findsOneWidget);
  });
}
