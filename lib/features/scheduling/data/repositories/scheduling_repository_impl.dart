import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/booking_schedule.dart';
import '../../domain/entities/worker_calendar.dart';
import '../../domain/repositories/scheduling_repository.dart';

class SchedulingRepositoryImpl implements SchedulingRepository {
  final FirebaseFirestore _db;

  SchedulingRepositoryImpl({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  // Firestore path: workers/{workerId}/calendar/availability
  DocumentReference<Map<String, dynamic>> _calendarDoc(String workerId) => _db
      .collection('workers')
      .doc(workerId)
      .collection('calendar')
      .doc('availability');

  @override
  Future<Either<Failure, WorkerCalendar>> getWorkerCalendar(
    String workerId,
  ) async {
    try {
      final snap = await _calendarDoc(workerId).get();
      if (!snap.exists) return Right(WorkerCalendar.empty(workerId));
      return Right(WorkerCalendar.fromJson(snap.data()!, workerId: workerId));
    } catch (e) {
      return Left(ServerFailure('Failed to load calendar: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> setWorkerCalendar(
    WorkerCalendar calendar,
  ) async {
    try {
      await _calendarDoc(
        calendar.workerId,
      ).set({...calendar.toJson(), 'updatedAt': FieldValue.serverTimestamp()});
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to save calendar: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkAvailability({
    required String workerId,
    required BookingSchedule schedule,
  }) async {
    try {
      final result = await getWorkerCalendar(workerId);
      return result.fold(
        Left.new,
        (cal) => Right(
          cal.isAvailable(
            date: schedule.date,
            startTime: schedule.startTime,
            endTime: schedule.endTime,
          ),
        ),
      );
    } catch (e) {
      return Left(ServerFailure('Availability check failed: $e'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> findAvailableWorkers({
    required BookingSchedule schedule,
    required String serviceType,
    double? nearLat,
    double? nearLng,
    double radiusKm = 15.0,
  }) async {
    try {
      // Query workers approved for the requested service type
      Query<Map<String, dynamic>> query = _db
          .collection('workers')
          .where('status', isEqualTo: 'approved')
          .where('isOnline', isEqualTo: true);

      final snap = await query.get();
      final available = <String>[];

      for (final doc in snap.docs) {
        final data = doc.data();

        // Service type filter
        final services =
            (data['services'] as List<dynamic>?)
                ?.map((s) => s as String)
                .toList() ??
            [];
        if (!services.contains(serviceType)) continue;

        // Calendar availability check
        final avail = await checkAvailability(
          workerId: doc.id,
          schedule: schedule,
        );
        if (avail.fold((_) => false, (ok) => ok)) {
          available.add(doc.id);
        }
      }

      return Right(available);
    } catch (e) {
      return Left(ServerFailure('Failed to find available workers: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> blockCalendarSlot({
    required String workerId,
    required BookingSchedule schedule,
  }) async {
    try {
      final result = await getWorkerCalendar(workerId);
      return result.fold(Left.new, (cal) async {
        final updated = cal.withBookedDate(schedule.date);
        return setWorkerCalendar(updated);
      });
    } catch (e) {
      return Left(ServerFailure('Failed to block slot: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> releaseCalendarSlot({
    required String workerId,
    required BookingSchedule schedule,
  }) async {
    try {
      final result = await getWorkerCalendar(workerId);
      return result.fold(Left.new, (cal) async {
        final updated = cal.withReleasedDate(schedule.date);
        return setWorkerCalendar(updated);
      });
    } catch (e) {
      return Left(ServerFailure('Failed to release slot: $e'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> generateRecurringBookings({
    required String parentBookingId,
    required BookingSchedule schedule,
    required Map<String, dynamic> bookingTemplate,
  }) async {
    try {
      final dates = schedule.recurrence.generateDates(schedule.date);
      // Skip first date — it's the parent booking itself
      final instanceDates = dates.skip(1).toList();

      final batch = _db.batch();
      final createdIds = <String>[];

      for (final date in instanceDates) {
        final ref = _db.collection('bookings').doc();
        final instanceSchedule = schedule.copyWith(
          date: date,
          recurrence: schedule.recurrence.copyWith(
            parentBookingId: parentBookingId,
          ),
        );
        batch.set(ref, {
          ...bookingTemplate,
          'id': ref.id,
          'schedule': instanceSchedule.toJson(),
          'scheduledDate': Timestamp.fromDate(date),
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
        createdIds.add(ref.id);
      }

      await batch.commit();
      return Right(createdIds);
    } catch (e) {
      return Left(ServerFailure('Failed to generate recurring bookings: $e'));
    }
  }
}
