import 'package:equatable/equatable.dart';

/// Referral status
enum ReferralStatus {
  pending, // Referred user signed up but not completed first booking
  completed, // Referred user completed first booking
  rewarded, // Reward has been credited
  expired, // Referral expired without completion
}

/// Referral reward type
enum RewardType {
  walletCredit,
  discountCode,
  freeService,
}

/// Referral entity
///
/// Phase 7: Business Features - Referral System
class ReferralEntity extends Equatable {
  final String id;
  final String referrerId;
  final String? referredUserId;
  final String referralCode;
  final ReferralStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? rewardedAt;
  final double rewardAmount;
  final RewardType rewardType;
  final bool referrerRewarded;
  final bool referredRewarded;
  final Map<String, dynamic>? metadata;

  const ReferralEntity({
    required this.id,
    required this.referrerId,
    this.referredUserId,
    required this.referralCode,
    this.status = ReferralStatus.pending,
    required this.createdAt,
    this.completedAt,
    this.rewardedAt,
    this.rewardAmount = 500.0, // Default LKR 500
    this.rewardType = RewardType.walletCredit,
    this.referrerRewarded = false,
    this.referredRewarded = false,
    this.metadata,
  });

  /// Empty referral
  static final empty = ReferralEntity(
    id: '',
    referrerId: '',
    referralCode: '',
    createdAt: DateTime(2000, 1, 1),
  );

  bool get isEmpty => id.isEmpty;

  /// Check if referral is pending
  bool get isPending => status == ReferralStatus.pending;

  /// Check if referral is completed
  bool get isCompleted =>
      status == ReferralStatus.completed || status == ReferralStatus.rewarded;

  /// Check if reward has been processed
  bool get isRewarded => status == ReferralStatus.rewarded;

  /// Get days since creation
  int get daysSinceCreation {
    return DateTime.now().difference(createdAt).inDays;
  }

  /// Check if referral is expired (30 days pending limit)
  bool get isExpired {
    if (status != ReferralStatus.pending) return false;
    return daysSinceCreation > 30;
  }

  ReferralEntity copyWith({
    String? id,
    String? referrerId,
    String? referredUserId,
    String? referralCode,
    ReferralStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? rewardedAt,
    double? rewardAmount,
    RewardType? rewardType,
    bool? referrerRewarded,
    bool? referredRewarded,
    Map<String, dynamic>? metadata,
  }) {
    return ReferralEntity(
      id: id ?? this.id,
      referrerId: referrerId ?? this.referrerId,
      referredUserId: referredUserId ?? this.referredUserId,
      referralCode: referralCode ?? this.referralCode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      rewardedAt: rewardedAt ?? this.rewardedAt,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      rewardType: rewardType ?? this.rewardType,
      referrerRewarded: referrerRewarded ?? this.referrerRewarded,
      referredRewarded: referredRewarded ?? this.referredRewarded,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        referrerId,
        referredUserId,
        referralCode,
        status,
      ];
}

/// User referral info
class UserReferralInfo extends Equatable {
  final String userId;
  final String referralCode;
  final int totalReferrals;
  final int successfulReferrals;
  final double totalRewardsEarned;
  final List<ReferralEntity> recentReferrals;

  const UserReferralInfo({
    required this.userId,
    required this.referralCode,
    this.totalReferrals = 0,
    this.successfulReferrals = 0,
    this.totalRewardsEarned = 0.0,
    this.recentReferrals = const [],
  });

  /// Generate a unique referral code from user ID
  static String generateReferralCode(String userId) {
    // Take first 8 chars of userId and add random suffix
    final prefix = userId.substring(0, 8).toUpperCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch % 10000;
    return 'HEL$prefix$timestamp';
  }

  /// Get share message
  String get shareMessage {
    return 'Join me on HelaService and get LKR 500 off your first booking! '
        'Use my referral code: $referralCode\n\n'
        'Download the app: https://helaservice.lk/app';
  }

  UserReferralInfo copyWith({
    String? userId,
    String? referralCode,
    int? totalReferrals,
    int? successfulReferrals,
    double? totalRewardsEarned,
    List<ReferralEntity>? recentReferrals,
  }) {
    return UserReferralInfo(
      userId: userId ?? this.userId,
      referralCode: referralCode ?? this.referralCode,
      totalReferrals: totalReferrals ?? this.totalReferrals,
      successfulReferrals: successfulReferrals ?? this.successfulReferrals,
      totalRewardsEarned: totalRewardsEarned ?? this.totalRewardsEarned,
      recentReferrals: recentReferrals ?? this.recentReferrals,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        referralCode,
        totalReferrals,
        successfulReferrals,
        totalRewardsEarned,
      ];
}

/// Referral leaderboard entry
class ReferralLeaderboardEntry extends Equatable {
  final String userId;
  final String? displayName;
  final int referralCount;
  final double totalRewards;

  const ReferralLeaderboardEntry({
    required this.userId,
    this.displayName,
    required this.referralCount,
    required this.totalRewards,
  });

  @override
  List<Object?> get props => [userId, referralCount, totalRewards];
}

/// Referral statistics
class ReferralStatistics {
  final int totalReferrals;
  final int successfulReferrals;
  final int pendingReferrals;
  final double conversionRate;
  final double totalRewardsGiven;
  final double averageReward;

  const ReferralStatistics({
    required this.totalReferrals,
    required this.successfulReferrals,
    required this.pendingReferrals,
    required this.conversionRate,
    required this.totalRewardsGiven,
    required this.averageReward,
  });

  factory ReferralStatistics.fromReferrals(List<ReferralEntity> referrals) {
    final total = referrals.length;
    final successful =
        referrals.where((r) => r.status == ReferralStatus.completed).length;
    final pending =
        referrals.where((r) => r.status == ReferralStatus.pending).length;
    final totalRewards = referrals
        .where((r) => r.isRewarded)
        .fold(0.0, (sum, r) => sum + r.rewardAmount);

    return ReferralStatistics(
      totalReferrals: total,
      successfulReferrals: successful,
      pendingReferrals: pending,
      conversionRate: total > 0 ? (successful / total) * 100 : 0.0,
      totalRewardsGiven: totalRewards,
      averageReward: successful > 0 ? totalRewards / successful : 0.0,
    );
  }
}
