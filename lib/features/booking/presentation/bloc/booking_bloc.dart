import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/services/analytics_service.dart';
import '../../../../core/monitoring/performance_monitoring.dart';
import '../../../matching/domain/usecases/find_nearest_worker.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';

/// BLoC for managing booking-related state
class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingRepository _bookingRepository;
  final FindNearestWorker _findNearestWorker;
  final AnalyticsService _analytics;
  final PerformanceMonitoring _performance;

  BookingBloc({
    required BookingRepository bookingRepository,
    required FindNearestWorker findNearestWorker,
    AnalyticsService? analytics,
    PerformanceMonitoring? performance,
  }) : _bookingRepository = bookingRepository,
       _findNearestWorker = findNearestWorker,
       _analytics = analytics ?? AnalyticsService(),
       _performance = performance ?? PerformanceMonitoring(),
       super(BookingInitial()) {
    on<CreateBooking>(_onCreateBooking);
    on<LoadBooking>(_onLoadBooking);
    on<UpdateBooking>(_onUpdateBooking);
    on<CancelBooking>(_onCancelBooking);
    on<LoadCustomerBookings>(_onLoadCustomerBookings);
    on<LoadWorkerBookings>(_onLoadWorkerBookings);
    on<FindWorkers>(_onFindWorkers);
    on<AssignWorker>(_onAssignWorker);
    on<UpdateBookingStatus>(_onUpdateBookingStatus);
    on<WatchBooking>(_onWatchBooking);
  }

  Future<void> _onCreateBooking(
    CreateBooking event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());

    final result = await _performance.measure(
      'create_booking',
      () => _bookingRepository.createBooking(event.bookingData),
    );

    if (result.isLeft()) {
      final failure = result.fold((l) => l, (_) => throw StateError(''));
      await _analytics.logError(
        error: 'Booking creation failed: ${failure.message}',
        context: 'booking_bloc',
      );
      emit(BookingError(message: failure.message));
      return;
    }

    final booking = result.getOrElse(() => throw StateError(''));
    await _analytics.logBookingCreated(
      bookingId: booking.id,
      serviceType: booking.serviceType.name,
      estimatedPrice: booking.estimatedPrice,
      scheduledDate: booking.scheduledDate,
    );
    await _analytics.logAddToCart(
      serviceType: booking.serviceType.name,
      price: booking.estimatedPrice,
    );
    if (!emit.isDone) emit(BookingCreated(booking: booking));
  }

  Future<void> _onLoadBooking(
    LoadBooking event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    final result = await _bookingRepository.getBooking(event.bookingId);
    result.fold(
      (failure) => emit(BookingError(message: failure.message)),
      (booking) => emit(BookingLoaded(booking: booking)),
    );
  }

  Future<void> _onUpdateBooking(
    UpdateBooking event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    final result = await _bookingRepository.updateBooking(
      event.bookingId,
      event.data,
    );
    result.fold(
      (failure) => emit(BookingError(message: failure.message)),
      (booking) => emit(BookingUpdated(booking: booking)),
    );
  }

  Future<void> _onCancelBooking(
    CancelBooking event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    final result = await _bookingRepository.cancelBooking(
      event.bookingId,
      reason: event.reason,
    );
    if (result.isLeft()) {
      emit(BookingError(message: result.fold((l) => l.message, (_) => '')));
      return;
    }
    await _analytics.logBookingCancelled(
      bookingId: event.bookingId,
      reason: event.reason,
    );
    if (!emit.isDone) emit(BookingCancelled(bookingId: event.bookingId));
  }

  Future<void> _onLoadCustomerBookings(
    LoadCustomerBookings event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    final result = await _bookingRepository.getCustomerBookings(
      event.customerId,
    );
    result.fold(
      (failure) => emit(BookingError(message: failure.message)),
      (bookings) => emit(BookingListLoaded(bookings: bookings)),
    );
  }

  Future<void> _onLoadWorkerBookings(
    LoadWorkerBookings event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    final result = await _bookingRepository.getWorkerBookings(event.workerId);
    result.fold(
      (failure) => emit(BookingError(message: failure.message)),
      (bookings) => emit(BookingListLoaded(bookings: bookings)),
    );
  }

  Future<void> _onFindWorkers(
    FindWorkers event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    try {
      final result = await _performance.measure(
        'find_workers',
        () => _findNearestWorker(
          FindNearestWorkerParams(
            customerLat: event.latitude,
            customerLng: event.longitude,
            serviceType: event.serviceType,
            zoneId: event.zoneId,
            maxRadiusKm: event.maxRadiusKm,
            topN: event.topN,
          ),
        ),
      );
      result.fold(
        (failure) => emit(BookingError(message: failure.message)),
        (workers) => emit(WorkersFound(workers: workers)),
      );
    } catch (e) {
      _analytics.logError(
        error: 'Find workers failed: $e',
        context: 'booking_bloc',
      );
      emit(BookingError(message: 'Failed to find workers: $e'));
    }
  }

  Future<void> _onAssignWorker(
    AssignWorker event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    final result = await _bookingRepository.assignWorker(
      event.bookingId,
      event.workerId,
    );
    result.fold((failure) => emit(BookingError(message: failure.message)), (
      booking,
    ) {
      emit(WorkerAssigned(booking: booking, workerId: event.workerId));
    });
  }

  Future<void> _onUpdateBookingStatus(
    UpdateBookingStatus event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    final result = await _bookingRepository.updateBookingStatus(
      event.bookingId,
      event.status,
      additionalData: event.additionalData,
    );
    result.fold((failure) => emit(BookingError(message: failure.message)), (
      booking,
    ) async {
      if (event.status == BookingStatus.completed) {
        final durationMinutes = booking.duration?.inMinutes ?? 0;
        await _analytics.logJobCompleted(
          jobId: event.bookingId,
          workerId: booking.workerId ?? 'unknown',
          serviceType: booking.serviceType.name,
          durationMinutes: durationMinutes,
          finalPrice: booking.finalPrice ?? booking.estimatedPrice,
          workerRating: ((event.additionalData?['rating'] as num?) ?? 0)
              .toDouble(),
        );
        await _analytics.logPurchase(
          bookingId: event.bookingId,
          value: booking.finalPrice ?? booking.estimatedPrice,
          serviceType: booking.serviceType.name,
        );
      }
      emit(BookingStatusUpdated(booking: booking, status: event.status));
    });
  }

  Future<void> _onWatchBooking(
    WatchBooking event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    await emit.forEach(
      _bookingRepository.watchBooking(event.bookingId),
      onData: (result) => result.fold(
        (failure) => BookingError(message: failure.message),
        (booking) => BookingUpdated(booking: booking),
      ),
      onError: (error, _) {
        _analytics.logError(
          error: 'Booking stream error: $error',
          context: 'booking_bloc',
        );
        return BookingError(message: 'Stream error: $error');
      },
    );
  }
}

// ==================== EVENTS ====================

abstract class BookingEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Create new booking
class CreateBooking extends BookingEvent {
  final Booking bookingData;

  CreateBooking({required this.bookingData});

  @override
  List<Object?> get props => [bookingData];
}

/// Load booking by ID
class LoadBooking extends BookingEvent {
  final String bookingId;

  LoadBooking({required this.bookingId});

  @override
  List<Object?> get props => [bookingId];
}

/// Update booking
class UpdateBooking extends BookingEvent {
  final String bookingId;
  final Map<String, dynamic> data;

  UpdateBooking({required this.bookingId, required this.data});

  @override
  List<Object?> get props => [bookingId, data];
}

/// Cancel booking
class CancelBooking extends BookingEvent {
  final String bookingId;
  final String? reason;

  CancelBooking({required this.bookingId, this.reason});

  @override
  List<Object?> get props => [bookingId, reason];
}

/// Load customer bookings
class LoadCustomerBookings extends BookingEvent {
  final String customerId;

  LoadCustomerBookings({required this.customerId});

  @override
  List<Object?> get props => [customerId];
}

/// Load worker bookings
class LoadWorkerBookings extends BookingEvent {
  final String workerId;

  LoadWorkerBookings({required this.workerId});

  @override
  List<Object?> get props => [workerId];
}

/// Find nearest workers
class FindWorkers extends BookingEvent {
  final double latitude;
  final double longitude;
  final dynamic serviceType;
  final String zoneId;
  final double maxRadiusKm;
  final int topN;

  FindWorkers({
    required this.latitude,
    required this.longitude,
    required this.serviceType,
    required this.zoneId,
    this.maxRadiusKm = 5.0,
    this.topN = 3,
  });

  @override
  List<Object?> get props => [
    latitude,
    longitude,
    serviceType,
    zoneId,
    maxRadiusKm,
    topN,
  ];
}

/// Assign worker to booking
class AssignWorker extends BookingEvent {
  final String bookingId;
  final String workerId;

  AssignWorker({required this.bookingId, required this.workerId});

  @override
  List<Object?> get props => [bookingId, workerId];
}

/// Update booking status
class UpdateBookingStatus extends BookingEvent {
  final String bookingId;
  final BookingStatus status;
  final Map<String, dynamic>? additionalData;

  UpdateBookingStatus({
    required this.bookingId,
    required this.status,
    this.additionalData,
  });

  @override
  List<Object?> get props => [bookingId, status, additionalData];
}

/// Watch booking updates
class WatchBooking extends BookingEvent {
  final String bookingId;

  WatchBooking({required this.bookingId});

  @override
  List<Object?> get props => [bookingId];
}

// ==================== STATES ====================

abstract class BookingState extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Initial state
class BookingInitial extends BookingState {}

/// Loading state
class BookingLoading extends BookingState {}

/// Booking created
class BookingCreated extends BookingState {
  final Booking booking;

  BookingCreated({required this.booking});

  @override
  List<Object?> get props => [booking];
}

/// Booking loaded
class BookingLoaded extends BookingState {
  final Booking booking;

  BookingLoaded({required this.booking});

  @override
  List<Object?> get props => [booking];
}

/// Booking updated
class BookingUpdated extends BookingState {
  final Booking booking;

  BookingUpdated({required this.booking});

  @override
  List<Object?> get props => [booking];
}

/// Booking cancelled
class BookingCancelled extends BookingState {
  final String bookingId;

  BookingCancelled({required this.bookingId});

  @override
  List<Object?> get props => [bookingId];
}

/// Booking list loaded
class BookingListLoaded extends BookingState {
  final List<Booking> bookings;

  BookingListLoaded({required this.bookings});

  @override
  List<Object?> get props => [bookings];
}

/// Workers found
class WorkersFound extends BookingState {
  final List<dynamic> workers;

  WorkersFound({required this.workers});

  @override
  List<Object?> get props => [workers];
}

/// Worker assigned
class WorkerAssigned extends BookingState {
  final Booking booking;
  final String workerId;

  WorkerAssigned({required this.booking, required this.workerId});

  @override
  List<Object?> get props => [booking, workerId];
}

/// Booking status updated
class BookingStatusUpdated extends BookingState {
  final Booking booking;
  final BookingStatus status;

  BookingStatusUpdated({required this.booking, required this.status});

  @override
  List<Object?> get props => [booking, status];
}

/// Error state
class BookingError extends BookingState {
  final String message;

  BookingError({required this.message});

  @override
  List<Object?> get props => [message];
}
