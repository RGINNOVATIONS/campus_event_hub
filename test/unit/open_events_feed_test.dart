import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_event_hub/app/env.dart';
import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/core/demo/demo_data_store.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/features/events/data/demo_event_repository.dart';
import 'package:campus_event_hub/features/events/presentation/screens/home_screen.dart';
import 'package:campus_event_hub/features/enrolments/presentation/screens/my_events_screen.dart';

void main() {
  setUpAll(() async {
    await Env.load();
  });

  setUp(() {
    DemoDataStore.instance.resetForTests();
  });

  group('Open Published Events vs Upcoming Events', () {
    test('DemoEventRepository openPublishedEvents filters out past-deadline events', () async {
      final repo = DemoEventRepository();
      
      final openResult = await repo.openPublishedEvents();
      expect(openResult.isOk, isTrue);
      final openEvents = openResult.valueOrNull!;

      final upcomingResult = await repo.upcomingPublishedEvents();
      expect(upcomingResult.isOk, isTrue);
      final upcomingEvents = upcomingResult.valueOrNull!;

      // Past-deadline event must be in upcomingEvents, but NOT in openEvents
      final closedEventInUpcoming = upcomingEvents.where((e) => e.id == 'evt-closed-deadline');
      expect(closedEventInUpcoming.length, 1, reason: 'evt-closed-deadline should be in upcomingPublishedEvents');

      final closedEventInOpen = openEvents.where((e) => e.id == 'evt-closed-deadline');
      expect(closedEventInOpen.length, 0, reason: 'evt-closed-deadline must NOT be in openPublishedEvents');

      // Future-deadline published event and postponed event must be in openEvents
      final futurePublished = openEvents.where((e) => e.id == 'evt-1');
      expect(futurePublished.length, 1, reason: 'evt-1 should be in openPublishedEvents');

      final futurePostponed = openEvents.where((e) => e.id == 'evt-postponed-future');
      expect(futurePostponed.length, 1, reason: 'evt-postponed-future should be in openPublishedEvents');
      expect(futurePostponed.first.status, EventStatus.postponed);
    });

    testWidgets('HomeScreen shows only open-registration events and hides closed ones', (tester) async {
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            demoModeProvider.overrideWithValue(true),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Future deadline event 'RoboWars 2026' and postponed 'Autonomous Drone Showcase' should show
      expect(find.text('RoboWars 2026'), findsWidgets);
      expect(find.text('Autonomous Drone Showcase'), findsWidgets);

      // Past deadline event 'AI Research Symposium 2026' should NOT show
      expect(find.text('AI Research Symposium 2026'), findsNothing);
    });

    testWidgets('MyEventsScreen retains past-deadline event for enrolled student', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            demoModeProvider.overrideWithValue(true),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const MyEventsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Aisha is enrolled in evt-1 and evt-closed-deadline ('AI Research Symposium 2026')
      expect(find.text('RoboWars 2026'), findsWidgets);
      expect(find.text('AI Research Symposium 2026'), findsWidgets);
    });
  });
}
