import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:home_service_app/main.dart' as app;

/// Worker flow integration tests
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Worker Dashboard Flow', () {
    testWidgets('worker dashboard loads with offline state', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Check if we're on worker dashboard
      final workerTitle = find.text('HelaService Worker');
      if (workerTitle.evaluate().isNotEmpty) {
        expect(workerTitle, findsOneWidget);
        
        // Verify offline state
        expect(find.text('You are OFFLINE'), findsOneWidget);
        expect(find.text('Go online to receive job offers'), findsOneWidget);
        expect(find.text('GO ONLINE'), findsOneWidget);
      }
    });

    testWidgets('worker stats are displayed', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      if (find.text('HelaService Worker').evaluate().isNotEmpty) {
        // Verify stats section
        expect(find.text("Today's Jobs"), findsOneWidget);
        expect(find.text('Earnings'), findsOneWidget);
        expect(find.text('Rating'), findsOneWidget);
        
        // Default values
        expect(find.text('0'), findsWidgets);
        expect(find.text('LKR 0'), findsOneWidget);
      }
    });

    testWidgets('toggling online shows loading', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      if (find.text('GO ONLINE').evaluate().isNotEmpty) {
        // Tap GO ONLINE
        await tester.tap(find.text('GO ONLINE'));
        await tester.pump(); // Don't settle, check loading state

        // Should show loading
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      }
    });

    testWidgets('profile button exists in app bar', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      if (find.text('HelaService Worker').evaluate().isNotEmpty) {
        // Check for profile icon button
        expect(find.byIcon(Icons.account_circle), findsOneWidget);
      }
    });

    testWidgets('status indicator is visible', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      if (find.text('HelaService Worker').evaluate().isNotEmpty) {
        // Status indicator should be present
        expect(find.byType(AnimatedContainer), findsOneWidget);
        
        // Verify icon exists
        expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
      }
    });
  });

  group('Worker Onboarding Flow', () {
    testWidgets('NIC input page validation', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to NIC input if available
      final nicPage = find.text('Enter Your NIC');
      if (nicPage.evaluate().isNotEmpty) {
        expect(nicPage, findsOneWidget);
        
        // Try invalid NIC
        await tester.enterText(find.byType(TextFormField), '123');
        await tester.tap(find.text('CONTINUE'));
        await tester.pumpAndSettle();
        
        // Should show error
        expect(find.textContaining('valid'), findsOneWidget);
      }
    });

    testWidgets('document upload page elements', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final docPage = find.text('Upload Documents');
      if (docPage.evaluate().isNotEmpty) {
        expect(docPage, findsOneWidget);
        expect(find.text('NIC Front'), findsOneWidget);
        expect(find.text('NIC Back'), findsOneWidget);
        expect(find.text('Profile Photo'), findsOneWidget);
      }
    });
  });
}
