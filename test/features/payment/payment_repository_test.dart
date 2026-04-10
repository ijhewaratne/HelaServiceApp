import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:home_service_app/features/payment/domain/repositories/payment_repository.dart';
import 'package:home_service_app/features/payment/domain/entities/payment_result.dart';
import 'package:home_service_app/core/errors/failures.dart';

@GenerateMocks([PaymentRepository])
import 'payment_repository_test.mocks.dart';

void main() {
  late MockPaymentRepository mockRepository;

  setUp(() {
    mockRepository = MockPaymentRepository();
  });

  group('PaymentRepository', () {
    const testBookingId = 'booking_123';
    const testAmount = 150000; // LKR 1,500 in cents
    const testCustomerName = 'John Doe';
    const testCustomerPhone = '+94771234567';
    const testCustomerEmail = 'john@example.com';

    test('should process payment successfully', () async {
      // Arrange
      final expectedResult = PaymentResult.success(
        paymentId: 'pay_123',
        orderId: testBookingId,
        amount: 1500.0,
        currency: 'LKR',
      );

      when(mockRepository.processPayment(
        bookingId: anyNamed('bookingId'),
        amount: anyNamed('amount'),
        customerName: anyNamed('customerName'),
        customerPhone: anyNamed('customerPhone'),
        customerEmail: anyNamed('customerEmail'),
      )).thenAnswer((_) async => Right(expectedResult));

      // Act
      final result = await mockRepository.processPayment(
        bookingId: testBookingId,
        amount: testAmount,
        customerName: testCustomerName,
        customerPhone: testCustomerPhone,
        customerEmail: testCustomerEmail,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (paymentResult) {
          expect(paymentResult.success, true);
          expect(paymentResult.paymentId, 'pay_123');
          expect(paymentResult.amount, 1500.0);
        },
      );
    });

    test('should return failure for invalid amount', () async {
      // Arrange
      when(mockRepository.processPayment(
        bookingId: anyNamed('bookingId'),
        amount: 500, // Below minimum
        customerName: anyNamed('customerName'),
        customerPhone: anyNamed('customerPhone'),
        customerEmail: anyNamed('customerEmail'),
      )).thenAnswer((_) async => const Left(
        PaymentFailure('Minimum payment amount is LKR 10.00'),
      ));

      // Act
      final result = await mockRepository.processPayment(
        bookingId: testBookingId,
        amount: 500,
        customerName: testCustomerName,
        customerPhone: testCustomerPhone,
        customerEmail: testCustomerEmail,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, contains('Minimum')),
        (_) => fail('Should return failure'),
      );
    });

    test('should check payment status', () async {
      // Arrange
      when(mockRepository.checkPaymentStatus(any))
          .thenAnswer((_) async => const Right(PaymentStatus.completed));

      // Act
      final result = await mockRepository.checkPaymentStatus(testBookingId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (status) => expect(status, PaymentStatus.completed),
      );
    });

    test('should get customer payment history', () async {
      // Arrange
      final payments = [
        PaymentResult.success(
          paymentId: 'pay_1',
          orderId: 'order_1',
          amount: 1500.0,
        ),
        PaymentResult.success(
          paymentId: 'pay_2',
          orderId: 'order_2',
          amount: 2000.0,
        ),
      ];

      when(mockRepository.getCustomerPaymentHistory('customer_123'))
          .thenAnswer((_) async => Right(payments));

      // Act
      final result = await mockRepository.getCustomerPaymentHistory('customer_123');

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (history) {
          expect(history.length, 2);
          expect(history[0].paymentId, 'pay_1');
          expect(history[1].paymentId, 'pay_2');
        },
      );
    });
  });
}
