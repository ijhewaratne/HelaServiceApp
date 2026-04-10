import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:mockito/mockito.dart';

import 'package:home_service_app/features/payment/presentation/pages/payment_page.dart';
import 'package:home_service_app/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:home_service_app/features/payment/domain/repositories/payment_repository.dart';
import 'package:home_service_app/features/payment/domain/entities/payment_result.dart';

class MockPaymentRepository extends Mock implements PaymentRepository {}

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
        child: PaymentPage(
          bookingId: bookingId,
          amount: amount,
        ),
      ),
    );
  }

  group('PaymentPage', () {
    testWidgets('shows payment summary initially', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      expect(find.text('Payment'), findsOneWidget);
      expect(find.text('Amount to Pay'), findsOneWidget);
      expect(find.text('LKR 1,500.00'), findsOneWidget);
      expect(find.text('PAY NOW'), findsOneWidget);
    });

    testWidgets('shows payment methods', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      expect(find.text('Payment Methods'), findsOneWidget);
      expect(find.text('Visa/Master'), findsOneWidget);
      expect(find.text('Bank'), findsOneWidget);
      expect(find.text('eZCash'), findsOneWidget);
      expect(find.text('mCash'), findsOneWidget);
    });

    testWidgets('shows disclaimer about final price', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      expect(
        find.text('Final price may vary based on actual work duration'),
        findsOneWidget,
      );
    });

    testWidgets('shows processing state', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      paymentBloc.emit(PaymentProcessing());
      await tester.pump();

      expect(find.text('Processing payment...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.text('Please complete the payment in the PayHere window'),
        findsOneWidget,
      );
    });

    testWidgets('shows success state', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      paymentBloc.emit(PaymentSuccess(
        payment: PaymentResult.success(
          paymentId: 'pay_123',
          orderId: 'booking_123',
          amount: 1500.0,
        ),
      ));
      await tester.pump();

      expect(find.text('Payment Successful!'), findsOneWidget);
      expect(find.text('Payment ID: pay_123'), findsOneWidget);
      expect(find.text('LKR 1,500.00'), findsOneWidget);
    });

    testWidgets('shows failure state with retry', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      paymentBloc.emit(PaymentFailed(
        message: 'Payment cancelled by user',
        status: PaymentStatus.cancelled,
      ));
      await tester.pump();

      expect(find.text('Payment Failed'), findsOneWidget);
      expect(find.text('Payment cancelled by user'), findsOneWidget);
      expect(find.text('TRY AGAIN'), findsOneWidget);
    });

    testWidgets('shows error state', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      paymentBloc.emit(PaymentError(message: 'Network error'));
      await tester.pump();

      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);
    });

    testWidgets('initiates payment when button pressed', (tester) async {
      when(mockRepository.processPayment(
        bookingId: anyNamed('bookingId'),
        amount: anyNamed('amount'),
        customerName: anyNamed('customerName'),
        customerPhone: anyNamed('customerPhone'),
        customerEmail: anyNamed('customerEmail'),
      )).thenAnswer((_) async => Right(PaymentResult.success(
        paymentId: 'pay_123',
        orderId: 'booking_123',
      )));

      await tester.pumpWidget(createTestableWidget());

      await tester.tap(find.text('PAY NOW'));
      await tester.pump();

      // Should show loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays correct amount formatting', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        amount: 250000, // LKR 2,500
      ));

      expect(find.text('LKR 2,500.00'), findsOneWidget);
    });

    testWidgets('shows Secured by PayHere footer', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      expect(find.text('Secured by PayHere'), findsOneWidget);
    });

    testWidgets('has back button in app bar', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });
}
