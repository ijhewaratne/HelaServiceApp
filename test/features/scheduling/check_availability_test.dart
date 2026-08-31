import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:home_service_app/core/errors/failures.dart';
import 'package:home_service_app/features/scheduling/domain/entities/booking_schedule.dart';
import 'package:home_service_app/features/scheduling/domain/entities/recurrence_rule.dart';
import 'package:home_service_app/features/scheduling/domain/repositories/scheduling_repository.dart';
import 'package:home_service_app/features/scheduling/domain/usecases/check_worker_availability.dart';
import 'package:home_service_app/features/scheduling/domain/usecases/find_available_workers.dart';
import 'package:home_service_app/features/scheduling/domain/usecases/generate_recurring_bookings.dart';
import 'package:home_service_app/features/scheduling/domain/entities/worker_calendar.dart';

class TestSchedulingRepository implements SchedulingRepository {
  Future<Either<Failure, bool>> Function({
    required String workerId,
    required BookingSchedule schedule,
  })?
  checkAvailabilityHandler;

  Future<Either<Failure, List<String>>> Function({
    required BookingSchedule schedule,
    required String serviceType,
    double? nearLat,
    double? nearLng,
    double radiusKm,
  })?
  findAvailableWorkersHandler;

  Future<Either<Failure, List<String>>> Function({
    required String parentBookingId,
    required BookingSchedule schedule,
    required Map<String, dynamic> bookingTemplate,
  })?
  generateRecurringBookingsHandler;

  @override
  Future<Either<Failure, bool>> checkAvailability({
    required String workerId,
    required BookingSchedule schedule,
  }) {
    if (checkAvailabilityHandler == null) {
      throw UnimplementedError('checkAvailabilityHandler not configured');
    }
    return checkAvailabilityHandler!(workerId: workerId, schedule: schedule);
  }

  @override
  Future<Either<Failure, List<String>>> findAvailableWorkers({
    required BookingSchedule schedule,
    required String serviceType,
    double? nearLat,
    double? nearLng,
    double radiusKm = 15.0,
  }) {
    if (findAvailableWorkersHandler == null) {
      throw UnimplementedError('findAvailableWorkersHandler not configured');
    }
    return findAvailableWorkersHandler!(
      schedule: schedule,
      serviceType: serviceType,
      nearLat: nearLat,
      nearLng: nearLng,
      radiusKm: radiusKm,
    );
  }

  @override
  Future<Either<Failure, List<String>>> generateRecurringBookings({
    required String parentBookingId,
    required BookingSchedule schedule,
    required Map<String, dynamic> bookingTemplate,
  }) {
    if (generateRecurringBookingsHandler == null) {
      throw UnimplementedError(
        'generateRecurringBookingsHandler not configured',
      );
    }
    return generateRecurringBookingsHandler!(
      parentBookingId: parentBookingId,
      schedule: schedule,
      bookingTemplate: bookingTemplate,
    );
  }

  @override
  Future<Either<Failure, void>> blockCalendarSlot({
    required String workerId,
    required BookingSchedule schedule,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, WorkerCalendar>> getWorkerCalendar(String workerId) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> releaseCalendarSlot({
    required String workerId,
    required BookingSchedule schedule,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> setWorkerCalendar(WorkerCalendar calendar) {
    throw UnimplementedError();
  }
}

void main() {
  late TestSchedulingRepository repo;
  late CheckWorkerAvailability checkAvailability;
  late FindAvailableWorkers findAvailable;
  late GenerateRecurringBookings generateRecurring;

  setUp(() {
    repo = TestSchedulingRepository();
    checkAvailability = CheckWorkerAvailability(repo);
    findAvailable = FindAvailableWorkers(repo);
    generateRecurring = GenerateRecurringBookings(repo);
  });

  final tSchedule = BookingSchedule(
    date: DateTime(2026, 6, 10),
    startTime: '09:00',
    endTime: '13:00',
    durationHours: 4,
  );

  // ── CheckWorkerAvailability ───────────────────────────────────────────────

  group('CheckWorkerAvailability', () {
    test('returns true when worker is available', () async {
      repo.checkAvailabilityHandler =
          ({required workerId, required schedule}) async => const Right(true);

      final result = await checkAvailability(
        CheckWorkerAvailabilityParams(workerId: 'w1', schedule: tSchedule),
      );

      expect(result, const Right<Failure, bool>(true));
    });

    test('returns false when worker is unavailable', () async {
      repo.checkAvailabilityHandler =
          ({required workerId, required schedule}) async => const Right(false);

      final result = await checkAvailability(
        CheckWorkerAvailabilityParams(workerId: 'w1', schedule: tSchedule),
      );

      expect(result, const Right<Failure, bool>(false));
    });

    test('propagates ServerFailure on error', () async {
      repo.checkAvailabilityHandler =
          ({required workerId, required schedule}) async =>
              const Left(ServerFailure('network error'));

      final result = await checkAvailability(
        CheckWorkerAvailabilityParams(workerId: 'w1', schedule: tSchedule),
      );

      expect(result.isLeft(), true);
    });
  });

  // ── FindAvailableWorkers ──────────────────────────────────────────────────

  group('FindAvailableWorkers', () {
    test('returns list of worker IDs matching slot', () async {
      Future<Either<Failure, List<String>>> availableWorkers({
        required BookingSchedule schedule,
        required String serviceType,
        double? nearLat,
        double? nearLng,
        double radiusKm = 15.0,
      }) async {
        return const Right<Failure, List<String>>(['w1', 'w2', 'w3']);
      }

      repo.findAvailableWorkersHandler = availableWorkers;

      final result = await findAvailable(
        FindAvailableWorkersParams(
          schedule: tSchedule,
          serviceType: 'babysitting',
          nearLat: 6.9271,
          nearLng: 79.8612,
          radiusKm: 5.0,
        ),
      );

      result.fold(
        (l) => fail('Expected Right, got Left: ${l.message}'),
        (workers) => expect(workers, ['w1', 'w2', 'w3']),
      );
    });

    test('returns empty list when no workers available', () async {
      Future<Either<Failure, List<String>>> noAvailableWorkers({
        required BookingSchedule schedule,
        required String serviceType,
        double? nearLat,
        double? nearLng,
        double radiusKm = 15.0,
      }) async {
        return const Right<Failure, List<String>>([]);
      }

      repo.findAvailableWorkersHandler = noAvailableWorkers;

      final result = await findAvailable(
        FindAvailableWorkersParams(
          schedule: tSchedule,
          serviceType: 'babysitting',
          nearLat: 6.9271,
          nearLng: 79.8612,
          radiusKm: 5.0,
        ),
      );

      result.fold(
        (l) => fail('Expected Right'),
        (workers) => expect(workers, isEmpty),
      );
    });
  });

  // ── GenerateRecurringBookings ─────────────────────────────────────────────

  group('GenerateRecurringBookings', () {
    test('returns list of generated booking IDs', () async {
      final bookingTemplate = {'serviceType': 'babysitting'};
      repo.generateRecurringBookingsHandler =
          ({
            required parentBookingId,
            required schedule,
            required bookingTemplate,
          }) async => const Right(['b2', 'b3', 'b4']);

      final result = await generateRecurring(
        GenerateRecurringBookingsParams(
          parentBookingId: 'b1',
          schedule: tSchedule,
          bookingTemplate: bookingTemplate,
        ),
      );

      result.fold(
        (l) => fail('Expected Right'),
        (ids) => expect(ids.length, 3),
      );
    });
  });

  // ── RecurrenceRule date generation ───────────────────────────────────────

  group('RecurrenceRule', () {
    test('once: returns only the first date', () {
      const rule = RecurrenceRule(pattern: RecurrencePattern.once);
      final dates = rule.generateDates(DateTime(2026, 6, 10));
      expect(dates.length, 1);
      expect(dates.first, DateTime(2026, 6, 10));
    });

    test('weekly: generates 4 dates in a month', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.weekly,
        endDate: DateTime(2026, 7, 10),
      );
      final dates = rule.generateDates(DateTime(2026, 6, 10));
      expect(dates.length, 5); // Jun 10, 17, 24, Jul 1, Jul 8
    });

    test('biweekly: generates 2 dates in a month', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.biweekly,
        endDate: DateTime(2026, 7, 10),
      );
      final dates = rule.generateDates(DateTime(2026, 6, 10));
      expect(dates.length, 3); // Jun 10, Jun 24, Jul 8
    });

    test('maxOccurrences caps generation', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.weekly,
        maxOccurrences: 3,
      );
      final dates = rule.generateDates(DateTime(2026, 6, 10));
      expect(dates.length, 3);
    });

    test('isRecurring is false for once', () {
      expect(RecurrenceRule.once.isRecurring, false);
    });

    test('isRecurring is true for weekly', () {
      expect(
        const RecurrenceRule(pattern: RecurrencePattern.weekly).isRecurring,
        true,
      );
    });

    test('intervalDays: weekly=7, biweekly=14, monthly=30', () {
      expect(
        const RecurrenceRule(pattern: RecurrencePattern.weekly).intervalDays,
        7,
      );
      expect(
        const RecurrenceRule(pattern: RecurrencePattern.biweekly).intervalDays,
        14,
      );
      expect(
        const RecurrenceRule(pattern: RecurrencePattern.monthly).intervalDays,
        30,
      );
    });
  });

  // ── WorkerCalendar availability ───────────────────────────────────────────

  group('WorkerCalendar', () {
    test('isAvailable returns true when slot matches recurring schedule', () {
      final calendar = WorkerCalendar(
        workerId: 'w1',
        recurring: {
          'wednesday': DayAvailability(
            day: 'wednesday',
            slots: [const TimeSlot(start: '08:00', end: '17:00')],
          ),
        },
      );
      // June 10, 2026 is a Wednesday.
      expect(
        calendar.isAvailable(
          date: DateTime(2026, 6, 10),
          startTime: '09:00',
          endTime: '13:00',
        ),
        true,
      );
    });

    test('isAvailable returns false when date is in exceptions', () {
      final calendar = WorkerCalendar(
        workerId: 'w1',
        recurring: {
          'wednesday': DayAvailability(
            day: 'wednesday',
            slots: [const TimeSlot(start: '08:00', end: '17:00')],
          ),
        },
        exceptions: {'2026-06-10': 'unavailable'},
      );
      expect(
        calendar.isAvailable(
          date: DateTime(2026, 6, 10),
          startTime: '09:00',
          endTime: '13:00',
        ),
        false,
      );
    });

    test('isAvailable returns false when no recurring entry for that day', () {
      final calendar = WorkerCalendar(
        workerId: 'w1',
        recurring: {}, // no days configured
      );
      expect(
        calendar.isAvailable(
          date: DateTime(2026, 6, 10),
          startTime: '09:00',
          endTime: '13:00',
        ),
        false,
      );
    });

    test('withBookedDate adds exception', () {
      final base = WorkerCalendar(workerId: 'w1', recurring: {});
      final blocked = base.withBookedDate(DateTime(2026, 6, 15));
      expect(blocked.exceptions.containsKey('2026-06-15'), true);
    });

    test('withReleasedDate removes exception', () {
      final blocked = WorkerCalendar(
        workerId: 'w1',
        recurring: {},
        exceptions: {'2026-06-15': 'booked'},
      );
      final released = blocked.withReleasedDate(DateTime(2026, 6, 15));
      expect(released.exceptions.containsKey('2026-06-15'), false);
    });
  });
}
