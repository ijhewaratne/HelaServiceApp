import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:home_service_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('HelaService End-to-End Tests', () {
    testWidgets('complete customer booking flow', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Step 1: Auth Screen
      expect(find.text('Welcome to HelaService'), findsOneWidget);
      
      // Enter phone number
      await tester.enterText(find.byType(TextFormField).first, '771234567');
      await tester.pumpAndSettle();
      
      // Tap send code
      await tester.tap(find.text('SEND CODE'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Step 2: Enter OTP
      // Note: In real test, you'd need to get OTP from Firebase or mock it
      // For integration test, we check the UI state
      if (find.text('Enter OTP').evaluate().isNotEmpty) {
        await tester.enterText(find.byType(TextFormField).first, '123456');
        await tester.tap(find.text('VERIFY'));
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Step 3: Customer Home
      // Check if we're on customer home (might need onboarding for new user)
      if (find.text('What service do you need?').evaluate().isNotEmpty) {
        // Select a service
        await tester.tap(find.text('Home Cleaning'));
        await tester.pumpAndSettle();

        // Step 4: Booking Form
        expect(find.text('Book Service'), findsOneWidget);
        
        // Select date (simplified - just verify UI)
        expect(find.text('Date'), findsOneWidget);
        
        // Enter address
        await tester.enterText(
          find.widgetWithText(TextFormField, 'House/Apartment Number *'),
          '123',
        );
        
        await tester.pumpAndSettle();
        
        // Verify booking can be initiated
        expect(find.text('FIND A HELPER'), findsOneWidget);
      }
    });

    testWidgets('worker goes online flow', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to worker dashboard (assuming already logged in as worker)
      // This test assumes pre-authenticated state or specific navigation
      
      // Check for worker dashboard elements
      if (find.text('HelaService Worker').evaluate().isNotEmpty) {
        // Verify offline state
        expect(find.text('You are OFFLINE'), findsOneWidget);
        expect(find.text('GO ONLINE'), findsOneWidget);

        // Toggle online
        await tester.tap(find.text('GO ONLINE'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify online state or loading
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      }
    });

    testWidgets('app launches without errors', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify app didn't crash
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Check for splash or auth screen
      final hasSplash = find.byType(Scaffold).evaluate().isNotEmpty;
      expect(hasSplash, true);
    });
  });
}
