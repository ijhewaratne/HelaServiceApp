import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/features/payment/data/repositories/payout_repository_impl.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late PayoutRepositoryImpl repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = PayoutRepositoryImpl(firestore: firestore);
  });

  group('generateWeeklyPayouts', () {
    test(
        'includes completed bookings that have never had a payoutId field',
        () async {
      // No payoutId field at all — this is the real shape of a normal booking
      // fresh off booking_repository_impl.dart, which never sets it.
      //
      // NOTE: this does NOT regression-test the original bug. Real Firestore
      // never matches a query filter (isNull included) against a document
      // missing that field, but fake_cloud_firestore's isNull is more lenient
      // and matches missing fields too — verified by temporarily reverting
      // this repository to `.where('payoutId', isNull: true)`, which still
      // passed this test. The application-side `data['payoutId'] != null`
      // check below is what makes this correct against real Firestore; this
      // test only proves the current filtering logic behaves as intended.
      await firestore.collection('bookings').doc('booking_1').set({
        'status': 'completed',
        'workerId': 'worker_1',
        'finalPrice': 2000.0,
      });

      final result = await repository.generateWeeklyPayouts();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected payouts to be generated'),
        (payoutIds) => expect(payoutIds, hasLength(1)),
      );

      final bookingDoc =
          await firestore.collection('bookings').doc('booking_1').get();
      expect(bookingDoc.data()?['payoutId'], isNotNull);

      final payoutsSnap = await firestore.collection('payouts').get();
      expect(payoutsSnap.docs, hasLength(1));
      final payout = payoutsSnap.docs.first.data();
      expect(payout['workerId'], 'worker_1');
      expect(payout['grossAmount'], 2000.0);
      expect(payout['platformFee'], 400.0);
      expect(payout['workerAmount'], 1600.0);
    });

    test('excludes bookings that already have a payoutId', () async {
      await firestore.collection('bookings').doc('already_paid').set({
        'status': 'completed',
        'workerId': 'worker_1',
        'finalPrice': 1000.0,
        'payoutId': 'existing_payout',
      });

      final result = await repository.generateWeeklyPayouts();

      result.fold(
        (_) => fail('Expected an empty payout list'),
        (payoutIds) => expect(payoutIds, isEmpty),
      );
    });

    test('excludes bookings that are not completed', () async {
      await firestore.collection('bookings').doc('in_progress').set({
        'status': 'inProgress',
        'workerId': 'worker_1',
        'finalPrice': 1000.0,
      });

      final result = await repository.generateWeeklyPayouts();

      result.fold(
        (_) => fail('Expected an empty payout list'),
        (payoutIds) => expect(payoutIds, isEmpty),
      );
    });

    test('groups multiple unpaid bookings for the same worker into one payout',
        () async {
      await firestore.collection('bookings').doc('b1').set({
        'status': 'completed',
        'workerId': 'worker_1',
        'finalPrice': 1000.0,
      });
      await firestore.collection('bookings').doc('b2').set({
        'status': 'completed',
        'workerId': 'worker_1',
        'estimatedPrice': 500.0,
      });

      final result = await repository.generateWeeklyPayouts();

      result.fold(
        (_) => fail('Expected one payout'),
        (payoutIds) => expect(payoutIds, hasLength(1)),
      );

      final payoutsSnap = await firestore.collection('payouts').get();
      final payout = payoutsSnap.docs.first.data();
      expect(payout['grossAmount'], 1500.0);
      expect((payout['bookingIds'] as List).toSet(), {'b1', 'b2'});
    });

    test('skips bookings with no workerId', () async {
      await firestore.collection('bookings').doc('orphaned').set({
        'status': 'completed',
        'finalPrice': 1000.0,
      });

      final result = await repository.generateWeeklyPayouts();

      result.fold(
        (_) => fail('Expected an empty payout list'),
        (payoutIds) => expect(payoutIds, isEmpty),
      );
    });
  });

  group('getWorkerPayouts', () {
    test('returns only the requested worker\'s payouts, newest first',
        () async {
      await firestore.collection('payouts').doc('p1').set({
        'id': 'p1',
        'workerId': 'worker_1',
        'grossAmount': 100.0,
        'platformFee': 20.0,
        'workerAmount': 80.0,
        'status': 'pending',
        'periodStart': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'periodEnd': Timestamp.fromDate(DateTime(2026, 1, 8)),
        'bookingIds': ['b1'],
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 8)),
      });
      await firestore.collection('payouts').doc('p2').set({
        'id': 'p2',
        'workerId': 'worker_2',
        'grossAmount': 200.0,
        'platformFee': 40.0,
        'workerAmount': 160.0,
        'status': 'pending',
        'periodStart': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'periodEnd': Timestamp.fromDate(DateTime(2026, 1, 8)),
        'bookingIds': ['b2'],
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 8)),
      });

      final result = await repository.getWorkerPayouts('worker_1');

      result.fold(
        (_) => fail('Expected payouts for worker_1'),
        (payouts) {
          expect(payouts, hasLength(1));
          expect(payouts.first.workerId, 'worker_1');
        },
      );
    });
  });
}
