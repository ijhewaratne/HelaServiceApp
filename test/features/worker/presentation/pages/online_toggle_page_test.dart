import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/core/services/location_service.dart';
import 'package:home_service_app/injection_container.dart';
import 'package:home_service_app/features/worker/presentation/pages/online_toggle_page.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'online_toggle_page_test.mocks.dart';

@GenerateMocks([LocationService])
void main() {
  late MockLocationService mockLocationService;

  setUp(() async {
    await sl.reset();
    mockLocationService = MockLocationService();
    sl.registerSingleton<LocationService>(mockLocationService);
    when(mockLocationService.startTracking(any)).thenAnswer((_) async {});
    when(mockLocationService.stopTracking()).thenAnswer((_) async {});
  });

  tearDown(() async => sl.reset());

  Widget createWidget() => const MaterialApp(home: OnlineTogglePage());

  group('OnlineTogglePage', () {
    testWidgets('renders correctly with offline state', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('Go Online'), findsOneWidget);
      expect(find.text('You are Offline'), findsOneWidget);
      expect(find.text('GO ONLINE'), findsOneWidget);
    });

    testWidgets('calls startTracking when GO ONLINE is tapped', (tester) async {
      await tester.pumpWidget(createWidget());

      await tester.tap(find.text('GO ONLINE'));
      await tester.pumpAndSettle();

      // The worker ID comes from FirebaseAuth.currentUser?.uid — in tests
      // Firebase is not initialized so uid is '' or null-safe fallback ''.
      verify(mockLocationService.startTracking(any)).called(1);
    });
  });
}
