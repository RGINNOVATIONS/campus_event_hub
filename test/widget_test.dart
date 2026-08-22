import 'package:campus_event_hub/app/env.dart';
import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    await Env.load();
  });

  testWidgets('Campus Event Hub app boots in demo mode', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          demoModeProvider.overrideWithValue(true),
        ],
        child: const CampusEventHubApp(),
      ),
    );

    // Give go_router a frame to push the initial route
    await tester.pump();
    // Give LoginScreen a frame to render
    await tester.pump(const Duration(seconds: 1));
    
    expect(find.text('Campus Event Hub'), findsWidgets);
  });
}
