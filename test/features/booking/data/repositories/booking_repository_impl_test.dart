import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/core/errors/failures.dart';
import 'package:home_service_app/features/booking/data/repositories/booking_repository_impl.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../test_helpers/firebase_mocks.dart';

void main() {
  late BookingRepositoryImpl repository;
  late MockFirebaseFirestore mockFirestore;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    repository = BookingRepositoryImpl(mockFirestore, mockFirestore);
  });

  group('createBooking', () {
    final bookingData = {
      'customerId': 'customer_123',
      'serviceType': 'cleaning',
      'zoneId': 'col_03_04',
      'location': {'latitude': 6.9271, 'longitude': 79.8612},
      'houseNumber': '45/A',
      'estimatedPrice': 1500.0,
      'status': 'searching',
    };

    test('should create booking successfully', () async {
      // Arrange
      final mockDocRef = MockDocumentReference();
      when(mockDocRef.id).thenReturn('booking_123');
      when(mockFirestore.collection('bookings')).thenReturn(MockCollectionReference());
      when(mockDocRef.set(any)).thenAnswer((_) async {});

      // Act
      final result = await repository.createBooking(bookingData);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should return booking'),
        (booking) {
          expect(booking['id'], equals('booking_123'));
          expect(booking['customerId'], equals('customer_123'));
        },
      );
    });

    test('should return ServerFailure when creation fails', () async {
      // Arrange
      final mockDocRef = MockDocumentReference();
      when(mockFirestore.collection('bookings')).thenReturn(MockCollectionReference());
      when(mockDocRef.set(any)).thenThrow(Exception('Network error'));

      // Act
      final result = await repository.createBooking(bookingData);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should return failure'),
      );
    });
  });

  group('getBooking', () {
    const bookingId = 'booking_123';

    test('should return booking when found', () async {
      // Arrange
      final mockDocRef = MockDocumentReference();
      final mockDocSnap = createMockDocumentSnapshot(
        id: bookingId,
        data: {
          'id': bookingId,
          'customerId': 'customer_123',
          'serviceType': 'cleaning',
          'status': 'assigned',
          'workerId': 'worker_456',
          'createdAt': Timestamp.now(),
        },
      );
      
      when(mockFirestore.collection('bookings')).thenReturn(MockCollectionReference());
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnap);

      // Act
      final result = await repository.getBooking(bookingId);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should return booking'),
        (booking) {
          expect(booking['id'], equals(bookingId));
          expect(booking['status'], equals('assigned'));
        },
      );
    });

    test('should return NotFoundFailure when booking not found', () async {
      // Arrange
      final mockDocRef = MockDocumentReference();
      final mockDocSnap = createMockDocumentSnapshot(
        id: bookingId,
        data: null,
        exists: false,
      );
      
      when(mockFirestore.collection('bookings')).thenReturn(MockCollectionReference());
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnap);

      // Act
      final result = await repository.getBooking(bookingId);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NotFoundFailure>()),
        (_) => fail('Should return failure'),
      );
    });
  });

  group('getCustomerBookings', () {
    const customerId = 'customer_123';

    test('should return list of customer bookings', () async {
      // Arrange
      final mockQuerySnap = createMockQuerySnapshot([
        createMockQueryDocumentSnapshot(
          id: 'booking_1',
          data: {
            'id': 'booking_1',
            'customerId': customerId,
            'serviceType': 'cleaning',
            'status': 'completed',
          },
        ),
        createMockQueryDocumentSnapshot(
          id: 'booking_2',
          data: {
            'id': 'booking_2',
            'customerId': customerId,
            'serviceType': 'cooking',
            'status': 'assigned',
          },
        ),
      ]);
      
      when(mockFirestore.collection('bookings')).thenReturn(MockCollectionReference());

      // Act
      final result = await repository.getCustomerBookings(customerId);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should return bookings'),
        (bookings) {
          expect(bookings.length, equals(2));
          expect(bookings[0]['serviceType'], equals('cleaning'));
          expect(bookings[1]['serviceType'], equals('cooking'));
        },
      );
    });

    test('should return empty list when no bookings found', () async {
      // Arrange
      final mockQuerySnap = createMockQuerySnapshot([]);
      
      when(mockFirestore.collection('bookings')).thenReturn(MockCollectionReference());

      // Act
      final result = await repository.getCustomerBookings(customerId);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should return empty list'),
        (bookings) => expect(bookings, isEmpty),
      );
    });
  });

  group('assignWorker', () {
    const bookingId = 'booking_123';
    const workerId = 'worker_456';

    test('should assign worker successfully', () async {
      // Arrange
      final mockDocRef = MockDocumentReference();
      when(mockFirestore.collection('bookings')).thenReturn(MockCollectionReference());
      when(mockDocRef.update(any)).thenAnswer((_) async {});

      // Act
      final result = await repository.assignWorker(bookingId, workerId);

      // Assert
      expect(result.isRight(), isTrue);
    });
  });

  group('cancelBooking', () {
    const bookingId = 'booking_123';

    test('should cancel booking with reason', () async {
      // Arrange
      final mockDocRef = MockDocumentReference();
      when(mockFirestore.collection('bookings')).thenReturn(MockCollectionReference());
      when(mockDocRef.update(any)).thenAnswer((_) async {});

      // Act
      final result = await repository.cancelBooking(bookingId, reason: 'Customer request');

      // Assert
      expect(result, equals(const Right(null)));
    });
  });

  group('updateBookingStatus', () {
    const bookingId = 'booking_123';

    test('should update booking status', () async {
      // Arrange
      final mockDocRef = MockDocumentReference();
      final mockDocSnap = createMockDocumentSnapshot(
        id: bookingId,
        data: {
          'id': bookingId,
          'status': 'assigned',
          'customerId': 'customer_123',
        },
      );
      
      when(mockFirestore.collection('bookings')).thenReturn(MockCollectionReference());
      when(mockDocRef.update(any)).thenAnswer((_) async {});
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnap);

      // Act
      final result = await repository.updateBookingStatus(bookingId, 'inProgress');

      // Assert
      expect(result.isRight(), isTrue);
    });
  });
}
