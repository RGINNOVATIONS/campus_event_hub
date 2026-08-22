import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/core/demo/demo_data_store.dart';
import 'package:campus_event_hub/features/admin/data/demo_admin_repository.dart';
import 'package:campus_event_hub/features/admin/presentation/screens/admin_screens.dart';

void main() {
  setUp(() => DemoDataStore.instance.resetForTests());

  testWidgets('Pending events screen shows Approve and Reject actions',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminRepositoryProvider.overrideWithValue(DemoAdminRepository())
        ],
        child: MaterialApp(
            theme: AppTheme.dark, home: const PendingEventsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Drone Racing Trials'), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
  });

  testWidgets('Approving a pending event removes it from the pending list',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminRepositoryProvider.overrideWithValue(DemoAdminRepository())
        ],
        child: MaterialApp(
            theme: AppTheme.dark, home: const PendingEventsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Drone Racing Trials'), findsOneWidget);

    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();

    expect(find.text('Drone Racing Trials'), findsNothing);
    expect(find.text('Nothing pending review.'), findsOneWidget);
  });
}
