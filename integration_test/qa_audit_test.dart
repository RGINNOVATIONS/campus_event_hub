import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:campus_pulse/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const studentEmail = 'gurjot.singh2@nmims.in';
  const studentPass = 'g0YdSWJ3XFQEh4DkA1!';

  const organizerEmail = 'swapnil.mahajan@nmims.edu';
  const organizerPass = 'kzbJb6uOuSdoAkqA1!';

  const adminEmail = 'admin@nmims.edu';
  const adminPass = String.fromEnvironment('ADMIN_QA_PASSWORD');

  Future<void> waitForText(
      WidgetTester tester, String text, {Duration timeout = const Duration(seconds: 30)}) async {
    final deadline = DateTime.now().add(timeout);
    while (find.text(text).evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  Future<void> login(WidgetTester tester, String email, String password,
      String landingText) async {
    expect(password, isNotEmpty,
      reason: 'Missing QA password for $email. Supply it securely via ADMIN_QA_PASSWORD.');
    await tester.pump(const Duration(seconds: 3));
    final emailField = find.byType(TextFormField).first;
    final passField = find.byType(TextFormField).last;
    
    await tester.enterText(emailField, email);
    await tester.enterText(passField, password);
    await tester.pump(const Duration(seconds: 1));
    
    await tester.tap(find.text('Sign in').last);
    await waitForText(tester, landingText);
    expect(find.text(landingText), findsWidgets,
      reason:
        'Authentication or routing failed for $email; expected $landingText.');
  }

  Future<void> logout(WidgetTester tester) async {
    await tester.tap(find.text('Profile').last);
    await tester.pump(const Duration(seconds: 2));
    // Scroll down to reveal sign out
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Sign out').last);
    await tester.pump(const Duration(seconds: 5));
  }

  testWidgets('CampusPulse LIVE E2E QA Audit (All Roles)', (WidgetTester tester) async {
    app.main();
    
    // --- 1. STUDENT ---
    debugPrint('Testing Student Workflow...');
    await login(tester, studentEmail, studentPass, 'Upcoming Events');

    expect(find.text('Upcoming Events'), findsWidgets,
      reason: 'Student should see Upcoming Events on Home');

    // Browse Clubs is available from the student Profile destination.
    await tester.tap(find.text('Profile').last);
    await tester.pump(const Duration(seconds: 2));
    await tester.ensureVisible(find.text('Browse Clubs').last);
    await tester.tap(find.text('Browse Clubs').last);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Campus Clubs'), findsWidgets, reason: 'Student should be able to view Campus Clubs');
    await tester.tap(find.byTooltip('Back').last);
    await tester.pump(const Duration(seconds: 2));

    await logout(tester);

    // --- 2. ORGANIZER ---
    debugPrint('Testing Organizer Workflow...');
    await login(tester, organizerEmail, organizerPass, 'Organizer Dashboard');

    expect(find.text('Organizer Dashboard'), findsWidgets, reason: 'Organizer should see Dashboard');

    // Test My Events Tab
    await tester.tap(find.text('My Events').last);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Organizer Dashboard'), findsNothing, reason: 'Should have navigated away from Dashboard');
    expect(find.text('My Events'), findsWidgets,
      reason: 'Organizer should access My Events');

    await tester.tap(find.text('Scan').last);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Scan Attendance'), findsWidgets,
      reason: 'Organizer should access attendance scanning');

    await tester.tap(find.text('Profile').last);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Profile'), findsWidgets,
      reason: 'Organizer should access Profile');

    await logout(tester);

    // --- 3. ADMIN ---
    debugPrint('Testing Admin Workflow...');
    await login(tester, adminEmail, adminPass, 'Administrator Dashboard');
    
    // Test Pending Tab
    await tester.tap(find.text('Pending').last);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Pending Events'), findsWidgets, reason: 'Admin should see Pending Events');

    await tester.tap(find.text('Profile').last);
    await tester.pump(const Duration(seconds: 2));
    await tester.ensureVisible(find.text('Role').last);
    expect(find.text('Admin'), findsWidgets,
      reason: 'Authenticated Admin account should load the admin role.');
    
    await logout(tester);
  });
}
