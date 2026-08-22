import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/core/demo/demo_data_store.dart';
import 'package:campus_event_hub/features/clubs/data/demo_club_repository.dart';
import 'package:campus_event_hub/features/clubs/presentation/screens/notification_preferences_screen.dart';
import 'package:campus_event_hub/features/events/data/demo_event_repository.dart';
import 'package:campus_event_hub/features/organizer/presentation/screens/create_event_screen.dart';

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

  testWidgets('create event category dropdown opens and updates selection',
      (tester) async {
    DemoDataStore.instance.currentUserId = 'demo-student-1';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventRepositoryProvider.overrideWithValue(DemoEventRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            behavior: HitTestBehavior.translucent,
            child: const CreateEventScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final categoryField = find.byType(DropdownButtonFormField<String>);
    expect(categoryField, findsOneWidget);

    await tester.tap(categoryField);
    await tester.pumpAndSettle();

    expect(find.text('Technical'), findsWidgets);

    await tester.tap(find.text('Technical').last);
    await tester.pumpAndSettle();

    expect(find.text('Technical'), findsAtLeastNWidgets(1));
  });
}
