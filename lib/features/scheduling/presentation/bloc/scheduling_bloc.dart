import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/booking_schedule.dart';
import '../../domain/entities/worker_calendar.dart';
import '../../domain/usecases/check_worker_availability.dart';
import '../../domain/usecases/find_available_workers.dart';
import '../../domain/usecases/generate_recurring_bookings.dart';
import '../../domain/repositories/scheduling_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class SchedulingEvent extends Equatable {
  const SchedulingEvent();
  @override
  List<Object?> get props => [];
}

class LoadWorkerCalendar extends SchedulingEvent {
  final String workerId;
  const LoadWorkerCalendar(this.workerId);
  @override
  List<Object?> get props => [workerId];
}

class SaveWorkerCalendar extends SchedulingEvent {
  final WorkerCalendar calendar;
  const SaveWorkerCalendar(this.calendar);
  @override
  List<Object?> get props => [calendar];
}

class CheckAvailability extends SchedulingEvent {
  final String workerId;
  final BookingSchedule schedule;
  const CheckAvailability({required this.workerId, required this.schedule});
  @override
  List<Object?> get props => [workerId, schedule];
}

class FindWorkers extends SchedulingEvent {
  final BookingSchedule schedule;
  final String serviceType;
  final double? nearLat;
  final double? nearLng;
  const FindWorkers({
    required this.schedule,
    required this.serviceType,
    this.nearLat,
    this.nearLng,
  });
  @override
  List<Object?> get props => [schedule, serviceType];
}

class ExpandRecurringBooking extends SchedulingEvent {
  final String parentBookingId;
  final BookingSchedule schedule;
  final Map<String, dynamic> bookingTemplate;
  const ExpandRecurringBooking({
    required this.parentBookingId,
    required this.schedule,
    required this.bookingTemplate,
  });
  @override
  List<Object?> get props => [parentBookingId];
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class SchedulingState extends Equatable {
  const SchedulingState();
  @override
  List<Object?> get props => [];
}

class SchedulingInitial extends SchedulingState {}

class SchedulingLoading extends SchedulingState {}

class CalendarLoaded extends SchedulingState {
  final WorkerCalendar calendar;
  const CalendarLoaded(this.calendar);
  @override
  List<Object?> get props => [calendar];
}

class AvailabilityResult extends SchedulingState {
  final bool isAvailable;
  final String workerId;
  const AvailabilityResult({required this.isAvailable, required this.workerId});
  @override
  List<Object?> get props => [isAvailable, workerId];
}

class AvailableWorkersList extends SchedulingState {
  final List<String> workerIds;
  const AvailableWorkersList(this.workerIds);
  @override
  List<Object?> get props => [workerIds];
}

class RecurringBookingsGenerated extends SchedulingState {
  final List<String> instanceIds;
  const RecurringBookingsGenerated(this.instanceIds);
  @override
  List<Object?> get props => [instanceIds];
}

class CalendarSaved extends SchedulingState {}

class SchedulingError extends SchedulingState {
  final String message;
  const SchedulingError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

class SchedulingBloc extends Bloc<SchedulingEvent, SchedulingState> {
  final SchedulingRepository _repository;
  final CheckWorkerAvailability _checkAvailability;
  final FindAvailableWorkers _findAvailableWorkers;
  final GenerateRecurringBookings _generateRecurringBookings;

  SchedulingBloc({
    required SchedulingRepository repository,
    required CheckWorkerAvailability checkAvailability,
    required FindAvailableWorkers findAvailableWorkers,
    required GenerateRecurringBookings generateRecurringBookings,
  })  : _repository = repository,
        _checkAvailability = checkAvailability,
        _findAvailableWorkers = findAvailableWorkers,
        _generateRecurringBookings = generateRecurringBookings,
        super(SchedulingInitial()) {
    on<LoadWorkerCalendar>(_onLoadCalendar);
    on<SaveWorkerCalendar>(_onSaveCalendar);
    on<CheckAvailability>(_onCheckAvailability);
    on<FindWorkers>(_onFindWorkers);
    on<ExpandRecurringBooking>(_onExpandRecurring);
  }

  Future<void> _onLoadCalendar(
      LoadWorkerCalendar event, Emitter<SchedulingState> emit) async {
    emit(SchedulingLoading());
    final result = await _repository.getWorkerCalendar(event.workerId);
    result.fold(
      (f) => emit(SchedulingError(f.message)),
      (cal) => emit(CalendarLoaded(cal)),
    );
  }

  Future<void> _onSaveCalendar(
      SaveWorkerCalendar event, Emitter<SchedulingState> emit) async {
    emit(SchedulingLoading());
    final result = await _repository.setWorkerCalendar(event.calendar);
    result.fold(
      (f) => emit(SchedulingError(f.message)),
      (_) => emit(CalendarSaved()),
    );
  }

  Future<void> _onCheckAvailability(
      CheckAvailability event, Emitter<SchedulingState> emit) async {
    emit(SchedulingLoading());
    final result = await _checkAvailability(
      CheckWorkerAvailabilityParams(
        workerId: event.workerId,
        schedule: event.schedule,
      ),
    );
    result.fold(
      (f) => emit(SchedulingError(f.message)),
      (ok) => emit(AvailabilityResult(
          isAvailable: ok, workerId: event.workerId)),
    );
  }

  Future<void> _onFindWorkers(
      FindWorkers event, Emitter<SchedulingState> emit) async {
    emit(SchedulingLoading());
    final result = await _findAvailableWorkers(
      FindAvailableWorkersParams(
        schedule: event.schedule,
        serviceType: event.serviceType,
        nearLat: event.nearLat,
        nearLng: event.nearLng,
      ),
    );
    result.fold(
      (f) => emit(SchedulingError(f.message)),
      (ids) => emit(AvailableWorkersList(ids)),
    );
  }

  Future<void> _onExpandRecurring(
      ExpandRecurringBooking event, Emitter<SchedulingState> emit) async {
    emit(SchedulingLoading());
    final result = await _generateRecurringBookings(
      GenerateRecurringBookingsParams(
        parentBookingId: event.parentBookingId,
        schedule: event.schedule,
        bookingTemplate: event.bookingTemplate,
      ),
    );
    result.fold(
      (f) => emit(SchedulingError(f.message)),
      (ids) => emit(RecurringBookingsGenerated(ids)),
    );
  }
}
