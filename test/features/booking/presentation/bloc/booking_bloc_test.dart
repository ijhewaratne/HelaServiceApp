import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/core/errors/failures.dart';
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

  setUp(() {
    mockRepository = MockBookingRepository();
    mockFindNearestWorker = MockFindNearestWorker();
    bloc = BookingBloc(
      bookingRepository: mockRepository,
      findNearestWorker: mockFindNearestWorker,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('CreateBooking', () {
    final bookingData = {
      'customerId': 'customer_123',
      'serviceType': 'cleaning',
      'zoneId': 'col_03_04',
      'location': {'latitude': 6.9271, 'longitude': 79.8612},
      'houseNumber': '45/A',
      'estimatedPrice': 1500.0,
    };

    final createdBooking = {
      'id': 'booking_123',
      ...bookingData,
      'status': 'searching',
      'createdAt': DateTime.now().toIso8601String(),
    };

    blocTest<BookingBloc, BookingState>(
      'emits [BookingLoading, BookingCreated] when successful',
      build: () {
        when(mockRepository.createBooking(bookingData))
            .thenAnswer((_) async => Right(createdBooking));
        return bloc;
      },
      act: (bloc) => bloc.add(CreateBooking(bookingData: bookingData)),
      expect: () => [
        BookingLoading(),
        BookingCreated(booking: createdBooking),
      ],
    );

    blocTest<BookingBloc, BookingState>(
      'emits [BookingLoading, BookingError] when creation fails',
      build: () {
        when(mockRepository.createBooking(bookingData))
            .thenAnswer((_) async => Left(ServerFailure('Creation failed')));
        return bloc;
      },
      act: (bloc) => bloc.add(CreateBooking(bookingData: bookingData)),
      expect: () => [
        BookingLoading(),
        BookingError(message: 'Creation failed'),
      ],
    );
  });

  group('LoadBooking', () {
    const bookingId = 'booking_123';
    final booking = {
      'id': bookingId,
      'customerId': 'customer_123',
      'serviceType': 'cleaning',
      'status': 'assigned',
      'workerId': 'worker_456',
    };

    blocTest<BookingBloc, BookingState>(
      'emits [BookingLoading, BookingLoaded] when successful',
      build: () {
        when(mockRepository.getBooking(bookingId))
            .thenAnswer((_) async => Right(booking));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadBooking(bookingId: bookingId)),
      expect: () => [
        BookingLoading(),
        BookingLoaded(booking: booking),
      ],
    );
  });

  group('CancelBooking', () {
    const bookingId = 'booking_123';

    blocTest<BookingBloc, BookingState>(
      'emits [BookingLoading, BookingCancelled] when successful',
      build: () {
        when(mockRepository.cancelBooking(bookingId, reason: anyNamed('reason')))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const CancelBooking(
        bookingId: bookingId,
        reason: 'Customer request',
      )),
      expect: () => [
        BookingLoading(),
        const BookingCancelled(bookingId: bookingId),
      ],
    );
  });

  group('AssignWorker', () {
    const bookingId = 'booking_123';
    const workerId = 'worker_456';
    final booking = {
      'id': bookingId,
      'status': 'assigned',
      'workerId': workerId,
    };

    blocTest<BookingBloc, BookingState>(
      'emits [BookingLoading, WorkerAssigned] when successful',
      build: () {
        when(mockRepository.assignWorker(bookingId, workerId))
            .thenAnswer((_) async => Right(booking));
        return bloc;
      },
      act: (bloc) => bloc.add(const AssignWorker(
        bookingId: bookingId,
        workerId: workerId,
      )),
      expect: () => [
        BookingLoading(),
        WorkerAssigned(booking: booking, workerId: workerId),
      ],
    );
  });

  group('UpdateBookingStatus', () {
    const bookingId = 'booking_123';
    const status = 'inProgress';
    final booking = {
      'id': bookingId,
      'status': status,
    };

    blocTest<BookingBloc, BookingState>(
      'emits [BookingLoading, BookingStatusUpdated] when successful',
      build: () {
        when(mockRepository.updateBookingStatus(bookingId, status, additionalData: anyNamed('additionalData')))
            .thenAnswer((_) async => Right(booking));
        return bloc;
      },
      act: (bloc) => bloc.add(const UpdateBookingStatus(
        bookingId: bookingId,
        status: status,
      )),
      expect: () => [
        BookingLoading(),
        BookingStatusUpdated(booking: booking, status: status),
      ],
    );
  });
}
