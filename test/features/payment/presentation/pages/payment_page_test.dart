import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:home_service_app/core/services/analytics_service.dart';
import 'package:home_service_app/features/payment/domain/repositories/payment_repository.dart';
import 'package:home_service_app/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:home_service_app/features/payment/presentation/pages/payment_page.dart';
import 'package:mockito/annotations.dart';

import 'payment_page_test.mocks.dart';

// Gate 0: in-app payments (PayHere) are disabled for this MVP release —
// PaymentPage now short-circuits to a "not available" message before ever
// touching PaymentBloc (see payment_page.dart's _paymentsEnabled flag). The
// previous version of this test file asserted the old payment-flow UI
// (amount, payment methods, "Pay Now" button), which no longer renders by
// design; these tests were rewritten to match what the screen actually does
// now rather than left failing against removed functionality.
@GenerateMocks([PaymentRepository, AnalyticsService])
void main() {
  late MockPaymentRepository mockRepository;
  late MockAnalyticsService mockAnalytics;

  setUp(() {
    mockRepository = MockPaymentRepository();
    mockAnalytics = MockAnalyticsService();
  });

  Widget createWidget({int amount = 150000}) {
    return MaterialApp(
      home: BlocProvider(
        create: (_) => PaymentBloc(
          paymentRepository: mockRepository,
          analytics: mockAnalytics,
        ),
        child: PaymentPage(bookingId: 'booking_123', amount: amount),
      ),
    );
  }

  group('PaymentPage (Gate 0: payments disabled for MVP)', () {
    testWidgets(
      'shows a clear "not available" message instead of the payment flow',
      (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(
          find.text('Payments are not available in this release.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('does not render a Pay Now button', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Pay Now'), findsNothing);
      expect(find.text('Select Payment Method'), findsNothing);
    });

    testWidgets('close button in the app bar still works', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('never calls the payment repository', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      verifyZeroInteractions(mockRepository);
    });
  });
}
