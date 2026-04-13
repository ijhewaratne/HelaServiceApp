import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:home_service_app/main.dart' as app;

/// Worker flow integration tests - End-to-end worker onboarding and job acceptance
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Worker Onboarding Flow', () {
    testWidgets('complete worker registration journey', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Step 1: Navigate to worker registration
      await tester.tap(find.text('Become a Helper'));
      await tester.pumpAndSettle();

      // Step 2: Enter NIC
      expect(find.text('Enter Your NIC'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '123456789V');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3: Enter personal details
      expect(find.text('Personal Information'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), 'Kamal Perera');
      await tester.enterText(find.byType(TextField).at(1), '123 Galle Road, Colombo');
      await tester.enterText(find.byType(TextField).at(2), 'Sunil Perera');
      await tester.enterText(find.byType(TextField).at(3), '+94771234568');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 4: Select services
      expect(find.text('Select Your Services'), findsOneWidget);
      await tester.tap(find.text('Home Cleaning'));
      await tester.tap(find.text('Cooking Help'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 5: Upload documents (mock - just verify screen)
      expect(find.text('Upload Documents'), findsOneWidget);
      expect(find.text('NIC Front'), findsOneWidget);
      expect(find.text('NIC Back'), findsOneWidget);
      
      // Navigate back for now (file picker needs separate testing)
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
    });

    testWidgets('worker can toggle online status', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to worker section
      await tester.tap(find.text('I\'m a Helper'));
      await tester.pumpAndSettle();

      // Find online toggle
      expect(find.text('Go Online'), findsOneWidget);
      
      // Toggle online
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Should show location permission dialog or online status
      // This depends on implementation
    });

    testWidgets('worker can view job offers', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to worker home
      await tester.tap(find.text('I\'m a Helper'));
      await tester.pumpAndSettle();

      // Verify job offers section exists
      expect(find.text('Available Jobs'), findsOneWidget);
      
      // Check for job offer card or empty state
      final jobList = find.byType(ListView);
      if (jobList.evaluate().isNotEmpty) {
        // If jobs available, verify job card structure
        expect(find.text('Accept'), findsWidgets);
        expect(find.text('Decline'), findsWidgets);
      } else {
        // Verify empty state
        expect(find.text('No jobs available right now'), findsOneWidget);
      }
    });

    testWidgets('worker earnings dashboard is accessible', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to worker home
      await tester.tap(find.text('I\'m a Helper'));
      await tester.pumpAndSettle();

      // Navigate to earnings tab
      await tester.tap(find.byIcon(Icons.account_balance_wallet));
      await tester.pumpAndSettle();

      // Verify earnings screen
      expect(find.text('My Earnings'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('Total Earnings'), findsOneWidget);
    });
  });

  group('Worker Active Job Flow', () {
    testWidgets('worker can navigate to active job', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to worker home
      await tester.tap(find.text('I\'m a Helper'));
      await tester.pumpAndSettle();

      // Check for active job indicator
      final activeJobFinder = find.text('Active Job');
      if (activeJobFinder.evaluate().isNotEmpty) {
        await tester.tap(activeJobFinder);
        await tester.pumpAndSettle();

        // Verify active job screen
        expect(find.text('Job Details'), findsOneWidget);
        expect(find.text('Navigate to Customer'), findsOneWidget);
        expect(find.text('Mark as Arrived'), findsOneWidget);
      }
    });

    testWidgets('worker can complete job flow', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to worker section
      await tester.tap(find.text('I\'m a Helper'));
      await tester.pumpAndSettle();

      // Look for job completion button
      final completeButton = find.text('Complete Job');
      if (completeButton.evaluate().isNotEmpty) {
        await tester.tap(completeButton);
        await tester.pumpAndSettle();

        // Verify completion dialog
        expect(find.text('Confirm Job Completion'), findsOneWidget);
        
        // Enter final details
        await tester.enterText(find.byType(TextField).first, 'Job completed successfully');
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();
      }
    });
  });
}
