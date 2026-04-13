import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/referral_entity.dart';

/// Abstract repository for referral operations
///
/// Phase 7: Business Features - Referral System
abstract class ReferralRepository {
  /// Get or create user's referral info (including referral code)
  Future<Either<Failure, UserReferralInfo>> getUserReferralInfo(String userId);

  /// Get referral by ID
  Future<Either<Failure, ReferralEntity>> getReferral(String referralId);

  /// Get all referrals made by a user
  Future<Either<Failure, List<ReferralEntity>>> getUserReferrals(
    String userId, {
    ReferralStatus? status,
    int limit = 50,
  });

  /// Apply referral code during signup
  Future<Either<Failure, ReferralEntity>> applyReferralCode({
    required String referralCode,
    required String newUserId,
  });

  /// Mark referral as completed (when referred user completes first booking)
  Future<Either<Failure, ReferralEntity>> completeReferral({
    required String referralId,
    required String bookingId,
  });

  /// Get referral statistics for a user
  Future<Either<Failure, ReferralStatistics>> getReferralStatistics(
    String userId,
  );

  /// Get referral leaderboard (top referrers)
  Future<Either<Failure, List<ReferralLeaderboardEntry>>> getLeaderboard({
    int limit = 10,
  });

  /// Check if referral code is valid
  Future<Either<Failure, bool>> isReferralCodeValid(String code);

  /// Get referrer ID from referral code
  Future<Either<Failure, String?>> getReferrerId(String referralCode);

  /// Stream of referral updates for a user
  Stream<Either<Failure, List<ReferralEntity>>> watchUserReferrals(
    String userId,
  );

  /// Admin: Get all referrals in system
  Future<Either<Failure, List<ReferralEntity>>> getAllReferrals({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  });

  /// Admin: Update referral reward amount
  Future<Either<Failure, void>> updateRewardAmount({
    required String referralId,
    required double newAmount,
  });

  /// Admin: Process pending rewards manually
  Future<Either<Failure, int>> processPendingRewards();
}
