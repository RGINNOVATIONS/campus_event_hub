import 'package:flutter_test/flutter_test.dart';
import 'package:campus_event_hub/features/favourites/domain/favourite_toggle.dart';

void main() {
  test('optimistic toggle flips state immediately', () {
    expect(FavouriteToggle.optimisticNextState(false), isTrue);
    expect(FavouriteToggle.optimisticNextState(true), isFalse);
  });

  test('rollback restores the prior state on failure', () {
    expect(FavouriteToggle.rollback(false), isFalse);
    expect(FavouriteToggle.rollback(true), isTrue);
  });
}
