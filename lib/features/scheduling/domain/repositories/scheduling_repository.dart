import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/booking_schedule.dart';
import '../entities/worker_calendar.dart';

abstract class SchedulingRepository {
  /// Fetch a worker's full availability calendar
  Future<Either<Failure, WorkerCalendar>> getWorkerCalendar(String workerId);

  /// Overwrite a worker's availability calendar
  Future<Either<Failure, void>> setWorkerCalendar(WorkerCalendar calendar);

  /// Check whether a single worker is free for the given slot
  Future<Either<Failure, bool>> checkAvailability({
    required String workerId,
    required BookingSchedule schedule,
  });

  /// Return IDs of workers available for a slot, filtered by service type
  Future<Either<Failure, List<String>>> findAvailableWorkers({
    required BookingSchedule schedule,
    required String serviceType,
    double? nearLat,
    double? nearLng,
    double radiusKm = 15.0,
  });

  /// Mark a calendar slot as blocked after a booking is confirmed
  Future<Either<Failure, void>> blockCalendarSlot({
    required String workerId,
    required BookingSchedule schedule,
  });

  /// Release a previously blocked slot (e.g. booking cancelled)
  Future<Either<Failure, void>> releaseCalendarSlot({
    required String workerId,
    required BookingSchedule schedule,
  });

  /// Expand a recurring booking into all its occurrence dates and persist them
  Future<Either<Failure, List<String>>> generateRecurringBookings({
    required String parentBookingId,
    required BookingSchedule schedule,
    required Map<String, dynamic> bookingTemplate,
  });
}
