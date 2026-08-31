import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/features/worker/domain/repositories/worker_repository.dart';
import 'package:home_service_app/features/worker/presentation/bloc/worker_onboarding_bloc.dart';
import 'package:home_service_app/features/worker/presentation/pages/nic_input_page.dart';
import 'package:mockito/annotations.dart';

import 'nic_input_page_test.mocks.dart';

@GenerateMocks([WorkerRepository])
void main() {
  late MockWorkerRepository mockRepository;

  setUp(() {
    mockRepository = MockWorkerRepository();
  });

  Widget createWidget() {
    return MaterialApp(
      home: BlocProvider(
        create: (_) => WorkerOnboardingBloc(repository: mockRepository),
        child: NICInputPage(),
      ),
    );
  }

  group('NICInputPage', () {
    testWidgets('renders correctly with all required elements', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('Worker Registration'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(6));
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('shows validation error for empty NIC', (tester) async {
      await tester.pumpWidget(createWidget());

      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('NIC is required'), findsOneWidget);
    });

    testWidgets('accepts valid old format NIC', (tester) async {
      await tester.pumpWidget(createWidget());

      await tester.enterText(find.byType(TextFormField).first, '123456789V');
      await tester.pump();

      expect(
        find.text(
          'Enter valid Sri Lankan NIC (e.g., 853202937V or 198532029372)',
        ),
        findsNothing,
      );
    });
  });
}
