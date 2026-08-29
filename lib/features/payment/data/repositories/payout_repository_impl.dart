import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/payout.dart';
import '../../domain/repositories/payout_repository.dart';

class PayoutRepositoryImpl implements PayoutRepository {
  final FirebaseFirestore _db;

  PayoutRepositoryImpl({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('payouts');

  @override
  Future<Either<Failure, List<Payout>>> getWorkerPayouts(
      String workerId) async {
    try {
      final snap = await _col
          .where('workerId', isEqualTo: workerId)
          .orderBy('createdAt', descending: true)
          .get();
      return Right(snap.docs.map(Payout.fromFirestore).toList());
    } catch (e) {
      return Left(ServerFailure('Failed to load payouts: $e'));
    }
  }

  @override
  Future<Either<Failure, Payout>> getPayout(String payoutId) async {
    try {
      final doc = await _col.doc(payoutId).get();
      if (!doc.exists) return Left(NotFoundFailure('Payout not found'));
      return Right(Payout.fromFirestore(doc));
    } catch (e) {
      return Left(ServerFailure('Failed to get payout: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Payout>>> getPendingPayouts() async {
    try {
      final snap = await _col
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt')
          .get();
      return Right(snap.docs.map(Payout.fromFirestore).toList());
    } catch (e) {
      return Left(ServerFailure('Failed to load pending payouts: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markProcessed(String payoutId) async {
    try {
      await _col.doc(payoutId).update({
        'status': 'completed',
        'processedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to mark processed: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markFailed(
      String payoutId, String reason) async {
    try {
      await _col.doc(payoutId).update({
        'status': 'failed',
        'failureReason': reason,
        'processedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to mark failed: $e'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> generateWeeklyPayouts() async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final periodStart =
          DateTime(weekStart.year, weekStart.month, weekStart.day);
      final periodEnd = periodStart.add(const Duration(days: 7));

      // Find all completed bookings not yet in a payout. Firestore queries
      // never match documents where the filtered field is absent, and
      // payoutId is never initialized on booking creation — so filtering by
      // `payoutId isNull` here would silently exclude every normal booking.
      // Filter for a missing/null payoutId client-side instead.
      final bookingsSnap = await _db
          .collection('bookings')
          .where('status', isEqualTo: 'completed')
          .get();

      // Group by workerId
      final Map<String, List<DocumentSnapshot>> byWorker = {};
      for (final doc in bookingsSnap.docs) {
        final data = doc.data();
        if (data['payoutId'] != null) continue;
        final workerId = data['workerId'] as String?;
        if (workerId == null || workerId.isEmpty) continue;
        byWorker.putIfAbsent(workerId, () => []).add(doc);
      }

      final batch = _db.batch();
      final createdIds = <String>[];

      for (final entry in byWorker.entries) {
        final workerId = entry.key;
        final bookings = entry.value;
        final gross = bookings.fold<double>(0.0, (sum, b) {
          final data = b.data() as Map<String, dynamic>;
          return sum +
              ((data['finalPrice'] as num?)?.toDouble() ??
                  (data['estimatedPrice'] as num?)?.toDouble() ??
                  0.0);
        });

        if (gross <= 0) continue;

        final payoutRef = _col.doc();
        final payout = Payout.calculate(
          id: payoutRef.id,
          workerId: workerId,
          grossAmount: gross,
          periodStart: periodStart,
          periodEnd: periodEnd,
          bookingIds: bookings.map((b) => b.id).toList(),
        );
        batch.set(payoutRef, payout.toJson());

        // Link bookings to payout
        for (final b in bookings) {
          batch.update(b.reference, {'payoutId': payoutRef.id});
        }

        createdIds.add(payoutRef.id);
      }

      await batch.commit();
      return Right(createdIds);
    } catch (e) {
      return Left(ServerFailure('Failed to generate weekly payouts: $e'));
    }
  }
}
