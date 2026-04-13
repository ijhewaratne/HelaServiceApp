import 'package:equatable/equatable.dart';

import '../../../booking/domain/entities/booking.dart';

/// Discount type for promo codes
enum DiscountType {
  percentage,
  fixed,
}

/// Promo code status
enum PromoCodeStatus {
  active,
  inactive,
  expired,
  exhausted,
}

/// Promo code entity
///
/// Phase 7: Business Features - Promo Codes
class PromoCodeEntity extends Equatable {
  final String code;
  final String description;
  final DiscountType discountType;
  final double discountAmount;
  final DateTime validFrom;
  final DateTime validUntil;
  final int maxUses;
  final int currentUses;
  final double minOrderAmount;
  final double? maxDiscountAmount; // For percentage discounts
  final List<ServiceType>? applicableServices;
  final List<String>? applicableZones;
  final List<String>? applicableUserTypes; // 'customer', 'worker', 'new_user'
  final bool isFirstOrderOnly;
  final bool isOneTimePerUser;
  final Map<String, dynamic>? metadata;

  const PromoCodeEntity({
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountAmount,
    required this.validFrom,
    required this.validUntil,
    required this.maxUses,
    this.currentUses = 0,
    this.minOrderAmount = 0.0,
    this.maxDiscountAmount,
    this.applicableServices,
    this.applicableZones,
    this.applicableUserTypes,
    this.isFirstOrderOnly = false,
    this.isOneTimePerUser = true,
    this.metadata,
  });

  /// Empty promo code
  static final empty = PromoCodeEntity(
    code: '',
    description: '',
    discountType: DiscountType.fixed,
    discountAmount: 0.0,
    validFrom: DateTime(2000, 1, 1),
    validUntil: DateTime(2000, 1, 1),
    maxUses: 0,
  );

  bool get isEmpty => code.isEmpty;

  /// Check if promo code is currently valid (time-based)
  bool get isTimeValid {
    final now = DateTime.now();
    return now.isAfter(validFrom) && now.isBefore(validUntil);
  }

  /// Check if promo code has uses remaining
  bool get hasUsesRemaining => currentUses < maxUses;

  /// Get overall status
  PromoCodeStatus get status {
    if (!isTimeValid) return PromoCodeStatus.expired;
    if (!hasUsesRemaining) return PromoCodeStatus.exhausted;
    return PromoCodeStatus.active;
  }

  /// Check if promo code is valid and usable
  bool get isValid => status == PromoCodeStatus.active;

  /// Calculate discount for given order amount
  double calculateDiscount(double orderAmount) {
    if (orderAmount < minOrderAmount) return 0.0;

    double discount;
    if (discountType == DiscountType.percentage) {
      discount = orderAmount * (discountAmount / 100);
      if (maxDiscountAmount != null) {
        discount = discount.clamp(0, maxDiscountAmount!);
      }
    } else {
      discount = discountAmount;
    }

    // Don't exceed order amount
    return discount.clamp(0, orderAmount);
  }

  /// Check if promo applies to specific service type
  bool appliesToService(ServiceType serviceType) {
    if (applicableServices == null || applicableServices!.isEmpty) return true;
    return applicableServices!.contains(serviceType);
  }

  /// Check if promo applies to specific zone
  bool appliesToZone(String zoneId) {
    if (applicableZones == null || applicableZones!.isEmpty) return true;
    return applicableZones!.contains(zoneId);
  }

  /// Check if user type is eligible
  bool isEligibleUserType(String userType) {
    if (applicableUserTypes == null || applicableUserTypes!.isEmpty) {
      return true;
    }
    return applicableUserTypes!.contains(userType);
  }

  /// Validate promo code for a booking
  ValidationResult validateForBooking({
    required double orderAmount,
    required ServiceType serviceType,
    required String zoneId,
    required String userType,
    required bool isFirstOrder,
    required bool hasUsedBefore,
  }) {
    if (!isValid) {
      return ValidationResult.failure('Promo code is ${status.name}');
    }

    if (orderAmount < minOrderAmount) {
      return ValidationResult.failure(
        'Minimum order amount is LKR ${minOrderAmount.toStringAsFixed(2)}',
      );
    }

    if (!appliesToService(serviceType)) {
      return ValidationResult.failure(
        'Promo code not valid for this service type',
      );
    }

    if (!appliesToZone(zoneId)) {
      return ValidationResult.failure('Promo code not valid in this area');
    }

    if (!isEligibleUserType(userType)) {
      return ValidationResult.failure('Not eligible for this promo code');
    }

    if (isFirstOrderOnly && !isFirstOrder) {
      return ValidationResult.failure('Valid for first order only');
    }

    if (isOneTimePerUser && hasUsedBefore) {
      return ValidationResult.failure('Promo code already used');
    }

    final discount = calculateDiscount(orderAmount);
    return ValidationResult.success(discount: discount);
  }

  PromoCodeEntity copyWith({
    String? code,
    String? description,
    DiscountType? discountType,
    double? discountAmount,
    DateTime? validFrom,
    DateTime? validUntil,
    int? maxUses,
    int? currentUses,
    double? minOrderAmount,
    double? maxDiscountAmount,
    List<ServiceType>? applicableServices,
    List<String>? applicableZones,
    List<String>? applicableUserTypes,
    bool? isFirstOrderOnly,
    bool? isOneTimePerUser,
    Map<String, dynamic>? metadata,
  }) {
    return PromoCodeEntity(
      code: code ?? this.code,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discountAmount: discountAmount ?? this.discountAmount,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      maxUses: maxUses ?? this.maxUses,
      currentUses: currentUses ?? this.currentUses,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      maxDiscountAmount: maxDiscountAmount ?? this.maxDiscountAmount,
      applicableServices: applicableServices ?? this.applicableServices,
      applicableZones: applicableZones ?? this.applicableZones,
      applicableUserTypes: applicableUserTypes ?? this.applicableUserTypes,
      isFirstOrderOnly: isFirstOrderOnly ?? this.isFirstOrderOnly,
      isOneTimePerUser: isOneTimePerUser ?? this.isOneTimePerUser,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        code,
        discountType,
        discountAmount,
        validUntil,
        currentUses,
        maxUses,
      ];
}

/// Validation result for promo code
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final double? discount;

  const ValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.discount,
  });

  factory ValidationResult.success({required double discount}) {
    return ValidationResult._(isValid: true, discount: discount);
  }

  factory ValidationResult.failure(String message) {
    return ValidationResult._(isValid: false, errorMessage: message);
  }

  bool get isFailure => !isValid;
}

/// Promo code usage record
class PromoCodeUsage extends Equatable {
  final String id;
  final String promoCode;
  final String userId;
  final String? bookingId;
  final double orderAmount;
  final double discountApplied;
  final DateTime usedAt;

  const PromoCodeUsage({
    required this.id,
    required this.promoCode,
    required this.userId,
    this.bookingId,
    required this.orderAmount,
    required this.discountApplied,
    required this.usedAt,
  });

  @override
  List<Object?> get props => [id, promoCode, userId, usedAt];
}
