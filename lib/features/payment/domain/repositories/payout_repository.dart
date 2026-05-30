import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/payout.dart';

abstract class PayoutRepository {
  /// Fetch all payouts for a worker, ordered by newest first
  Future<Either<Failure, List<Payout>>> getWorkerPayouts(String workerId);

  /// Fetch a single payout by id
  Future<Either<Failure, Payout>> getPayout(String payoutId);

  /// Admin: get all pending payouts ready to be processed
  Future<Either<Failure, List<Payout>>> getPendingPayouts();

  /// Admin: mark a payout as processing → completed
  Future<Either<Failure, void>> markProcessed(String payoutId);

  /// Admin: mark a payout as failed with reason
  Future<Either<Failure, void>> markFailed(String payoutId, String reason);

  /// Aggregate completed bookings into a weekly payout for each worker
  /// Returns the list of newly created payout ids
  Future<Either<Failure, List<String>>> generateWeeklyPayouts();
}
