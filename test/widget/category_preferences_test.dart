import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_pulse/app/theme.dart';
import 'package:campus_pulse/app/providers.dart';
import 'package:campus_pulse/core/demo/demo_data_store.dart';
import 'package:campus_pulse/features/clubs/data/demo_club_repository.dart';
import 'package:campus_pulse/features/clubs/presentation/screens/notification_preferences_screen.dart';
import 'package:campus_pulse/features/events/data/demo_event_repository.dart';

void main() {
  setUp(() => DemoDataStore.instance.resetForTests());

  testWidgets('toggling a category switch follows/unfollows it',
      (tester) async {
    DemoDataStore.instance.currentUserId = 'demo-student-1';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clubRepositoryProvider.overrideWithValue(DemoClubRepository()),
          eventRepositoryProvider.overrideWithValue(DemoEventRepository()),
        ],
        child: MaterialApp(
            theme: AppTheme.dark, home: const NotificationPreferencesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sports'), findsOneWidget);
    final sportsSwitch = find.widgetWithText(SwitchListTile, 'Sports');
    expect(tester.widget<SwitchListTile>(sportsSwitch).value, isFalse);

    await tester.tap(sportsSwitch);
    await tester.pumpAndSettle();

    expect(
        tester
            .widget<SwitchListTile>(
                find.widgetWithText(SwitchListTile, 'Sports'))
            .value,
        isTrue);
  });
}
