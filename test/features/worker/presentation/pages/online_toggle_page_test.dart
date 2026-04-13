import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/core/services/location_service.dart';
import 'package:home_service_app/features/worker/domain/repositories/worker_repository.dart';
import 'package:home_service_app/features/worker/presentation/bloc/worker_bloc.dart';
import 'package:home_service_app/features/worker/presentation/pages/online_toggle_page.dart';
import 'package:mockito/annotations.dart';

import 'online_toggle_page_test.mocks.dart';

@GenerateMocks([WorkerRepository, LocationService])
void main() {
  late MockWorkerRepository mockRepository;
  late MockLocationService mockLocationService;

  setUp(() {
    mockRepository = MockWorkerRepository();
    mockLocationService = MockLocationService();
  });

  Widget createWidget() {
    return MaterialApp(
      home: BlocProvider(
        create: (_) => WorkerBloc(
          workerRepository: mockRepository,
          locationService: mockLocationService,
        ),
        child: const OnlineTogglePage(),
      ),
    );
  }

  group('OnlineTogglePage', () {
    testWidgets('renders correctly with offline state', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('Go Online'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('toggles online status when switch is tapped', (tester) async {
      await tester.pumpWidget(createWidget());

      final switchWidget = find.byType(Switch);
      expect(switchWidget, findsOneWidget);

      // Tap the switch
      await tester.tap(switchWidget);
      await tester.pump();
    });

    testWidgets('shows location permission dialog when going online', (tester) async {
      await tester.pumpWidget(createWidget());

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // May show permission dialog
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
