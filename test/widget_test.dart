import 'package:campus_pulse/app/env.dart';
import 'package:campus_pulse/app/theme.dart';
import 'package:campus_pulse/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    await Env.load();
  });

  testWidgets('CampusPulse app boots in demo mode', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const CampusPulseApp(),
        ),
      ),
    );

    expect(find.text('CampusPulse'), findsWidgets);
  });
}
