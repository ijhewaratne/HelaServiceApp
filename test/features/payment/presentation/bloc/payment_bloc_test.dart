import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/core/errors/failures.dart';
import 'package:home_service_app/core/services/analytics_service.dart';
import 'package:home_service_app/features/payment/domain/entities/payment_result.dart';
import 'package:home_service_app/features/payment/domain/repositories/payment_repository.dart';
import 'package:home_service_app/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'payment_bloc_test.mocks.dart';

@GenerateMocks([PaymentRepository, AnalyticsService])
void main() {
  late PaymentBloc bloc;
  late MockPaymentRepository mockRepository;
  late MockAnalyticsService mockAnalytics;

  setUp(() {
    mockRepository = MockPaymentRepository();
    mockAnalytics = MockAnalyticsService();
    bloc = PaymentBloc(
      paymentRepository: mockRepository,
      analytics: mockAnalytics,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('ProcessPayment', () {
    const bookingId = 'booking_123';
    const amount = 150000; // cents
    const customerName = 'Test Customer';
    const customerPhone = '+94771234567';
    const customerEmail = 'test@example.com';

    final successResult = PaymentResult(
      success: true,
      paymentId: 'pay_123',
      status: PaymentStatus.success,
      message: 'Payment successful',
    );

    final failureResult = PaymentResult(
      success: false,
      status: PaymentStatus.failed,
      message: 'Payment failed',
    );

    blocTest<PaymentBloc, PaymentState>(
      'emits [PaymentProcessing, PaymentSuccess] and logs analytics when successful',
      build: () {
        when(mockRepository.processPayment(
          bookingId: bookingId,
          amount: amount,
          customerName: customerName,
          customerPhone: customerPhone,
          customerEmail: customerEmail,
          customerAddress: anyNamed('customerAddress'),
          customerCity: anyNamed('customerCity'),
          description: anyNamed('description'),
        )).thenAnswer((_) async => Right(successResult));
        when(mockAnalytics.logPaymentSuccess(
          paymentId: anyNamed('paymentId'),
          bookingId: anyNamed('bookingId'),
          amount: anyNamed('amount'),
          method: anyNamed('method'),
        )).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc.add(const ProcessPayment(
        bookingId: bookingId,
        amount: amount,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
      )),
      expect: () => [
        PaymentProcessing(),
        PaymentSuccess(payment: successResult),
      ],
    );

    blocTest<PaymentBloc, PaymentState>(
      'emits [PaymentProcessing, PaymentFailed] and logs analytics when failed',
      build: () {
        when(mockRepository.processPayment(
          bookingId: anyNamed('bookingId'),
          amount: anyNamed('amount'),
          customerName: anyNamed('customerName'),
          customerPhone: anyNamed('customerPhone'),
          customerEmail: anyNamed('customerEmail'),
          customerAddress: anyNamed('customerAddress'),
          customerCity: anyNamed('customerCity'),
          description: anyNamed('description'),
        )).thenAnswer((_) async => Right(failureResult));
        when(mockAnalytics.logPaymentFailed(
          bookingId: anyNamed('bookingId'),
          amount: anyNamed('amount'),
          reason: anyNamed('reason'),
          errorCode: anyNamed('errorCode'),
        )).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc.add(const ProcessPayment(
        bookingId: bookingId,
        amount: amount,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
      )),
      expect: () => [
        PaymentProcessing(),
        PaymentFailed(
          message: 'Payment failed',
          status: PaymentStatus.failed,
        ),
      ],
    );
  });

  group('CheckPaymentStatus', () {
    const orderId = 'order_123';

    blocTest<PaymentBloc, PaymentState>(
      'emits [PaymentLoading, PaymentStatusChecked] when successful',
      build: () {
        when(mockRepository.checkPaymentStatus(orderId))
            .thenAnswer((_) async => const Right(PaymentStatus.success));
        return bloc;
      },
      act: (bloc) => bloc.add(const CheckPaymentStatus(orderId: orderId)),
      expect: () => [
        PaymentLoading(),
        const PaymentStatusChecked(status: PaymentStatus.success),
      ],
    );
  });

  group('LoadPaymentHistory', () {
    const customerId = 'customer_123';
    final payments = [
      PaymentResult(
        success: true,
        paymentId: 'pay_1',
        status: PaymentStatus.success,
      ),
      PaymentResult(
        success: true,
        paymentId: 'pay_2',
        status: PaymentStatus.success,
      ),
    ];

    blocTest<PaymentBloc, PaymentState>(
      'emits [PaymentLoading, PaymentHistoryLoaded] when successful',
      build: () {
        when(mockRepository.getCustomerPaymentHistory(customerId))
            .thenAnswer((_) async => Right(payments));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadPaymentHistory(customerId: customerId)),
      expect: () => [
        PaymentLoading(),
        PaymentHistoryLoaded(payments: payments),
      ],
    );
  });

  group('RequestRefund', () {
    const paymentId = 'pay_123';
    const refundResult = PaymentResult(
      success: true,
      paymentId: 'refund_123',
      status: PaymentStatus.refunded,
      message: 'Refund processed',
    );

    blocTest<PaymentBloc, PaymentState>(
      'emits [PaymentProcessing, RefundProcessed] when successful',
      build: () {
        when(mockRepository.refundPayment(
          paymentId: paymentId,
          amount: anyNamed('amount'),
          reason: anyNamed('reason'),
        )).thenAnswer((_) async => Right(refundResult));
        return bloc;
      },
      act: (bloc) => bloc.add(const RequestRefund(
        paymentId: paymentId,
        amount: 150000,
        reason: 'Customer request',
      )),
      expect: () => [
        PaymentProcessing(),
        RefundProcessed(refund: refundResult),
      ],
    );
  });
}
