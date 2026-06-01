import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/core/errors/failures.dart';
import 'package:home_service_app/features/booking/domain/entities/booking.dart';
import 'package:home_service_app/features/customer/domain/entities/address.dart';
import 'package:home_service_app/features/booking/domain/repositories/booking_repository.dart';
import 'package:home_service_app/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:home_service_app/features/matching/domain/usecases/find_nearest_worker.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'booking_bloc_test.mocks.dart';

@GenerateMocks([BookingRepository, FindNearestWorker])
void main() {
  late BookingBloc bloc;
  late MockBookingRepository mockRepository;
  late MockFindNearestWorker mockFindNearestWorker;

  final testAddress = Address(
    id: 'addr_1',
    customerId: 'customer_123',
    label: 'Home',
    houseNumber: '12A',
    city: 'Colombo',
    district: 'Colombo',
    zoneId: 'colombo_03_04',
    latitude: 6.9271,
    longitude: 79.8612,
    createdAt: DateTime(2026, 1, 1),
  );

  late Booking testBooking;

  setUp(() {
    mockRepository = MockBookingRepository();
    mockFindNearestWorker = MockFindNearestWorker();
    bloc = BookingBloc(
      bookingRepository: mockRepository,
      findNearestWorker: mockFindNearestWorker,
    );
    testBooking = Booking(
      id: 'booking_123',
      customerId: 'customer_123',
      serviceType: ServiceType.cleaning,
      address: testAddress,
      scheduledDate: DateTime(2026, 6, 15),
      scheduledTime: '10:00',
      durationHours: 4,
      estimatedPrice: 4800.0,
      createdAt: DateTime(2026, 6, 1),
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('CreateBooking', () {
    blocTest<BookingBloc, BookingState>(
      'emits [BookingLoading, BookingCreated] when successful',
      build: () {
        when(mockRepository.createBooking(testBooking))
            .thenAnswer((_) async => Right(testBooking));
        return bloc;
      },
      act: (bloc) => bloc.add(CreateBooking(bookingData: testBooking)),
      expect: () => [
        BookingLoading(),
        BookingCreated(booking: testBooking),
      ],
    );

    blocTest<BookingBloc, BookingState>(
      'emits [BookingLoading, BookingError] when creation fails',
      build: () {
        when(mockRepository.createBooking(testBooking))
            .thenAnswer((_) async => Left(ServerFailure('Creation failed')));
        return bloc;
      },
      act: (bloc) => bloc.add(CreateBooking(bookingData: testBooking)),
      expect: () => [
        BookingLoading(),
        BookingError(message: 'Creation failed'),
      ],
    );
  });

  group('LoadBooking', () {
    blocTest<BookingBloc, BookingState>(
      'emits [BookingLoading, BookingLoaded] when successful',
      build: () {
        when(mockRepository.getBooking('booking_123'))
            .thenAnswer((_) async => Right(testBooking));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadBooking(bookingId: 'booking_123')),
      expect: () => [
        BookingLoading(),
        BookingLoaded(booking: testBooking),
      ],
    );

    blocTest<BookingBloc, BookingState>(
      'emits [BookingLoading, BookingError] when not found',
      build: () {
        when(mockRepository.getBooking('booking_123'))
            .thenAnswer((_) async => Left(NotFoundFailure('Not found')));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadBooking(bookingId: 'booking_123')),
      expect: () => [
        BookingLoading(),
        BookingError(message: 'Not found'),
      ],
    );
  });

  group('CancelBooking', () {
    blocTest<BookingBloc, BookingState>(
      'emits [BookingLoading, BookingCancelled] when successful',
      build: () {
        when(mockRepository.cancelBooking('booking_123'))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(CancelBooking(bookingId: 'booking_123')),
      expect: () => [
        BookingLoading(),
        BookingCancelled(bookingId: 'booking_123'),
      ],
    );
  });
}
