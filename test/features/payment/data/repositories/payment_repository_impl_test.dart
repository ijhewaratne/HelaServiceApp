import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/core/errors/failures.dart';
import 'package:home_service_app/features/payment/data/repositories/payment_repository_impl.dart';
import 'package:home_service_app/features/payment/domain/entities/payment_result.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../test_helpers/firebase_mocks.dart';

void main() {
  late PaymentRepositoryImpl repository;
  late MockFirebaseFirestore mockFirestore;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    repository = PaymentRepositoryImpl(mockFirestore);
  });

  group('checkPaymentStatus', () {
    const orderId = 'order_123';

    test('should return payment status when found', () async {
      // Arrange
      final mockDocRef = MockDocumentReference();
      final mockDocSnap = createMockDocumentSnapshot(
        id: orderId,
        data: {
          'orderId': orderId,
          'status': 'success',
          'amount': 150000,
          'currency': 'LKR',
        },
      );
      
      when(mockFirestore.collection('payments')).thenReturn(MockCollectionReference());
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnap);

      // Act
      final result = await repository.checkPaymentStatus(orderId);

      // Assert
      expect(result.isRight(), isTrue);
    });

    test('should return NotFoundFailure when payment not found', () async {
      // Arrange
      final mockDocRef = MockDocumentReference();
      final mockDocSnap = createMockDocumentSnapshot(
        id: orderId,
        data: null,
        exists: false,
      );
      
      when(mockFirestore.collection('payments')).thenReturn(MockCollectionReference());
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnap);

      // Act
      final result = await repository.checkPaymentStatus(orderId);

      // Assert
      expect(result.isLeft(), isTrue);
    });
  });

  group('getCustomerPaymentHistory', () {
    const customerId = 'customer_123';

    test('should return list of payments', () async {
      // Arrange
      final mockQuerySnap = createMockQuerySnapshot([
        createMockQueryDocumentSnapshot(
          id: 'pay_1',
          data: {
            'paymentId': 'pay_1',
            'customerId': customerId,
            'amount': 150000,
            'status': 'success',
            'createdAt': Timestamp.now(),
          },
        ),
      ]);
      
      when(mockFirestore.collection('payments')).thenReturn(MockCollectionReference());

      // Act
      final result = await repository.getCustomerPaymentHistory(customerId);

      // Assert
      expect(result.isRight(), isTrue);
    });

    test('should return empty list when no payments', () async {
      // Arrange
      final mockQuerySnap = createMockQuerySnapshot([]);
      
      when(mockFirestore.collection('payments')).thenReturn(MockCollectionReference());

      // Act
      final result = await repository.getCustomerPaymentHistory(customerId);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should return empty list'),
        (payments) => expect(payments, isEmpty),
      );
    });
  });

  group('refundPayment', () {
    const paymentId = 'pay_123';

    test('should process refund successfully', () async {
      // Arrange
      final mockDocRef = MockDocumentReference();
      when(mockFirestore.collection('payments')).thenReturn(MockCollectionReference());
      when(mockDocRef.update(any)).thenAnswer((_) async {});

      // Act
      final result = await repository.refundPayment(
        paymentId: paymentId,
        amount: 150000,
        reason: 'Customer request',
      );

      // Assert
      expect(result.isRight(), isTrue);
    });
  });
}
