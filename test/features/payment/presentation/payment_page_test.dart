import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';

import 'package:home_service_app/features/payment/presentation/pages/payment_page.dart';
import 'package:home_service_app/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:home_service_app/features/payment/domain/repositories/payment_repository.dart';

class MockPaymentRepository extends Mock implements PaymentRepository {}

// Gate 0: in-app payments (PayHere) are disabled for this MVP release — see
// payment_page_test.dart (in pages/) for the full rationale. This duplicate
// test file predates that change and asserted UI text ("Amount to Pay",
// "eZCash", "mCash") that did not even match the PaymentPage implementation
// current at the time; rewritten to test the actual, current disabled state
// rather than either the stale old assertions or the removed payment flow.
void main() {
  late MockPaymentRepository mockRepository;
  late PaymentBloc paymentBloc;

  setUp(() {
    mockRepository = MockPaymentRepository();
    paymentBloc = PaymentBloc(paymentRepository: mockRepository);
  });

  tearDown(() {
    paymentBloc.close();
  });

  Widget createTestableWidget({
    String bookingId = 'booking_123',
    int amount = 150000,
  }) {
    return MaterialApp(
      home: BlocProvider<PaymentBloc>.value(
        value: paymentBloc,
        child: PaymentPage(bookingId: bookingId, amount: amount),
      ),
    );
  }

  group('PaymentPage (Gate 0: payments disabled for MVP)', () {
    testWidgets('shows a clear "not available" message', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      expect(
        find.text('Payments are not available in this release.'),
        findsOneWidget,
      );
    });

    testWidgets('does not render the payment flow UI', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      expect(find.text('PAY NOW'), findsNothing);
      expect(find.text('Payment Methods'), findsNothing);
    });

    testWidgets('has a close button in the app bar', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('never calls the payment repository', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      verifyZeroInteractions(mockRepository);
    });
  });
}
