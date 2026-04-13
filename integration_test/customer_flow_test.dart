import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:home_service_app/main.dart' as app;

/// Customer flow integration tests - End-to-end customer booking journey
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Customer Booking Flow', () {
    testWidgets('complete booking journey', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Step 1: Navigate to booking
      await tester.tap(find.text('Book Now'));
      await tester.pumpAndSettle();

      // Step 2: Select service type
      expect(find.text('Select Service'), findsOneWidget);
      await tester.tap(find.text('Home Cleaning'));
      await tester.pumpAndSettle();

      // Step 3: Select date and time
      expect(find.text('Schedule'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();
      
      // Select tomorrow
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      await tester.tap(find.text('${tomorrow.day}'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Select time
      await tester.tap(find.byIcon(Icons.access_time));
      await tester.pumpAndSettle();
      await tester.tap(find.text('10:00'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Step 4: Enter address
      await tester.enterText(find.byType(TextFormField).first, '45/A, Galle Road, Colombo 03');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 5: Review and confirm
      expect(find.text('Confirm Booking'), findsOneWidget);
      expect(find.text('Estimated Price'), findsOneWidget);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
    });

    testWidgets('customer can search services', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap search bar
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Enter search term
      await tester.enterText(find.byType(TextField).first, 'cleaning');
      await tester.pumpAndSettle();

      // Verify search results
      expect(find.text('Home Cleaning'), findsOneWidget);
    });

    testWidgets('customer can view booking history', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to bookings tab
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Verify bookings screen
      expect(find.text('My Bookings'), findsOneWidget);
      
      // Check for tabs
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
    });

    testWidgets('customer can cancel a booking', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to bookings
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Look for cancel button on first booking
      final cancelButton = find.text('Cancel');
      if (cancelButton.evaluate().isNotEmpty) {
        await tester.tap(cancelButton.first);
        await tester.pumpAndSettle();

        // Confirm cancellation
        expect(find.text('Cancel Booking'), findsOneWidget);
        await tester.tap(find.text('Yes, Cancel'));
        await tester.pumpAndSettle();

        // Verify cancellation
        expect(find.text('Booking Cancelled'), findsOneWidget);
      }
    });

    testWidgets('customer can rate completed service', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to bookings
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Switch to completed tab
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      // Look for rate button
      final rateButton = find.text('Rate');
      if (rateButton.evaluate().isNotEmpty) {
        await tester.tap(rateButton.first);
        await tester.pumpAndSettle();

        // Rate with stars
        await tester.tap(find.byIcon(Icons.star).at(4)); // 5 stars
        await tester.enterText(find.byType(TextField).first, 'Excellent service!');
        await tester.tap(find.text('Submit'));
        await tester.pumpAndSettle();

        // Verify rating submitted
        expect(find.text('Thank you for your feedback!'), findsOneWidget);
      }
    });
  });

  group('Customer Profile Flow', () {
    testWidgets('customer can view and edit profile', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to profile
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // Verify profile screen
      expect(find.text('My Profile'), findsOneWidget);
      
      // Edit profile
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Update name
      await tester.enterText(find.byType(TextField).first, 'John Updated');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
    });

    testWidgets('customer can manage saved addresses', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to profile
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // Navigate to addresses
      await tester.tap(find.text('Saved Addresses'));
      await tester.pumpAndSettle();

      // Add new address
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Enter address details
      await tester.enterText(find.byType(TextField).at(0), 'Home');
      await tester.enterText(find.byType(TextField).at(1), '123 New Address, Colombo');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
    });

    testWidgets('customer can view payment methods', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to profile
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // Navigate to payment methods
      await tester.tap(find.text('Payment Methods'));
      await tester.pumpAndSettle();

      // Verify payment methods screen
      expect(find.text('Payment Methods'), findsOneWidget);
      expect(find.text('Visa/Mastercard'), findsOneWidget);
    });
  });

  group('Customer Support Flow', () {
    testWidgets('customer can access help center', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to profile
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // Navigate to help
      await tester.tap(find.text('Help & Support'));
      await tester.pumpAndSettle();

      // Verify help screen
      expect(find.text('Help Center'), findsOneWidget);
      expect(find.text('FAQs'), findsOneWidget);
    });

    testWidgets('customer can chat with support', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to profile
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // Open chat support
      await tester.tap(find.text('Chat with Us'));
      await tester.pumpAndSettle();

      // Verify chat screen
      expect(find.text('Support Chat'), findsOneWidget);
      
      // Send message
      await tester.enterText(find.byType(TextField).first, 'I need help with my booking');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
    });
  });
}
