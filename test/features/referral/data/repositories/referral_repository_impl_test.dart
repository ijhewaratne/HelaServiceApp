import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/core/errors/failures.dart';
import 'package:home_service_app/features/referral/data/repositories/referral_repository_impl.dart';
import 'package:home_service_app/features/referral/domain/entities/referral_entity.dart';

// NOTE: As of this writing, ReferralRepositoryImpl is an intentional stub
// (see commit cf5de51 "Implemented new PromoRepositoryImpl and
// ReferralRepositoryImpl with stub methods for future functionality").
// None of its methods read from or write to Firestore yet - every method
// ignores its arguments and returns a hardcoded Left/Right value.
//
// These tests pin down that current stub behaviour so that:
//   1. There is at least baseline coverage for a previously untested file.
//   2. Once real Firestore-backed logic is implemented (referral code
//      generation/lookup, self-referral guards, reward aggregation, etc.),
//      these tests will start failing loudly and MUST be rewritten to
//      exercise the real behaviour described in the domain repository
//      contract (lib/features/referral/domain/repositories/referral_repository.dart).
//
// Seeding Firestore documents in several tests below is deliberate: it
// demonstrates that the repository does NOT yet read seeded data (which is
// exactly the gap that needs to be closed before "happy path" referral-code
// application, code-validity lookups, and statistics aggregation can be
// tested meaningfully).
void main() {
  late FakeFirebaseFirestore firestore;
  late ReferralRepositoryImpl repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = ReferralRepositoryImpl(firestore);
  });

  group('ReferralRepositoryImpl', () {
    group('applyReferralCode', () {
      test('returns a failure even when a valid referral code document exists '
          '(not yet implemented)', () async {
        await firestore.collection('referral_codes').doc('HELREFCODE1').set({
          'referrerId': 'referrer_user_1',
          'code': 'HELREFCODE1',
        });

        final result = await repository.applyReferralCode(
          referralCode: 'HELREFCODE1',
          newUserId: 'new_user_1',
        );

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<GenericFailure>());
          expect(failure.message, 'Not implemented');
        }, (_) => fail('Expected a failure since applyReferralCode is a stub'));

        // No referral document should have been created as a side effect.
        final referrals = await firestore.collection('referrals').get();
        expect(referrals.docs, isEmpty);
      });

      test(
        'returns a failure for a nonexistent/invalid referral code',
        () async {
          final result = await repository.applyReferralCode(
            referralCode: 'DOES_NOT_EXIST',
            newUserId: 'new_user_2',
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<GenericFailure>()),
            (_) => fail('Expected a failure for an invalid referral code'),
          );
        },
      );
    });

    group('isReferralCodeValid', () {
      test('returns false for a seeded, existing referral code '
          '(lookup not yet implemented)', () async {
        await firestore.collection('referral_codes').doc('HELVALID123').set({
          'referrerId': 'referrer_user_2',
          'code': 'HELVALID123',
          'active': true,
        });

        final result = await repository.isReferralCodeValid('HELVALID123');

        expect(result.isRight(), isTrue);
        expect(result.getOrElse(() => true), isFalse);
      });

      test('returns false for a code that does not exist', () async {
        final result = await repository.isReferralCodeValid('NEVER_SEEDED');

        expect(result.isRight(), isTrue);
        expect(result.getOrElse(() => true), isFalse);
      });
    });

    group('getReferrerId', () {
      test('returns null for a seeded referral code '
          '(reverse lookup not yet implemented)', () async {
        await firestore.collection('referral_codes').doc('HELVALID123').set({
          'referrerId': 'referrer_user_2',
          'code': 'HELVALID123',
        });

        final result = await repository.getReferrerId('HELVALID123');

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right(null), got failure $failure'),
          (referrerId) => expect(referrerId, isNull),
        );
      });

      test('returns null for a code that does not exist', () async {
        final result = await repository.getReferrerId('NEVER_SEEDED');

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right(null), got failure $failure'),
          (referrerId) => expect(referrerId, isNull),
        );
      });
    });

    group('getUserReferralInfo', () {
      test('returns a failure even when the user already has referral '
          'documents in Firestore (aggregation not yet implemented)', () async {
        await firestore.collection('users').doc('user_1').set({
          'referralCode': 'HELUSER1000',
        });
        await firestore.collection('referrals').doc('ref_1').set({
          'referrerId': 'user_1',
          'referredUserId': 'user_2',
          'referralCode': 'HELUSER1000',
          'status': 'completed',
          'rewardAmount': 500.0,
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 3)),
        });
        await firestore.collection('referrals').doc('ref_2').set({
          'referrerId': 'user_1',
          'referredUserId': 'user_3',
          'referralCode': 'HELUSER1000',
          'status': 'pending',
          'rewardAmount': 500.0,
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 2)),
        });

        final result = await repository.getUserReferralInfo('user_1');

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<GenericFailure>());
            expect(failure.message, 'Not implemented');
          },
          (_) => fail('Expected a failure since getUserReferralInfo is a stub'),
        );
      });

      test('returns a failure for a user with no referral history', () async {
        final result = await repository.getUserReferralInfo('brand_new_user');

        expect(result.isLeft(), isTrue);
      });
    });

    group('getReferralStatistics', () {
      test('returns a failure even with realistic seeded referral data '
          '(statistics aggregation not yet implemented)', () async {
        // Seed a realistic mix of referral outcomes for the user.
        await firestore.collection('referrals').doc('ref_a').set({
          'referrerId': 'user_stats',
          'referredUserId': 'referred_a',
          'referralCode': 'HELSTATS001',
          'status': 'rewarded',
          'rewardAmount': 500.0,
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 3)),
          'rewardedAt': Timestamp.fromDate(DateTime(2026, 1, 5)),
        });
        await firestore.collection('referrals').doc('ref_b').set({
          'referrerId': 'user_stats',
          'referredUserId': 'referred_b',
          'referralCode': 'HELSTATS001',
          'status': 'pending',
          'rewardAmount': 500.0,
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 10)),
        });
        await firestore.collection('referrals').doc('ref_c').set({
          'referrerId': 'user_stats',
          'referredUserId': 'referred_c',
          'referralCode': 'HELSTATS001',
          'status': 'expired',
          'rewardAmount': 500.0,
          'createdAt': Timestamp.fromDate(DateTime(2025, 11, 3)),
        });

        final result = await repository.getReferralStatistics('user_stats');

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<GenericFailure>());
            expect(failure.message, 'Not implemented');
          },
          (_) =>
              fail('Expected a failure since getReferralStatistics is a stub'),
        );
      });
    });

    group('getUserReferrals', () {
      test(
        'returns an empty list even when referrals exist for the user',
        () async {
          await firestore.collection('referrals').doc('ref_1').set({
            'referrerId': 'user_1',
            'status': 'pending',
          });

          final result = await repository.getUserReferrals('user_1');

          expect(result.isRight(), isTrue);
          expect(result.getOrElse(() => [ReferralEntity.empty]), isEmpty);
        },
      );
    });

    group('getLeaderboard', () {
      test('returns an empty list regardless of Firestore contents', () async {
        final result = await repository.getLeaderboard();

        expect(result.isRight(), isTrue);
        expect(
          result.getOrElse(
            () => [
              const ReferralLeaderboardEntry(
                userId: 'x',
                referralCount: 1,
                totalRewards: 1,
              ),
            ],
          ),
          isEmpty,
        );
      });
    });

    group('getReferral', () {
      test('returns a failure for any referral ID', () async {
        await firestore.collection('referrals').doc('ref_1').set({
          'referrerId': 'user_1',
        });

        final result = await repository.getReferral('ref_1');

        expect(result.isLeft(), isTrue);
      });
    });

    group('completeReferral', () {
      test('returns a failure', () async {
        final result = await repository.completeReferral(
          referralId: 'ref_1',
          bookingId: 'booking_1',
        );

        expect(result.isLeft(), isTrue);
      });
    });

    group('updateRewardAmount', () {
      test('returns a failure and does not modify Firestore', () async {
        await firestore.collection('referrals').doc('ref_1').set({
          'rewardAmount': 500.0,
        });

        final result = await repository.updateRewardAmount(
          referralId: 'ref_1',
          newAmount: 750.0,
        );

        expect(result.isLeft(), isTrue);

        final doc = await firestore.collection('referrals').doc('ref_1').get();
        expect(doc.data()?['rewardAmount'], 500.0);
      });
    });

    group('processPendingRewards', () {
      test(
        'returns 0 processed rewards regardless of pending referrals',
        () async {
          await firestore.collection('referrals').doc('ref_1').set({
            'status': 'completed',
          });

          final result = await repository.processPendingRewards();

          expect(result.isRight(), isTrue);
          expect(result.getOrElse(() => -1), 0);
        },
      );
    });

    group('getAllReferrals', () {
      test('returns an empty list regardless of Firestore contents', () async {
        await firestore.collection('referrals').doc('ref_1').set({
          'referrerId': 'user_1',
        });

        final result = await repository.getAllReferrals();

        expect(result.isRight(), isTrue);
        expect(result.getOrElse(() => [ReferralEntity.empty]), isEmpty);
      });
    });

    group('watchUserReferrals', () {
      test('emits an empty list stream', () async {
        final stream = repository.watchUserReferrals('user_1');

        final result = await stream.first;

        expect(result.isRight(), isTrue);
        expect(result.getOrElse(() => [ReferralEntity.empty]), isEmpty);
      });
    });
  });
}
