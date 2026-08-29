import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/features/wallet/domain/entities/wallet_entity.dart';

void main() {
  group('WalletEntity', () {
    test('availableBalance is derived from balance - heldBalance, in cents',
        () {
      final wallet = WalletEntity(
        userId: 'u1',
        balance: 150000,
        heldBalance: 50000,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(wallet.availableBalance, 100000);
      expect(wallet.availableBalanceLKR, 1000.0);
    });

    test('formattedBalance renders cents as an LKR string with 2 decimals',
        () {
      final wallet = WalletEntity(
        userId: 'u1',
        balance: 123456,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(wallet.formattedBalance, 'LKR 1234.56');
    });

    test('hasSufficientBalance compares in cents and respects isFrozen', () {
      final wallet = WalletEntity(
        userId: 'u1',
        balance: 1000,
        heldBalance: 0,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(wallet.hasSufficientBalance(1000), isTrue);
      expect(wallet.hasSufficientBalance(1001), isFalse);

      final frozen = WalletEntity(
        userId: 'u1',
        balance: 1000,
        isFrozen: true,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(frozen.hasSufficientBalance(1), isFalse);
    });
  });

  group('TransactionEntity', () {
    test('formattedAmount converts cents to a signed LKR string', () {
      final credit = TransactionEntity(
        id: 't1',
        userId: 'u1',
        type: TransactionType.topUp,
        amount: 50000,
        balanceAfter: 50000,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(credit.formattedAmount, '+ LKR 500.00');

      final debit = TransactionEntity(
        id: 't2',
        userId: 'u1',
        type: TransactionType.payment,
        amount: -25000,
        balanceAfter: 25000,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(debit.formattedAmount, '- LKR 250.00');
    });
  });
}
