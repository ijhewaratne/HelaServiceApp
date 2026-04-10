import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/app.dart';

void main() {
  testWidgets('HelaServiceApp renders without error', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HelaServiceApp());

    // Verify that the app title is present
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
