import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../matching/domain/usecases/find_nearest_worker.dart';
import '../../domain/repositories/booking_repository.dart';

/// BLoC for managing booking-related state
class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingRepository _bookingRepository;
  final FindNearestWorker _findNearestWorker;

  BookingBloc({
    required BookingRepository bookingRepository,
    required FindNearestWorker findNearestWorker,
  })  : _bookingRepository = bookingRepository,
        _findNearestWorker = findNearestWorker,
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
    final result = await _bookingRepository.createBooking(event.bookingData);
    result.fold(
      (failure) => emit(BookingError(message: failure.message)),
      (booking) => emit(BookingCreated(booking: booking)),
    );
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
    result.fold(
      (failure) => emit(BookingError(message: failure.message)),
      (_) => emit(BookingCancelled(bookingId: event.bookingId)),
    );
  }

  Future<void> _onLoadCustomerBookings(
    LoadCustomerBookings event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    final result = await _bookingRepository.getCustomerBookings(event.customerId);
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
      final workers = await _findNearestWorker.execute(
        customerLat: event.latitude,
        customerLng: event.longitude,
        serviceType: event.serviceType,
        zoneId: event.zoneId,
        maxRadiusKm: event.maxRadiusKm,
        topN: event.topN,
      );
      emit(WorkersFound(workers: workers));
    } catch (e) {
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
    result.fold(
      (failure) => emit(BookingError(message: failure.message)),
      (booking) => emit(WorkerAssigned(booking: booking, workerId: event.workerId)),
    );
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
    result.fold(
      (failure) => emit(BookingError(message: failure.message)),
      (booking) => emit(BookingStatusUpdated(booking: booking, status: event.status)),
    );
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
      onError: (error, _) => BookingError(message: 'Stream error: $error'),
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
  final Map<String, dynamic> bookingData;

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
  List<Object?> get props => [latitude, longitude, serviceType, zoneId, maxRadiusKm, topN];
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
  final String status;
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
  final Map<String, dynamic> booking;

  BookingCreated({required this.booking});

  @override
  List<Object?> get props => [booking];
}

/// Booking loaded
class BookingLoaded extends BookingState {
  final Map<String, dynamic> booking;

  BookingLoaded({required this.booking});

  @override
  List<Object?> get props => [booking];
}

/// Booking updated
class BookingUpdated extends BookingState {
  final Map<String, dynamic> booking;

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
  final List<Map<String, dynamic>> bookings;

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
  final Map<String, dynamic> booking;
  final String workerId;

  WorkerAssigned({required this.booking, required this.workerId});

  @override
  List<Object?> get props => [booking, workerId];
}

/// Booking status updated
class BookingStatusUpdated extends BookingState {
  final Map<String, dynamic> booking;
  final String status;

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
