import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/safety_alert.dart';
import '../../domain/repositories/safety_repository.dart';

class SafetyRepositoryImpl implements SafetyRepository {
  final FirebaseFirestore _db;

  SafetyRepositoryImpl({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('safety_alerts');

  @override
  Future<Either<Failure, SafetyAlert>> createAlert(
      SafetyAlert alert) async {
    try {
      final ref = alert.id.isEmpty ? _col.doc() : _col.doc(alert.id);
      final withId = SafetyAlert(
        id: ref.id,
        bookingId: alert.bookingId,
        workerId: alert.workerId,
        customerId: alert.customerId,
        type: alert.type,
        severity: alert.severity,
        status: alert.status,
        message: alert.message,
        latitude: alert.latitude,
        longitude: alert.longitude,
        createdAt: alert.createdAt,
      );
      await ref.set(withId.toJson());
      return Right(withId);
    } catch (e) {
      return Left(ServerFailure('Failed to create alert: $e'));
    }
  }

  @override
  Future<Either<Failure, List<SafetyAlert>>> getOpenAlerts() async {
    try {
      final snap = await _col
          .where('status', isEqualTo: 'open')
          .orderBy('createdAt', descending: true)
          .get();
      return Right(snap.docs.map(SafetyAlert.fromFirestore).toList());
    } catch (e) {
      return Left(ServerFailure('Failed to get open alerts: $e'));
    }
  }

  @override
  Future<Either<Failure, List<SafetyAlert>>> getAlertsForBooking(
      String bookingId) async {
    try {
      final snap = await _col
          .where('bookingId', isEqualTo: bookingId)
          .orderBy('createdAt', descending: true)
          .get();
      return Right(snap.docs.map(SafetyAlert.fromFirestore).toList());
    } catch (e) {
      return Left(ServerFailure('Failed to get booking alerts: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> acknowledgeAlert(String alertId) async {
    try {
      await _col.doc(alertId).update({
        'status': 'acknowledged',
        'acknowledgedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to acknowledge alert: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> resolveAlert({
    required String alertId,
    required String adminId,
    required String notes,
  }) async {
    try {
      await _col.doc(alertId).update({
        'status': 'resolved',
        'resolvedBy': adminId,
        'resolutionNotes': notes,
        'resolvedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to resolve alert: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> escalateAlert(String alertId) async {
    try {
      await _col.doc(alertId).update({'status': 'escalated'});
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to escalate alert: $e'));
    }
  }

  @override
  Stream<List<SafetyAlert>> watchOpenAlerts() {
    return _col
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map(SafetyAlert.fromFirestore).toList());
  }

  @override
  Future<Either<Failure, List<SafetyAlert>>> detectMissedCheckIns({
    Duration gracePeriod = const Duration(minutes: 15),
  }) async {
    try {
      final now = DateTime.now();
      final cutoff = now.subtract(gracePeriod);

      // Find in-progress bookings (workerArrived) where checkIn is null
      // and scheduled start is past the grace period
      final snap = await _db
          .collection('bookings')
          .where('status', isEqualTo: 'workerArrived')
          .get();

      final created = <SafetyAlert>[];

      for (final doc in snap.docs) {
        final data = doc.data();
        if (data['checkIn'] != null) continue;

        final scheduledDate = data['scheduledDate'];
        if (scheduledDate == null) continue;
        final scheduled = scheduledDate is Timestamp
            ? scheduledDate.toDate()
            : DateTime.tryParse(scheduledDate as String? ?? '');
        if (scheduled == null || scheduled.isAfter(cutoff)) continue;

        // Check no alert already exists for this booking + type
        final existing = await _col
            .where('bookingId', isEqualTo: doc.id)
            .where('type', isEqualTo: 'missedCheckIn')
            .limit(1)
            .get();
        if (existing.docs.isNotEmpty) continue;

        final alert = SafetyAlert(
          id: '',
          bookingId: doc.id,
          workerId: data['workerId'] as String? ?? '',
          customerId: data['customerId'] as String? ?? '',
          type: AlertType.missedCheckIn,
          severity: AlertSeverity.high,
          message:
              'Worker has not checked in for booking ${doc.id} (grace: ${gracePeriod.inMinutes} min)',
          createdAt: now,
        );
        final result = await createAlert(alert);
        result.fold((_) {}, created.add);
      }

      return Right(created);
    } catch (e) {
      return Left(ServerFailure('Missed check-in detection failed: $e'));
    }
  }

  @override
  Future<Either<Failure, List<SafetyAlert>>> detectMissedCheckOuts({
    Duration gracePeriod = const Duration(minutes: 30),
  }) async {
    try {
      final now = DateTime.now();
      final cutoff = now.subtract(gracePeriod);

      final snap = await _db
          .collection('bookings')
          .where('status', isEqualTo: 'inProgress')
          .get();

      final created = <SafetyAlert>[];

      for (final doc in snap.docs) {
        final data = doc.data();
        if (data['checkOut'] != null) continue;

        // Use schedule endTime if present, else scheduledDate + durationHours
        DateTime? expectedEnd;
        final schedule = data['schedule'] as Map<String, dynamic>?;
        if (schedule != null) {
          final dateTs = schedule['date'];
          final endTime = schedule['endTime'] as String?;
          if (dateTs is Timestamp && endTime != null) {
            final date = dateTs.toDate();
            final parts = endTime.split(':');
            expectedEnd = DateTime(date.year, date.month, date.day,
                int.parse(parts[0]), int.parse(parts[1]));
          }
        }

        if (expectedEnd == null) {
          final scheduledDate = data['scheduledDate'];
          final dur = data['durationHours'] as int? ?? 4;
          final base = scheduledDate is Timestamp
              ? scheduledDate.toDate()
              : DateTime.tryParse(scheduledDate as String? ?? '');
          if (base != null) {
            expectedEnd = base.add(Duration(hours: dur));
          }
        }

        if (expectedEnd == null || expectedEnd.isAfter(cutoff)) continue;

        final existing = await _col
            .where('bookingId', isEqualTo: doc.id)
            .where('type', isEqualTo: 'missedCheckOut')
            .limit(1)
            .get();
        if (existing.docs.isNotEmpty) continue;

        final alert = SafetyAlert(
          id: '',
          bookingId: doc.id,
          workerId: data['workerId'] as String? ?? '',
          customerId: data['customerId'] as String? ?? '',
          type: AlertType.missedCheckOut,
          severity: AlertSeverity.high,
          message:
              'Worker has not checked out for booking ${doc.id} (expected end: ${expectedEnd.toIso8601String()})',
          createdAt: now,
        );
        final result = await createAlert(alert);
        result.fold((_) {}, created.add);
      }

      return Right(created);
    } catch (e) {
      return Left(ServerFailure('Missed check-out detection failed: $e'));
    }
  }
}
