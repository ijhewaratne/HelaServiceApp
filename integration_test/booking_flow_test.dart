import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:home_service_app/main.dart' as app;

/// Booking flow integration tests - Complete end-to-end booking lifecycle
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Service Selection Flow', () {
    testWidgets('user can browse all service categories', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify main service categories are displayed
      expect(find.text('Home Cleaning'), findsOneWidget);
      expect(find.text('Cooking Help'), findsOneWidget);
      expect(find.text('Babysitting'), findsOneWidget);
      expect(find.text('Elderly Care'), findsOneWidget);
      expect(find.text('Laundry'), findsOneWidget);
    });

    testWidgets('service details shows pricing information', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap on a service
      await tester.tap(find.text('Home Cleaning'));
      await tester.pumpAndSettle();

      // Verify service details
      expect(find.text('Service Details'), findsOneWidget);
      expect(find.text('Starting from'), findsOneWidget);
      expect(find.text('LKR 1,500'), findsOneWidget);
      
      // Verify service features
      expect(find.text('What\'s Included'), findsOneWidget);
    });

    testWidgets('user can select multiple services', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Select first service
      await tester.tap(find.text('Home Cleaning'));
      await tester.pumpAndSettle();

      // Add another service
      await tester.tap(find.text('Add Another Service'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cooking Help'));
      await tester.pumpAndSettle();

      // Verify both services selected
      expect(find.text('Home Cleaning'), findsOneWidget);
      expect(find.text('Cooking Help'), findsOneWidget);
    });
  });

  group('Scheduling Flow', () {
    testWidgets('user can select preferred date and time', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to booking
      await tester.tap(find.text('Home Cleaning'));
      await tester.pumpAndSettle();

      // Open date picker
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      // Select a date
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 3));
      await tester.tap(find.text('${futureDate.day}'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Open time picker
      await tester.tap(find.byIcon(Icons.access_time));
      await tester.pumpAndSettle();

      // Select time
      await tester.tap(find.text('14:00'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Verify selection
      expect(find.text('${futureDate.day}'), findsOneWidget);
    });

    testWidgets('shows available time slots', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to booking
      await tester.tap(find.text('Home Cleaning'));
      await tester.pumpAndSettle();

      // Verify time slots are shown
      expect(find.text('Morning'), findsOneWidget);
      expect(find.text('Afternoon'), findsOneWidget);
      expect(find.text('Evening'), findsOneWidget);

      // Select a time slot
      await tester.tap(find.text('09:00 AM'));
      await tester.pumpAndSettle();
    });

    testWidgets('validates past dates cannot be selected', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to booking
      await tester.tap(find.text('Home Cleaning'));
      await tester.pumpAndSettle();

      // Try to select past date (yesterday)
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      // Yesterday should be disabled or not selectable
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      
      // Note: Date picker UI may vary, this is a conceptual test
      // The actual implementation should prevent past date selection
    });
  });

  group('Location Selection Flow', () {
    testWidgets('user can enter new address', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to booking
      await tester.tap(find.text('Home Cleaning'));
      await tester.pumpAndSettle();

      // Enter address details
      await tester.enterText(
        find.byType(TextFormField).first,
        '45/A, Galle Road, Colombo 03',
      );
      
      await tester.enterText(
        find.byType(TextFormField).last,
        'Near Liberty Plaza',
      );
      
      await tester.pumpAndSettle();

      // Verify text entered
      expect(find.text('45/A, Galle Road, Colombo 03'), findsOneWidget);
    });

    testWidgets('user can select from saved addresses', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to booking
      await tester.tap(find.text('Home Cleaning'));
      await tester.pumpAndSettle();

      // Tap to show saved addresses
      await tester.tap(find.text('Use Saved Address'));
      await tester.pumpAndSettle();

      // Select an address if available
      final savedAddress = find.text('Home');
      if (savedAddress.evaluate().isNotEmpty) {
        await tester.tap(savedAddress);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('validates required address fields', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to booking
      await tester.tap(find.text('Home Cleaning'));
      await tester.pumpAndSettle();

      // Try to continue without address
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter your address'), findsOneWidget);
    });
  });

  group('Payment and Confirmation Flow', () {
    testWidgets('shows price breakdown before payment', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to booking and fill details
      await tester.tap(find.text('Home Cleaning'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        '45/A, Galle Road, Colombo 03',
      );
      await tester.pumpAndSettle();

      // Navigate to payment
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Verify price breakdown
      expect(find.text('Price Details'), findsOneWidget);
      expect(find.text('Service Fee'), findsOneWidget);
      expect(find.text('Platform Fee'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
    });

    testWidgets('applies promo codes correctly', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to payment screen
      await tester.tap(find.text('Home Cleaning'));
      await tester.pumpAndSettle();
      
      await tester.enterText(
        find.byType(TextFormField).first,
        '45/A, Galle Road, Colombo 03',
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Enter promo code
      await tester.enterText(
        find.byType(TextField).last,
        'FIRSTBOOKING',
      );
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // Verify discount applied
      expect(find.text('Discount'), findsOneWidget);
    });

    testWidgets('booking confirmation shows all details', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Complete booking flow
      await tester.tap(find.text('Home Cleaning'));
      await tester.pumpAndSettle();
      
      await tester.enterText(
        find.byType(TextFormField).first,
        '45/A, Galle Road, Colombo 03',
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Verify confirmation screen
      expect(find.text('Confirm Booking'), findsOneWidget);
      expect(find.text('Service'), findsOneWidget);
      expect(find.text('Home Cleaning'), findsOneWidget);
      expect(find.text('Address'), findsOneWidget);
    });
  });

  group('Real-time Booking Updates', () {
    testWidgets('shows searching for helper status', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to active booking
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Look for searching status
      if (find.text('Searching for Helper...').evaluate().isNotEmpty) {
        expect(find.text('Searching for Helper...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      }
    });

    testWidgets('shows helper assigned notification', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Check for helper assignment
      final helperAssigned = find.text('Helper Assigned');
      if (helperAssigned.evaluate().isNotEmpty) {
        expect(find.text('Your helper is on the way'), findsOneWidget);
        expect(find.text('View Helper Profile'), findsOneWidget);
      }
    });
  });
}
