import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_pulse/app/env.dart';
import 'package:campus_pulse/app/theme.dart';
import 'package:campus_pulse/app/providers.dart';
import 'package:campus_pulse/core/demo/demo_data_store.dart';
import 'package:campus_pulse/features/auth/data/demo_auth_repository.dart';
import 'package:campus_pulse/features/events/data/demo_event_repository.dart';
import 'package:campus_pulse/features/events/presentation/screens/event_details_screen.dart';

void main() {
  setUpAll(() async {
    await Env.load();
  });

  setUp(() => DemoDataStore.instance.resetForTests());

  testWidgets('Event details screen shows sections in the locked order',
      (tester) async {
    DemoDataStore.instance.currentUserId = 'demo-student-1';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventRepositoryProvider.overrideWithValue(DemoEventRepository()),
          currentProfileProvider.overrideWith((ref) => Stream.value(DemoAccounts.student)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const EventDetailsScreen(eventId: 'evt-1'),
        ),
      ),
    );

    // Let the FutureProviders resolve.
    await tester.pumpAndSettle();

    expect(find.text('RoboWars 2026'), findsOneWidget);
    expect(find.text('Main Auditorium'), findsOneWidget);
    expect(find.textContaining('Robotics & Automation Club'), findsOneWidget);
    expect(find.textContaining('About this event'), findsOneWidget);
    expect(find.text('Eligibility'), findsOneWidget);
    expect(find.text('Rules'), findsOneWidget);
    expect(find.text('Organizer contact'), findsOneWidget);

    // Confirm relative vertical order: name appears above venue,
    // venue above the description section header.
    final titleY = tester.getTopLeft(find.text('RoboWars 2026')).dy;
    final venueY = tester.getTopLeft(find.text('Main Auditorium')).dy;
    final aboutY = tester.getTopLeft(find.text('About this event')).dy;
    final eligibilityY = tester.getTopLeft(find.text('Eligibility')).dy;
    expect(titleY, lessThan(venueY));
    expect(venueY, lessThan(aboutY));
    expect(aboutY, lessThan(eligibilityY));
  });

  testWidgets('persistent action bar shows Enroll and Favourite',
      (tester) async {
    DemoDataStore.instance.currentUserId = 'demo-student-1';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventRepositoryProvider.overrideWithValue(DemoEventRepository()),
          currentProfileProvider.overrideWith((ref) => Stream.value(DemoAccounts.student)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const EventDetailsScreen(eventId: 'evt-3'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100)); // wait for profile
    await tester.pumpAndSettle();

    expect(find.text('Enroll'), findsOneWidget);
    expect(find.text('Favourite'), findsOneWidget);
  });
}
