import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Verification badge levels for workers.
/// Green → Blue → Gold → Partner (state machine, always forward).
enum VerificationTier { green, blue, gold, partner }

/// Current verification state including checklist completion
class WorkerVerification extends Equatable {
  final String workerId;
  final VerificationTier tier;

  // Green tier checklist
  final bool nicVerified;
  final bool phoneVerified;
  final bool backgroundCheckPassed;

  // Blue tier checklist
  final bool trainingCompleted;
  final bool firstJobCompleted;
  final bool minRatingMet; // >= 4.0 after >= 5 jobs

  // Gold tier checklist
  final bool hundredJobsCompleted;
  final bool goldRatingMet; // >= 4.7 sustained
  final bool zeroComplaintsLast30Days;

  // Partner tier checklist
  final bool twoFiftyJobsCompleted;
  final bool partnerRatingMet; // >= 4.8
  final bool exclusiveZoneGranted;

  final DateTime? tierGrantedAt;
  final String? reviewedBy; // admin uid
  final String? notes;

  const WorkerVerification({
    required this.workerId,
    this.tier = VerificationTier.green,
    this.nicVerified = false,
    this.phoneVerified = false,
    this.backgroundCheckPassed = false,
    this.trainingCompleted = false,
    this.firstJobCompleted = false,
    this.minRatingMet = false,
    this.hundredJobsCompleted = false,
    this.goldRatingMet = false,
    this.zeroComplaintsLast30Days = false,
    this.twoFiftyJobsCompleted = false,
    this.partnerRatingMet = false,
    this.exclusiveZoneGranted = false,
    this.tierGrantedAt,
    this.reviewedBy,
    this.notes,
  });

  static WorkerVerification initial(String workerId) =>
      WorkerVerification(workerId: workerId);

  bool get isGreenComplete =>
      nicVerified && phoneVerified && backgroundCheckPassed;

  bool get isBlueComplete =>
      isGreenComplete && trainingCompleted && firstJobCompleted && minRatingMet;

  bool get isGoldComplete =>
      isBlueComplete &&
      hundredJobsCompleted &&
      goldRatingMet &&
      zeroComplaintsLast30Days;

  bool get isPartnerComplete =>
      isGoldComplete &&
      twoFiftyJobsCompleted &&
      partnerRatingMet &&
      exclusiveZoneGranted;

  /// Next tier the worker can be promoted to, or null if already at partner
  VerificationTier? get nextTier {
    switch (tier) {
      case VerificationTier.green:
        return isBlueComplete ? VerificationTier.blue : null;
      case VerificationTier.blue:
        return isGoldComplete ? VerificationTier.gold : null;
      case VerificationTier.gold:
        return isPartnerComplete ? VerificationTier.partner : null;
      case VerificationTier.partner:
        return null;
    }
  }

  bool get canPromote => nextTier != null;

  WorkerVerification copyWith({
    VerificationTier? tier,
    bool? nicVerified,
    bool? phoneVerified,
    bool? backgroundCheckPassed,
    bool? trainingCompleted,
    bool? firstJobCompleted,
    bool? minRatingMet,
    bool? hundredJobsCompleted,
    bool? goldRatingMet,
    bool? zeroComplaintsLast30Days,
    bool? twoFiftyJobsCompleted,
    bool? partnerRatingMet,
    bool? exclusiveZoneGranted,
    DateTime? tierGrantedAt,
    String? reviewedBy,
    String? notes,
  }) => WorkerVerification(
    workerId: workerId,
    tier: tier ?? this.tier,
    nicVerified: nicVerified ?? this.nicVerified,
    phoneVerified: phoneVerified ?? this.phoneVerified,
    backgroundCheckPassed: backgroundCheckPassed ?? this.backgroundCheckPassed,
    trainingCompleted: trainingCompleted ?? this.trainingCompleted,
    firstJobCompleted: firstJobCompleted ?? this.firstJobCompleted,
    minRatingMet: minRatingMet ?? this.minRatingMet,
    hundredJobsCompleted: hundredJobsCompleted ?? this.hundredJobsCompleted,
    goldRatingMet: goldRatingMet ?? this.goldRatingMet,
    zeroComplaintsLast30Days:
        zeroComplaintsLast30Days ?? this.zeroComplaintsLast30Days,
    twoFiftyJobsCompleted: twoFiftyJobsCompleted ?? this.twoFiftyJobsCompleted,
    partnerRatingMet: partnerRatingMet ?? this.partnerRatingMet,
    exclusiveZoneGranted: exclusiveZoneGranted ?? this.exclusiveZoneGranted,
    tierGrantedAt: tierGrantedAt ?? this.tierGrantedAt,
    reviewedBy: reviewedBy ?? this.reviewedBy,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toJson() => {
    'workerId': workerId,
    'tier': tier.name,
    'nicVerified': nicVerified,
    'phoneVerified': phoneVerified,
    'backgroundCheckPassed': backgroundCheckPassed,
    'trainingCompleted': trainingCompleted,
    'firstJobCompleted': firstJobCompleted,
    'minRatingMet': minRatingMet,
    'hundredJobsCompleted': hundredJobsCompleted,
    'goldRatingMet': goldRatingMet,
    'zeroComplaintsLast30Days': zeroComplaintsLast30Days,
    'twoFiftyJobsCompleted': twoFiftyJobsCompleted,
    'partnerRatingMet': partnerRatingMet,
    'exclusiveZoneGranted': exclusiveZoneGranted,
    'tierGrantedAt': tierGrantedAt != null
        ? Timestamp.fromDate(tierGrantedAt!)
        : null,
    'reviewedBy': reviewedBy,
    'notes': notes,
  };

  factory WorkerVerification.fromJson(Map<String, dynamic> json) =>
      WorkerVerification(
        workerId: json['workerId'] as String? ?? '',
        tier: VerificationTier.values.firstWhere(
          (e) => e.name == (json['tier'] as String?),
          orElse: () => VerificationTier.green,
        ),
        nicVerified: json['nicVerified'] as bool? ?? false,
        phoneVerified: json['phoneVerified'] as bool? ?? false,
        backgroundCheckPassed: json['backgroundCheckPassed'] as bool? ?? false,
        trainingCompleted: json['trainingCompleted'] as bool? ?? false,
        firstJobCompleted: json['firstJobCompleted'] as bool? ?? false,
        minRatingMet: json['minRatingMet'] as bool? ?? false,
        hundredJobsCompleted: json['hundredJobsCompleted'] as bool? ?? false,
        goldRatingMet: json['goldRatingMet'] as bool? ?? false,
        zeroComplaintsLast30Days:
            json['zeroComplaintsLast30Days'] as bool? ?? false,
        twoFiftyJobsCompleted: json['twoFiftyJobsCompleted'] as bool? ?? false,
        partnerRatingMet: json['partnerRatingMet'] as bool? ?? false,
        exclusiveZoneGranted: json['exclusiveZoneGranted'] as bool? ?? false,
        tierGrantedAt: json['tierGrantedAt'] != null
            ? (json['tierGrantedAt'] as Timestamp).toDate()
            : null,
        reviewedBy: json['reviewedBy'] as String?,
        notes: json['notes'] as String?,
      );

  @override
  List<Object?> get props => [workerId, tier];
}

extension VerificationTierX on VerificationTier {
  String get label {
    switch (this) {
      case VerificationTier.green:
        return 'Green';
      case VerificationTier.blue:
        return 'Blue';
      case VerificationTier.gold:
        return 'Gold';
      case VerificationTier.partner:
        return 'Partner';
    }
  }

  /// Multiplier applied to worker's base rate
  double get rateMultiplier {
    switch (this) {
      case VerificationTier.green:
        return 1.0;
      case VerificationTier.blue:
        return 1.1;
      case VerificationTier.gold:
        return 1.25;
      case VerificationTier.partner:
        return 1.40;
    }
  }

  /// Whether this tier appears as a visible badge to customers
  bool get isVisible => this != VerificationTier.green;
}
