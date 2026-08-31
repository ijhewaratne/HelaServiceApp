import 'package:flutter_test/flutter_test.dart';

import 'package:home_service_app/features/payment/domain/entities/payout.dart';
import 'package:home_service_app/features/worker/domain/entities/worker_verification.dart';

void main() {
  // ── Payout.calculate — 80/20 split ───────────────────────────────────────

  final tPeriodStart = DateTime(2026, 6, 2);
  final tPeriodEnd = DateTime(2026, 6, 9);

  group('Payout.calculate', () {
    test('80/20 split is correct', () {
      final payout = Payout.calculate(
        id: 'p1',
        workerId: 'w1',
        grossAmount: 5000.0,
        periodStart: tPeriodStart,
        periodEnd: tPeriodEnd,
        bookingIds: ['b1'],
      );
      expect(payout.workerAmount, closeTo(4000.0, 0.01));
      expect(payout.platformFee, closeTo(1000.0, 0.01));
    });

    test('zero gross yields zero amounts', () {
      final payout = Payout.calculate(
        id: 'p2',
        workerId: 'w1',
        grossAmount: 0.0,
        periodStart: tPeriodStart,
        periodEnd: tPeriodEnd,
        bookingIds: [],
      );
      expect(payout.workerAmount, 0.0);
      expect(payout.platformFee, 0.0);
    });

    test('fractional amounts sum to gross', () {
      final payout = Payout.calculate(
        id: 'p3',
        workerId: 'w1',
        grossAmount: 1500.0,
        periodStart: tPeriodStart,
        periodEnd: tPeriodEnd,
        bookingIds: ['b1'],
      );
      expect(payout.workerAmount, closeTo(1200.0, 0.01));
      expect(payout.platformFee, closeTo(300.0, 0.01));
      expect(payout.workerAmount + payout.platformFee, closeTo(1500.0, 0.01));
    });

    test('platformFeeRate constant is 0.20', () {
      expect(Payout.platformFeeRate, 0.20);
    });

    test('workerShareRate constant is 0.80', () {
      expect(Payout.workerShareRate, 0.80);
    });
  });

  // ── WorkerVerification state machine ─────────────────────────────────────

  group('WorkerVerification state machine', () {
    // Green → Blue requires full isBlueComplete:
    // nicVerified + phoneVerified + backgroundCheckPassed + trainingCompleted + firstJobCompleted + minRatingMet
    test('green tier can promote to blue when all blue conditions met', () {
      final v = WorkerVerification(
        workerId: 'w1',
        tier: VerificationTier.green,
        nicVerified: true,
        phoneVerified: true,
        backgroundCheckPassed: true,
        trainingCompleted: true,
        firstJobCompleted: true,
        minRatingMet: true,
        hundredJobsCompleted: false,
        goldRatingMet: false,
        zeroComplaintsLast30Days: false,
        twoFiftyJobsCompleted: false,
        partnerRatingMet: false,
        exclusiveZoneGranted: false,
      );
      expect(v.nextTier, VerificationTier.blue);
      expect(v.canPromote, true);
    });

    test('green tier cannot promote if any blue condition missing', () {
      final v = WorkerVerification(
        workerId: 'w1',
        tier: VerificationTier.green,
        nicVerified: true,
        phoneVerified: true,
        backgroundCheckPassed: true,
        trainingCompleted: true,
        firstJobCompleted: false, // missing
        minRatingMet: true,
        hundredJobsCompleted: false,
        goldRatingMet: false,
        zeroComplaintsLast30Days: false,
        twoFiftyJobsCompleted: false,
        partnerRatingMet: false,
        exclusiveZoneGranted: false,
      );
      expect(v.nextTier, isNull);
      expect(v.canPromote, false);
    });

    // Blue → Gold requires isGoldComplete (all blue conditions + 100 jobs + 4.7 rating + no complaints)
    test('blue tier can promote to gold when gold conditions met', () {
      final v = WorkerVerification(
        workerId: 'w1',
        tier: VerificationTier.blue,
        nicVerified: true,
        phoneVerified: true,
        backgroundCheckPassed: true,
        trainingCompleted: true,
        firstJobCompleted: true,
        minRatingMet: true,
        hundredJobsCompleted: true,
        goldRatingMet: true,
        zeroComplaintsLast30Days: true,
        twoFiftyJobsCompleted: false,
        partnerRatingMet: false,
        exclusiveZoneGranted: false,
      );
      expect(v.nextTier, VerificationTier.gold);
    });

    test('gold tier can promote to partner when all conditions met', () {
      final v = WorkerVerification(
        workerId: 'w1',
        tier: VerificationTier.gold,
        nicVerified: true,
        phoneVerified: true,
        backgroundCheckPassed: true,
        trainingCompleted: true,
        firstJobCompleted: true,
        minRatingMet: true,
        hundredJobsCompleted: true,
        goldRatingMet: true,
        zeroComplaintsLast30Days: true,
        twoFiftyJobsCompleted: true,
        partnerRatingMet: true,
        exclusiveZoneGranted: true,
      );
      expect(v.nextTier, VerificationTier.partner);
    });

    test('partner tier has no next tier', () {
      final v = WorkerVerification(
        workerId: 'w1',
        tier: VerificationTier.partner,
        nicVerified: true,
        phoneVerified: true,
        backgroundCheckPassed: true,
        trainingCompleted: true,
        firstJobCompleted: true,
        minRatingMet: true,
        hundredJobsCompleted: true,
        goldRatingMet: true,
        zeroComplaintsLast30Days: true,
        twoFiftyJobsCompleted: true,
        partnerRatingMet: true,
        exclusiveZoneGranted: true,
      );
      expect(v.nextTier, isNull);
      expect(v.canPromote, false);
    });

    test('rate multipliers are correct per tier', () {
      expect(VerificationTier.green.rateMultiplier, 1.00);
      expect(VerificationTier.blue.rateMultiplier, 1.10);
      expect(VerificationTier.gold.rateMultiplier, 1.25);
      expect(VerificationTier.partner.rateMultiplier, 1.40);
    });
  });
}
