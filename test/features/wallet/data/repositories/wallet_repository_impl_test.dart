import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:home_service_app/features/wallet/domain/repositories/wallet_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late WalletRepositoryImpl repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = WalletRepositoryImpl(firestore);
  });

  group('getWallet', () {
    test('creates a zero-balance wallet in cents when none exists', () async {
      final result = await repository.getWallet('user_1');

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected wallet'), (wallet) {
        expect(wallet.balance, 0);
        expect(wallet.heldBalance, 0);
      });

      final doc = await firestore.collection('wallets').doc('user_1').get();
      expect(doc.data()?['balance'], 0);
      expect(doc.data()?.containsKey('availableBalance'), isFalse);
    });

    test('reads back an existing wallet stored in cents, including heldBalance',
        () async {
      await firestore.collection('wallets').doc('user_2').set({
        'balance': 150000, // LKR 1,500.00
        'heldBalance': 50000, // LKR 500.00
        'totalCredited': 150000,
        'totalDebited': 0,
        'isActive': true,
        'isFrozen': false,
        'createdAt': DateTime(2026, 1, 1),
      });

      final result = await repository.getWallet('user_2');

      result.fold((_) => fail('expected wallet'), (wallet) {
        expect(wallet.balance, 150000);
        expect(wallet.heldBalance, 50000);
        // This is the bug fix: heldBalance used to never be mapped from
        // Firestore at all, so availableBalance was always wrong.
        expect(wallet.availableBalance, 100000);
        expect(wallet.availableBalanceLKR, 1000.0);
        expect(wallet.formattedBalance, 'LKR 1500.00');
      });
    });
  });

  group('topUp', () {
    test('credits balance and totalCredited in cents for a new wallet',
        () async {
      final result = await repository.topUp(
        userId: 'user_3',
        amount: 100000, // LKR 1,000.00
        method: WalletPaymentMethod.payhere,
      );

      expect(result.isRight(), isTrue);

      final doc = await firestore.collection('wallets').doc('user_3').get();
      expect(doc.data()?['balance'], 100000);
      expect(doc.data()?['totalCredited'], 100000);

      final txSnap = await firestore.collection('wallet_transactions').get();
      expect(txSnap.docs, hasLength(1));
      expect(txSnap.docs.first.data()['amount'], 100000);
      expect(txSnap.docs.first.data()['balanceAfter'], 100000);
    });

    test('accumulates across repeated top-ups without float drift', () async {
      // 1/3 of a rupee repeated many times would visibly drift under doubles;
      // as integer cents it must not.
      for (var i = 0; i < 30; i++) {
        await repository.topUp(
          userId: 'user_4',
          amount: 33,
          method: WalletPaymentMethod.card,
        );
      }

      final doc = await firestore.collection('wallets').doc('user_4').get();
      expect(doc.data()?['balance'], 990); // exactly 30 * 33, no drift
    });

    test('rejects a non-positive amount', () async {
      final result = await repository.topUp(
        userId: 'user_5',
        amount: 0,
        method: WalletPaymentMethod.card,
      );

      expect(result.isLeft(), isTrue);
    });
  });

  group('processPayment', () {
    test('debits balance in cents and rejects insufficient balance', () async {
      await firestore.collection('wallets').doc('user_6').set({
        'balance': 5000,
        'heldBalance': 0,
        'totalCredited': 5000,
        'totalDebited': 0,
        'isActive': true,
        'isFrozen': false,
        'createdAt': DateTime(2026, 1, 1),
      });

      final tooMuch = await repository.processPayment(
        userId: 'user_6',
        amount: 10000,
        bookingId: 'booking_1',
      );
      expect(tooMuch.isLeft(), isTrue);

      final ok = await repository.processPayment(
        userId: 'user_6',
        amount: 2000,
        bookingId: 'booking_1',
      );
      expect(ok.isRight(), isTrue);

      final doc = await firestore.collection('wallets').doc('user_6').get();
      expect(doc.data()?['balance'], 3000);
      expect(doc.data()?['totalDebited'], 2000);
    });
  });

  group('watchBalance', () {
    test('emits the balance in cents', () async {
      await firestore.collection('wallets').doc('user_7').set({
        'balance': 4200,
        'isActive': true,
        'isFrozen': false,
        'createdAt': DateTime(2026, 1, 1),
      });

      final result = await repository.watchBalance('user_7').first;

      result.fold((_) => fail('expected balance'), (balance) {
        expect(balance, 4200);
      });
    });
  });
}
