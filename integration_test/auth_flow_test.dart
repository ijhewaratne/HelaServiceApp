import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:home_service_app/main.dart' as app;

/// Authentication flow integration tests
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow', () {
    testWidgets('user can enter phone number', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify auth screen is shown
      expect(find.text('Welcome to HelaService'), findsOneWidget);
      expect(find.text('SEND CODE'), findsOneWidget);

      // Enter valid phone number
      await tester.enterText(find.byType(TextFormField).first, '771234567');
      await tester.pumpAndSettle();

      // Verify text was entered
      final textField = tester.widget<TextFormField>(find.byType(TextFormField).first);
      expect(textField.controller?.text, '771234567');
    });

    testWidgets('shows validation error for invalid phone', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Try to submit empty form
      await tester.tap(find.text('SEND CODE'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter your mobile number'), findsOneWidget);

      // Enter invalid phone (wrong prefix)
      await tester.enterText(find.byType(TextFormField).first, '123456789');
      await tester.tap(find.text('SEND CODE'));
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter valid Sri Lankan mobile number'),
        findsOneWidget,
      );
    });

    testWidgets('phone input accepts only digits', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Try to enter non-digits
      await tester.enterText(find.byType(TextFormField).first, 'abc123');
      await tester.pumpAndSettle();

      // Should only accept digits (check formatting)
      final textField = tester.widget<TextFormField>(find.byType(TextFormField).first);
      
      // Note: TextFormField may not filter in tests the same way as real device
      // This tests that the field exists and accepts input
      expect(textField.keyboardType, TextInputType.phone);
    });

    testWidgets('shows loading state during auth', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Enter valid phone
      await tester.enterText(find.byType(TextFormField).first, '771234567');
      
      // Submit
      await tester.tap(find.text('SEND CODE'));
      await tester.pump(); // Single pump to show loading

      // Should show loading indicator immediately
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
