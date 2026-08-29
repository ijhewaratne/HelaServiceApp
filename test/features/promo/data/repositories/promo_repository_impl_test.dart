import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/core/errors/failures.dart';
import 'package:home_service_app/features/booking/domain/entities/booking.dart';
import 'package:home_service_app/features/promo/data/repositories/promo_repository_impl.dart';
import 'package:home_service_app/features/promo/domain/entities/promo_code_entity.dart';

// NOTE: As of this writing, `PromoRepositoryImpl` is an unimplemented stub —
// every method either returns `Left(GenericFailure('Not implemented'))` or a
// hardcoded empty/false `Right(...)`, regardless of what is stored in
// Firestore. None of the business rules that `PromoCodeEntity` already knows
// how to evaluate (expiry via `isTimeValid`, usage limits via
// `hasUsesRemaining`, minimum order amount via `calculateDiscount` /
// `validateForBooking`) are actually wired up to Firestore reads/writes yet.
//
// These tests pin down that *current* behavior so a future implementation is
// forced to consciously update this file (and, ideally, replace the
// "not implemented" style assertions below with real business-rule
// assertions once the repository grows real Firestore-backed logic).
void main() {
  late FakeFirebaseFirestore firestore;
  late PromoRepositoryImpl repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = PromoRepositoryImpl(firestore);
  });

  /// A promo code document that satisfies every business rule
  /// `PromoCodeEntity` knows how to check: it is within its validity window,
  /// has uses remaining, and the order amount clears the minimum.
  Future<void> seedActivePromoCode(
    FakeFirebaseFirestore db, {
    String code = 'SAVE10',
    DateTime? validFrom,
    DateTime? validUntil,
    int maxUses = 100,
    int currentUses = 5,
    double minOrderAmount = 500,
  }) async {
    await db.collection('promoCodes').doc(code).set({
      'code': code,
      'description': '10% off your order',
      'discountType': 'percentage',
      'discountAmount': 10.0,
      'validFrom': Timestamp.fromDate(validFrom ?? DateTime(2026)),
      'validUntil': Timestamp.fromDate(validUntil ?? DateTime(2027)),
      'maxUses': maxUses,
      'currentUses': currentUses,
      'minOrderAmount': minOrderAmount,
    });
  }

  PromoCodeEntity buildPromoEntity({
    String code = 'NEWCODE',
    double discountAmount = 250,
    int maxUses = 50,
  }) {
    return PromoCodeEntity(
      code: code,
      description: 'Flat LKR discount',
      discountType: DiscountType.fixed,
      discountAmount: discountAmount,
      validFrom: DateTime(2026),
      validUntil: DateTime(2027),
      maxUses: maxUses,
    );
  }

  group('PromoRepositoryImpl', () {
    group('validatePromoCode', () {
      test(
        'returns a failure even for a promo code that satisfies every '
        'business rule (valid window, uses remaining, order above minimum) '
        'because Firestore lookups are not implemented yet',
        () async {
          await seedActivePromoCode(firestore);

          final result = await repository.validatePromoCode(
            code: 'SAVE10',
            orderAmount: 1000,
            serviceType: ServiceType.cleaning,
            zoneId: 'colombo-1',
            userId: 'user_123',
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) {
              expect(failure, isA<GenericFailure>());
              expect(failure.message, 'Not implemented');
            },
            (_) => fail('Expected a Left(Failure), got a Right'),
          );
        },
      );

      test(
        'returns the same generic failure for an expired promo code '
        '(expiry is not yet distinguished from any other case)',
        () async {
          await seedActivePromoCode(
            firestore,
            code: 'EXPIRED5',
            validFrom: DateTime(2020),
            validUntil: DateTime(2021), // expired well before "now"
          );

          final result = await repository.validatePromoCode(
            code: 'EXPIRED5',
            orderAmount: 1000,
            serviceType: ServiceType.cleaning,
            zoneId: 'colombo-1',
            userId: 'user_123',
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<GenericFailure>()),
            (_) => fail('Expected a Left(Failure), got a Right'),
          );
        },
      );

      test(
        'returns a failure for a promo code that does not exist in Firestore '
        'at all (not-found is not yet distinguished either)',
        () async {
          final result = await repository.validatePromoCode(
            code: 'DOES_NOT_EXIST',
            orderAmount: 1000,
            serviceType: ServiceType.cleaning,
            zoneId: 'colombo-1',
            userId: 'user_123',
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<GenericFailure>()),
            (_) => fail('Expected a Left(Failure), got a Right'),
          );
        },
      );
    });

    group('applyPromoCode', () {
      test(
        'returns a failure and does not mutate the promo code usage count '
        'in Firestore',
        () async {
          await seedActivePromoCode(firestore);

          final result = await repository.applyPromoCode(
            code: 'SAVE10',
            userId: 'user_123',
            bookingId: 'booking_456',
            orderAmount: 1000,
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<GenericFailure>()),
            (_) => fail('Expected a Left(Failure), got a Right'),
          );

          // Since applyPromoCode is unimplemented, the usage count in
          // Firestore must remain untouched.
          final stored =
              await firestore.collection('promoCodes').doc('SAVE10').get();
          expect(stored.data()?['currentUses'], 5);
        },
      );
    });

    group('getPromoCode', () {
      test(
        'returns a failure even when a matching document exists',
        () async {
          await seedActivePromoCode(firestore);

          final result = await repository.getPromoCode('SAVE10');

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<GenericFailure>()),
            (_) => fail('Expected a Left(Failure), got a Right'),
          );
        },
      );
    });

    group('getActivePromoCodes', () {
      test(
        'ignores seeded Firestore data and always returns an empty list',
        () async {
          await seedActivePromoCode(firestore);
          await seedActivePromoCode(firestore, code: 'SAVE20');

          final result = await repository.getActivePromoCodes();

          expect(result.isRight(), isTrue);
          result.fold(
            (_) => fail('Expected a Right(<empty list>)'),
            (codes) => expect(codes, isEmpty),
          );
        },
      );
    });

    group('hasUserUsedPromoCode', () {
      test(
        'ignores an existing usage record in Firestore and always returns '
        'false',
        () async {
          await firestore.collection('promoUsages').add({
            'promoCode': 'SAVE10',
            'userId': 'user_123',
            'orderAmount': 1000.0,
            'discountApplied': 100.0,
            'usedAt': Timestamp.fromDate(DateTime(2026, 1, 5)),
          });

          final result = await repository.hasUserUsedPromoCode(
            userId: 'user_123',
            promoCode: 'SAVE10',
          );

          expect(result.isRight(), isTrue);
          expect(result.getOrElse(() => true), isFalse);
        },
      );

      test('returns false for a user with no usage history either', () async {
        final result = await repository.hasUserUsedPromoCode(
          userId: 'brand_new_user',
          promoCode: 'SAVE10',
        );

        expect(result.getOrElse(() => true), isFalse);
      });
    });

    group('getUserPromoUsage', () {
      test(
        'ignores seeded usage history and always returns an empty list',
        () async {
          await firestore.collection('promoUsages').add({
            'promoCode': 'SAVE10',
            'userId': 'user_123',
            'orderAmount': 1000.0,
            'discountApplied': 100.0,
            'usedAt': Timestamp.fromDate(DateTime(2026, 1, 5)),
          });

          final result =
              await repository.getUserPromoUsage(userId: 'user_123');

          expect(result.isRight(), isTrue);
          result.fold(
            (_) => fail('Expected a Right(<empty list>)'),
            (usages) => expect(usages, isEmpty),
          );
        },
      );
    });

    group('getTrendingPromoCodes', () {
      test(
        'ignores seeded promo codes and always returns an empty list',
        () async {
          await seedActivePromoCode(firestore);

          final result = await repository.getTrendingPromoCodes();

          expect(result.isRight(), isTrue);
          result.fold(
            (_) => fail('Expected a Right(<empty list>)'),
            (codes) => expect(codes, isEmpty),
          );
        },
      );
    });

    group('admin write operations', () {
      test(
        'createPromoCode returns a failure and does not persist a document',
        () async {
          final entity = buildPromoEntity();

          final result = await repository.createPromoCode(entity);

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<GenericFailure>()),
            (_) => fail('Expected a Left(Failure), got a Right'),
          );

          final stored =
              await firestore.collection('promoCodes').doc('NEWCODE').get();
          expect(stored.exists, isFalse);
        },
      );

      test(
        'updatePromoCode returns a failure and does not change an existing '
        'document',
        () async {
          await seedActivePromoCode(firestore);
          final updated = buildPromoEntity(
            code: 'SAVE10',
            discountAmount: 999,
          );

          final result = await repository.updatePromoCode(updated);

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<GenericFailure>()),
            (_) => fail('Expected a Left(Failure), got a Right'),
          );

          final stored =
              await firestore.collection('promoCodes').doc('SAVE10').get();
          expect(stored.data()?['minOrderAmount'], 500);
        },
      );

      test(
        'deactivatePromoCode returns a failure and leaves the document '
        'untouched',
        () async {
          await seedActivePromoCode(firestore);

          final result = await repository.deactivatePromoCode('SAVE10');

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<GenericFailure>()),
            (_) => fail('Expected a Left(Failure), got a Right'),
          );

          final stored =
              await firestore.collection('promoCodes').doc('SAVE10').get();
          expect(stored.exists, isTrue);
        },
      );

      test('getPromoCodeStatistics returns a failure', () async {
        await seedActivePromoCode(firestore);

        final result = await repository.getPromoCodeStatistics('SAVE10');

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<GenericFailure>()),
          (_) => fail('Expected a Left(Failure), got a Right'),
        );
      });
    });
  });
}
