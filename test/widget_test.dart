import 'package:campus_event_hub/app/env.dart';
import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fakes/fakes.dart';

void main() {
  setUpAll(() async {
    await Env.load();
  });

  setUp(() => FakeDataStore.instance.resetForTests());

  testWidgets('Campus Event Hub app boots', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          eventRepositoryProvider.overrideWithValue(FakeEventRepository()),
          notificationServiceProvider.overrideWithValue(FakeNotificationService(
            tokenRepository: FakeDeviceTokenRepository(),
            currentUserId: () => null,
          )),
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
