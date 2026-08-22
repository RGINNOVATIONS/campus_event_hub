import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/core/demo/demo_data_store.dart';
import 'package:campus_event_hub/features/auth/data/demo_auth_repository.dart';
import 'package:campus_event_hub/features/events/data/demo_event_repository.dart';
import 'package:campus_event_hub/features/events/presentation/screens/event_details_screen.dart';
import 'package:campus_event_hub/features/events/presentation/controllers/events_controllers.dart';

void main() {
  setUp(() => DemoDataStore.instance.resetForTests());

  testWidgets('Enroll button becomes View QR once the user is enrolled',
      (tester) async {
    DemoDataStore.instance.currentUserId = 'demo-student-1';
    final repo = DemoEventRepository();
    final container = ProviderContainer(overrides: [
      eventRepositoryProvider.overrideWithValue(repo),
      currentProfileProvider.overrideWith((ref) => Stream.value(DemoAccounts.student)),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const EventDetailsScreen(eventId: 'evt-3'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100)); // wait for profile
    await tester.pumpAndSettle();
    expect(find.text('Enroll'), findsOneWidget);
    expect(find.text('View QR'), findsNothing);

    // Drive the enrolment directly through the controller (avoids
    // exercising go_router's context.push, which needs a real router
    // in the widget tree).
    await container.read(enrolmentsProvider.notifier).enrol('evt-3');
    await tester.pumpAndSettle();

    expect(find.text('View QR'), findsOneWidget);
    expect(find.text('Enroll'), findsNothing);
  });

  testWidgets('Organizer does not see Enroll button', (tester) async {
    DemoDataStore.instance.currentUserId = 'demo-org-1';
    final repo = DemoEventRepository();
    final container = ProviderContainer(overrides: [
      eventRepositoryProvider.overrideWithValue(repo),
      currentProfileProvider.overrideWith((ref) => Stream.value(DemoAccounts.organizer)),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const EventDetailsScreen(eventId: 'evt-1'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100)); // wait for profile
    await tester.pumpAndSettle();

    expect(find.text('Enroll'), findsNothing);
    expect(find.text('View QR'), findsNothing);
  });

  testWidgets('Administrator does not see Enroll button', (tester) async {
    DemoDataStore.instance.currentUserId = 'demo-admin';
    final repo = DemoEventRepository();
    final container = ProviderContainer(overrides: [
      eventRepositoryProvider.overrideWithValue(repo),
      currentProfileProvider.overrideWith((ref) => Stream.value(DemoAccounts.admin)),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const EventDetailsScreen(eventId: 'evt-1'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100)); // wait for profile
    await tester.pumpAndSettle();

    expect(find.text('Enroll'), findsNothing);
    expect(find.text('View QR'), findsNothing);
  });
}
