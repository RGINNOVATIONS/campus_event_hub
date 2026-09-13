import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_event_hub/app/env.dart';
import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/core/demo/demo_data_store.dart';
import 'package:campus_event_hub/features/events/data/demo_event_repository.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';
import 'package:campus_event_hub/features/organizer/data/demo_organizer_repository.dart';
import 'package:campus_event_hub/features/organizer/domain/organizer_repository.dart';
import 'package:campus_event_hub/features/organizer/presentation/screens/create_event_screen.dart';

void main() {
  setUpAll(() async {
    await Env.load();
  });

  setUp(() {
    DemoDataStore.instance.resetForTests();
  });

  testWidgets(
      'create event with 2 guests, edit ONLY venue in CreateEventScreen, assert guests preserved',
      (tester) async {
    DemoDataStore.instance.currentUserId = 'demo-organizer-1';
    final repo = DemoOrganizerRepository();
    final now = DateTime.now().add(const Duration(days: 5));

    // 1. Create an initial event with 2 structured guests
    final createResult = await repo.saveDraft(DraftEventInput(
      categoryId: 'cat-technical',
      title: 'Robotics Workshop 2026',
      shortDescription: 'Hands-on robotics build and battle',
      fullDescription: 'Detailed session on microcontrollers and motors.',
      venue: 'Lab 101',
      startAt: now.add(const Duration(days: 2)),
      endAt: now.add(const Duration(days: 2, hours: 3)),
      registrationDeadline: now.add(const Duration(days: 1)),
      eligibility: 'Open to all years',
      rules: 'Bring laptops',
      contactName: 'Faculty In-Charge',
      contactEmail: 'fic@college.edu',
      guests: const [
        EventGuest(
          name: 'Dr. Katherine Vance',
          designation: 'Distinguished Professor',
          organization: 'Robotics Institute',
        ),
        EventGuest(
          name: 'Marcus Chen',
          designation: 'Principal Engineer',
          organization: 'Cybernetics Corp',
        ),
      ],
    ));

    expect(createResult.isOk, isTrue);
    final createdEvent = createResult.valueOrNull!;
    expect(createdEvent.guests.length, 2);
    expect(createdEvent.venue, 'Lab 101');

    // 2. Open CreateEventScreen in EDIT mode with this existing event
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventRepositoryProvider.overrideWithValue(DemoEventRepository()),
          organizerRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: CreateEventScreen(existing: createdEvent),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 3. Verify both guests are populated in the edit form UI
    expect(find.text('Dr. Katherine Vance'), findsOneWidget);
    expect(find.text('Marcus Chen'), findsOneWidget);

    // 4. Edit ONLY the venue field (touching zero guest fields)
    final venueField = find.widgetWithText(TextFormField, 'Venue / Location');
    expect(venueField, findsOneWidget);
    await tester.enterText(venueField, 'Grand Hall - Zone B');
    await tester.pumpAndSettle();

    // 5. Scroll down to and tap "Save Draft" or "Save Changes"
    final saveButton = find.text(createdEvent.status.name == 'published'
        ? 'Save Changes'
        : 'Save Draft');
    expect(saveButton, findsOneWidget);
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // 6. Retrieve the event from DemoDataStore and verify guests are STILL PRESENT
    final persisted = DemoDataStore.instance.events
        .firstWhere((e) => e.id == createdEvent.id);
    expect(persisted.venue, 'Grand Hall - Zone B',
        reason: 'Venue was edited and updated');
    expect(persisted.guests.length, 2,
        reason: 'Guests must be preserved when editing only the venue');
    expect(persisted.guests[0].name, 'Dr. Katherine Vance');
    expect(persisted.guests[0].designation, 'Distinguished Professor');
    expect(persisted.guests[0].organization, 'Robotics Institute');
    expect(persisted.guests[1].name, 'Marcus Chen');
    expect(persisted.guests[1].designation, 'Principal Engineer');
    expect(persisted.guests[1].organization, 'Cybernetics Corp');
  });
}
