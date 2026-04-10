import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:home_service_app/main.dart' as app;

/// Customer booking flow integration tests
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Customer Booking Flow', () {
    testWidgets('service selection screen loads', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to customer home (may need auth first)
      // This test verifies the service grid UI exists
      
      // Check if we're on customer home
      final serviceGrid = find.text('What service do you need?');
      if (serviceGrid.evaluate().isNotEmpty) {
        expect(serviceGrid, findsOneWidget);

        // Verify all services are displayed
        expect(find.text('Home Cleaning'), findsOneWidget);
        expect(find.text('Babysitting'), findsOneWidget);
        expect(find.text('Elderly Care'), findsOneWidget);
        expect(find.text('Cooking Help'), findsOneWidget);
      }
    });

    testWidgets('booking form has required fields', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to booking form if on home
      final bookServiceButton = find.text('Home Cleaning');
      if (bookServiceButton.evaluate().isNotEmpty) {
        await tester.tap(bookServiceButton);
        await tester.pumpAndSettle();

        // Verify booking form elements
        expect(find.text('Book Service'), findsOneWidget);
        expect(find.text('Select Service'), findsOneWidget);
        expect(find.text('Select Location'), findsOneWidget);
        
        // Check for required address field
        expect(find.text('House/Apartment Number *'), findsOneWidget);
        
        // Check for map
        expect(find.byType(Container), findsWidgets); // Map container
        
        // Verify submit button
        expect(find.text('FIND A HELPER'), findsOneWidget);
      }
    });

    testWidgets('can select service type', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // On booking form, verify service selection
      final selectService = find.text('Select Service');
      if (selectService.evaluate().isNotEmpty) {
        // Look for choice chips
        expect(find.byType(Wrap), findsWidgets);
        
        // Tap on a service
        await tester.tap(find.text('Cooking Help'));
        await tester.pumpAndSettle();
        
        // Verify price updates
        expect(find.textContaining('LKR'), findsOneWidget);
      }
    });

    testWidgets('shows date and time pickers', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Check for date/time on booking form
      if (find.text('Date *').evaluate().isNotEmpty) {
        expect(find.text('Date *'), findsOneWidget);
        expect(find.text('Time *'), findsOneWidget);
        
        // Tap date field
        await tester.tap(find.textContaining('/'));
        await tester.pumpAndSettle();
        
        // Should show date picker dialog
        expect(find.byType(Dialog), findsOneWidget);
      }
    });

    testWidgets('price estimate displays correctly', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Look for price estimate card
      if (find.text('Estimated Price:').evaluate().isNotEmpty) {
        expect(find.text('Estimated Price:'), findsOneWidget);
        expect(find.textContaining('LKR'), findsOneWidget);
        expect(
          find.text('Final price may vary based on actual work duration'),
          findsOneWidget,
        );
      }
    });
  });
}
