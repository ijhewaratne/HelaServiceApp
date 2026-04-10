import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:home_service_app/features/worker/presentation/pages/online_toggle_page.dart';
import 'package:home_service_app/features/worker/presentation/bloc/worker_bloc.dart';

class MockWorkerBloc extends WorkerBloc {
  MockWorkerBloc() : super(
    workerRepository: MockWorkerRepository(),
    locationService: MockLocationService(),
  );
}

class MockWorkerRepository {}
class MockLocationService {}

void main() {
  late MockWorkerBloc workerBloc;

  setUp(() {
    workerBloc = MockWorkerBloc();
  });

  tearDown(() {
    workerBloc.close();
  });

  Widget createTestableWidget() {
    return MaterialApp(
      home: BlocProvider<WorkerBloc>.value(
        value: workerBloc,
        child: const OnlineTogglePage(),
      ),
    );
  }

  group('OnlineTogglePage', () {
    testWidgets('shows offline state initially', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      expect(find.text('HelaService Worker'), findsOneWidget);
      expect(find.text('You are OFFLINE'), findsOneWidget);
      expect(find.text('Go online to receive job offers'), findsOneWidget);
      expect(find.text('GO ONLINE'), findsOneWidget);
    });

    testWidgets('shows profile button in app bar', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      expect(find.byIcon(Icons.account_circle), findsOneWidget);
    });

    testWidgets('shows stats cards', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      expect(find.text("Today's Jobs"), findsOneWidget);
      expect(find.text('Earnings'), findsOneWidget);
      expect(find.text('Rating'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('LKR 0'), findsOneWidget);
      expect(find.text('4.0'), findsOneWidget);
    });

    testWidgets('toggles to online state', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      // Tap GO ONLINE button
      await tester.tap(find.text('GO ONLINE'));
      await tester.pump();

      // Should show loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      workerBloc.emit(WorkerLoading());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows online state', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      workerBloc.emit(WorkerOnlineStatusUpdated(isOnline: true));
      await tester.pump();

      expect(find.text('You are ONLINE'), findsOneWidget);
      expect(find.text('Waiting for job requests nearby...'), findsOneWidget);
      expect(find.text('GO OFFLINE'), findsOneWidget);
    });

    testWidgets('shows job offers button when online', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      workerBloc.emit(WorkerOnlineStatusUpdated(isOnline: true));
      await tester.pump();

      expect(find.text('View Job Offers'), findsOneWidget);
      expect(find.byIcon(Icons.work), findsOneWidget);
    });

    testWidgets('status indicator changes color when online', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      // Initial offline state
      var container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      var decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.grey);

      // Go online
      workerBloc.emit(WorkerOnlineStatusUpdated(isOnline: true));
      await tester.pump();

      container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.green);
    });

    testWidgets('shows error message', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      workerBloc.emit(WorkerError(message: 'Location permission denied'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Location permission denied'), findsOneWidget);
    });
  });
}
