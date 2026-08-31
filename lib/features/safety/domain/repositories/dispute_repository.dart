import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/dispute.dart';

abstract class DisputeRepository {
  Future<Either<Failure, Dispute>> createDispute(Dispute dispute);
  Future<Either<Failure, List<Dispute>>> getAllDisputes();
  Future<Either<Failure, List<Dispute>>> getDisputesByStatus(
    DisputeStatus status,
  );
  Future<Either<Failure, Dispute?>> getDisputeForRequest(String requestId);
  Future<Either<Failure, void>> updateDisputeStatus({
    required String disputeId,
    required DisputeStatus status,
    required String adminId,
    String? adminNote,
  });
  Stream<List<Dispute>> watchOpenDisputes();
}
