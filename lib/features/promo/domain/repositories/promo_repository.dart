import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../booking/domain/entities/booking.dart';
import '../entities/promo_code_entity.dart';

/// Abstract repository for promo code operations
///
/// Phase 7: Business Features - Promo Codes
abstract class PromoRepository {
  /// Get promo code by code string
  Future<Either<Failure, PromoCodeEntity>> getPromoCode(String code);

  /// Validate promo code for a booking
  Future<Either<Failure, ValidationResult>> validatePromoCode({
    required String code,
    required double orderAmount,
    required ServiceType serviceType,
    required String zoneId,
    required String userId,
  });

  /// Apply promo code to booking (increments usage count)
  Future<Either<Failure, double>> applyPromoCode({
    required String code,
    required String userId,
    required String bookingId,
    required double orderAmount,
  });

  /// Get all active promo codes
  Future<Either<Failure, List<PromoCodeEntity>>> getActivePromoCodes({
    String? userId,
    ServiceType? serviceType,
    String? zoneId,
  });

  /// Check if user has used a promo code before
  Future<Either<Failure, bool>> hasUserUsedPromoCode({
    required String userId,
    required String promoCode,
  });

  /// Get promo code usage history for a user
  Future<Either<Failure, List<PromoCodeUsage>>> getUserPromoUsage({
    required String userId,
    int limit = 50,
  });

  /// Create promo code (admin only)
  Future<Either<Failure, PromoCodeEntity>> createPromoCode(
    PromoCodeEntity promoCode,
  );

  /// Update promo code (admin only)
  Future<Either<Failure, PromoCodeEntity>> updatePromoCode(
    PromoCodeEntity promoCode,
  );

  /// Deactivate promo code (admin only)
  Future<Either<Failure, void>> deactivatePromoCode(String code);

  /// Get promo code statistics (admin only)
  Future<Either<Failure, PromoCodeStatistics>> getPromoCodeStatistics(
    String code,
  );

  /// Get trending/popular promo codes
  Future<Either<Failure, List<PromoCodeEntity>>> getTrendingPromoCodes({
    int limit = 10,
  });
}

/// Promo code statistics
class PromoCodeStatistics {
  final String code;
  final int totalUses;
  final int uniqueUsers;
  final double totalDiscountGiven;
  final double averageOrderAmount;
  final DateTime firstUsedAt;
  final DateTime lastUsedAt;
  final Map<ServiceType, int> usageByService;

  const PromoCodeStatistics({
    required this.code,
    required this.totalUses,
    required this.uniqueUsers,
    required this.totalDiscountGiven,
    required this.averageOrderAmount,
    required this.firstUsedAt,
    required this.lastUsedAt,
    required this.usageByService,
  });
}
