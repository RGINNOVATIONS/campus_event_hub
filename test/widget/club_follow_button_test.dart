import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_event_hub/app/env.dart';
import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/core/demo/demo_data_store.dart';
import 'package:campus_event_hub/features/auth/data/demo_auth_repository.dart';
import 'package:campus_event_hub/features/clubs/data/demo_club_repository.dart';
import 'package:campus_event_hub/features/events/data/demo_event_repository.dart';
import 'package:campus_event_hub/features/clubs/presentation/screens/club_details_screen.dart';

void main() {
  setUpAll(() async {
    await Env.load();
  });

  setUp(() => DemoDataStore.instance.resetForTests());

  testWidgets('Follow button toggles to Following and back', (tester) async {
    DemoDataStore.instance.currentUserId = 'demo-student-1';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clubRepositoryProvider.overrideWithValue(DemoClubRepository()),
          eventRepositoryProvider.overrideWithValue(DemoEventRepository()),
          currentProfileProvider.overrideWith((ref) => Stream.value(DemoAccounts.student)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const ClubDetailsScreen(clubId: 'club-ecell'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100)); // wait for profile
    await tester.pumpAndSettle();

    expect(find.text('Follow'), findsOneWidget);
    expect(find.text('Following'), findsNothing);

    await tester.tap(find.text('Follow'));
    await tester.pumpAndSettle();

    expect(find.text('Following'), findsOneWidget);
    expect(find.text('Follow'), findsNothing);

    await tester.tap(find.text('Following'));
    await tester.pumpAndSettle();

    expect(find.text('Follow'), findsOneWidget);
  });

  testWidgets('Already-followed club shows Following immediately',
      (tester) async {
    // club-cultural is followed by demo-student-1 in the seed data.
    DemoDataStore.instance.currentUserId = 'demo-student-1';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clubRepositoryProvider.overrideWithValue(DemoClubRepository()),
          eventRepositoryProvider.overrideWithValue(DemoEventRepository()),
          currentProfileProvider.overrideWith((ref) => Stream.value(DemoAccounts.student)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const ClubDetailsScreen(clubId: 'club-cultural'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100)); // wait for profile
    await tester.pumpAndSettle();

    expect(find.text('Following'), findsOneWidget);
  });

  testWidgets('Organizer does not see Follow button', (tester) async {
    DemoDataStore.instance.currentUserId = 'demo-org-1';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clubRepositoryProvider.overrideWithValue(DemoClubRepository()),
          eventRepositoryProvider.overrideWithValue(DemoEventRepository()),
          currentProfileProvider.overrideWith((ref) => Stream.value(DemoAccounts.organizer)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const ClubDetailsScreen(clubId: 'club-ecell'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100)); // wait for profile
    await tester.pumpAndSettle();

    expect(find.text('Follow'), findsNothing);
    expect(find.text('Following'), findsNothing);
  });

  testWidgets('Administrator does not see Follow button', (tester) async {
    DemoDataStore.instance.currentUserId = 'demo-admin';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clubRepositoryProvider.overrideWithValue(DemoClubRepository()),
          eventRepositoryProvider.overrideWithValue(DemoEventRepository()),
          currentProfileProvider.overrideWith((ref) => Stream.value(DemoAccounts.admin)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const ClubDetailsScreen(clubId: 'club-ecell'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100)); // wait for profile
    await tester.pumpAndSettle();

    expect(find.text('Follow'), findsNothing);
    expect(find.text('Following'), findsNothing);
  });
}
