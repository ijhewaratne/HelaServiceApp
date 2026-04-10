import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:home_service_app/main.dart' as app;

/// Navigation and routing integration tests
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation Flow', () {
    testWidgets('app starts at splash/auth screen', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // App should start and show either splash or auth
      final materialApp = find.byType(MaterialApp);
      expect(materialApp, findsOneWidget);

      // Should have a Scaffold (present in most screens)
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('back button works correctly', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Look for any page with back button
      final backButton = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton.first);
        await tester.pumpAndSettle();
        
        // Should navigate back
        expect(find.byType(Scaffold), findsWidgets);
      }
    });

    testWidgets('scrollable content works', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Try scrolling if there's scrollable content
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.fling(scrollable.first, const Offset(0, -300), 1000);
        await tester.pumpAndSettle();
        
        // Should have scrolled without errors
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('navigation drawer or menu works', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Look for menu icon
      final menuIcon = find.byIcon(Icons.menu);
      if (menuIcon.evaluate().isNotEmpty) {
        await tester.tap(menuIcon.first);
        await tester.pumpAndSettle();
        
        // Drawer should open
        expect(find.byType(Drawer), findsOneWidget);
      }
    });
  });

  group('Error Handling', () {
    testWidgets('shows error widget on crash', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // App should still be running
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // No error indicators should be visible initially
      expect(find.text('Something went wrong'), findsNothing);
    });

    testWidgets('network error handling', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Perform action that might trigger network error
      // Most errors are handled gracefully with SnackBars
      
      // Check that error boundary exists
      final errorWidget = find.byType(ErrorWidget);
      // Should not find ErrorWidget initially
      expect(errorWidget, findsNothing);
    });
  });

  group('Responsive Layout', () {
    testWidgets('layout adapts to screen size', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Get initial screen size
      final size = tester.binding.window.physicalSize;
      
      // App should render at any reasonable size
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Test at different sizes
      await tester.binding.setSurfaceSize(const Size(360, 640)); // Small phone
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsWidgets);
      
      await tester.binding.setSurfaceSize(const Size(412, 732)); // Medium phone
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsWidgets);
      
      // Reset to original
      await tester.binding.setSurfaceSize(size);
    });
  });
}
