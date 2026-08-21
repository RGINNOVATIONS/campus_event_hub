import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_pulse/app/theme.dart';
import 'package:campus_pulse/core/domain/enums.dart';
import 'package:campus_pulse/features/events/domain/event.dart';
import 'package:campus_pulse/features/events/presentation/widgets/event_card.dart';

EventModel _event() => EventModel(
      id: 'e1',
      clubId: 'c1',
      clubName: 'Robotics Club',
      categoryId: 'cat1',
      categoryName: 'Technical',
      title: 'RoboWars',
      shortDescription: 'short',
      fullDescription: 'full',
      venue: 'Main Auditorium',
      startAt: DateTime(2026, 9, 10, 14, 30),
      endAt: DateTime(2026, 9, 10, 18),
      registrationDeadline: DateTime(2026, 9, 5),
      eligibility: 'All years',
      rules: 'No rules',
      contactName: 'Organizer',
      contactEmail: 'organizer@college.edu.example',
      status: EventStatus.published,
    );

void main() {
  testWidgets('EventCard renders title, venue and club/category tags',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: EventCard(
          event: _event(),
          isFavourite: false,
          onTap: () {},
          onToggleFavourite: () {},
        ),
      ),
    ));

    expect(find.text('RoboWars'), findsOneWidget);
    expect(find.text('Main Auditorium'), findsOneWidget);
    expect(find.text('Robotics Club'), findsOneWidget);
    expect(find.text('Technical'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
  });

  testWidgets('tapping the favourite heart calls onToggleFavourite',
      (tester) async {
    var toggled = false;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: EventCard(
          event: _event(),
          isFavourite: false,
          onTap: () {},
          onToggleFavourite: () => toggled = true,
        ),
      ),
    ));

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();
    expect(toggled, isTrue);
  });

  testWidgets('favourited state shows filled heart', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: EventCard(
          event: _event(),
          isFavourite: true,
          onTap: () {},
          onToggleFavourite: () {},
        ),
      ),
    ));
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });

  testWidgets('tapping the card body calls onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: EventCard(
          event: _event(),
          isFavourite: false,
          onTap: () => tapped = true,
          onToggleFavourite: () {},
        ),
      ),
    ));
    await tester.tap(find.text('RoboWars'));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
