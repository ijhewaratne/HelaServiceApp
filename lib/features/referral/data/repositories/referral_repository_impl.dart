import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/referral_entity.dart';
import '../../domain/repositories/referral_repository.dart';

class ReferralRepositoryImpl implements ReferralRepository {
  final FirebaseFirestore _firestore;

  ReferralRepositoryImpl(this._firestore);

  @override
  Future<Either<Failure, UserReferralInfo>> getUserReferralInfo(
    String userId,
  ) async =>
      const Left(GenericFailure('Not implemented'));

  @override
  Future<Either<Failure, ReferralEntity>> getReferral(
    String referralId,
  ) async =>
      const Left(GenericFailure('Not implemented'));

  @override
  Future<Either<Failure, List<ReferralEntity>>> getUserReferrals(
    String userId, {
    ReferralStatus? status,
    int limit = 50,
  }) async =>
      const Right([]);

  @override
  Future<Either<Failure, ReferralEntity>> applyReferralCode({
    required String referralCode,
    required String newUserId,
  }) async =>
      const Left(GenericFailure('Not implemented'));

  @override
  Future<Either<Failure, ReferralEntity>> completeReferral({
    required String referralId,
    required String bookingId,
  }) async =>
      const Left(GenericFailure('Not implemented'));

  @override
  Future<Either<Failure, ReferralStatistics>> getReferralStatistics(
    String userId,
  ) async =>
      const Left(GenericFailure('Not implemented'));

  @override
  Future<Either<Failure, List<ReferralLeaderboardEntry>>> getLeaderboard({
    int limit = 10,
  }) async =>
      const Right([]);

  @override
  Future<Either<Failure, bool>> isReferralCodeValid(String code) async =>
      const Right(false);

  @override
  Future<Either<Failure, String?>> getReferrerId(String referralCode) async =>
      const Right(null);

  @override
  Stream<Either<Failure, List<ReferralEntity>>> watchUserReferrals(
    String userId,
  ) =>
      Stream.value(const Right([]));

  @override
  Future<Either<Failure, List<ReferralEntity>>> getAllReferrals({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async =>
      const Right([]);

  @override
  Future<Either<Failure, void>> updateRewardAmount({
    required String referralId,
    required double newAmount,
  }) async =>
      const Left(GenericFailure('Not implemented'));

  @override
  Future<Either<Failure, int>> processPendingRewards() async =>
      const Right(0);
}
