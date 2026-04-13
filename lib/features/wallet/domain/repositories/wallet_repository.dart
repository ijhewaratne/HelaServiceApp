import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/wallet_entity.dart';

/// Payment methods for wallet top-up
enum WalletPaymentMethod {
  payhere,
  bankTransfer,
  card,
}

/// Abstract repository for wallet operations
///
/// Phase 7: Business Features - In-App Wallet
abstract class WalletRepository {
  /// Get or create wallet for user
  Future<Either<Failure, WalletEntity>> getWallet(String userId);

  /// Get wallet with transaction history
  Future<Either<Failure, WalletEntity>> getWalletWithTransactions(
    String userId, {
    int limit = 50,
    String? startAfter,
  });

  /// Top up wallet
  Future<Either<Failure, WalletEntity>> topUp({
    required String userId,
    required double amount,
    required WalletPaymentMethod method,
    String? description,
  });

  /// Process payment from wallet
  Future<Either<Failure, WalletEntity>> processPayment({
    required String userId,
    required double amount,
    required String bookingId,
    String? description,
  });

  /// Process refund to wallet
  Future<Either<Failure, WalletEntity>> processRefund({
    required String userId,
    required double amount,
    required String bookingId,
    String? description,
  });

  /// Get transaction history
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    required String userId,
    int limit = 50,
    String? startAfter,
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get a specific transaction
  Future<Either<Failure, TransactionEntity>> getTransaction(
    String transactionId,
  );

  /// Freeze wallet (admin only)
  Future<Either<Failure, WalletEntity>> freezeWallet(String userId);

  /// Unfreeze wallet (admin only)
  Future<Either<Failure, WalletEntity>> unfreezeWallet(String userId);

  /// Get wallet balance (real-time)
  Stream<Either<Failure, double>> watchBalance(String userId);

  /// Verify sufficient balance
  Future<Either<Failure, bool>> hasSufficientBalance(
    String userId,
    double amount,
  );

  /// Get wallet statistics
  Future<Either<Failure, WalletStatistics>> getWalletStatistics(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  });
}

/// Wallet statistics
class WalletStatistics {
  final double openingBalance;
  final double closingBalance;
  final double totalCredits;
  final double totalDebits;
  final int transactionCount;
  final Map<TransactionType, double> byType;

  const WalletStatistics({
    required this.openingBalance,
    required this.closingBalance,
    required this.totalCredits,
    required this.totalDebits,
    required this.transactionCount,
    required this.byType,
  });

  double get netChange => closingBalance - openingBalance;

  factory WalletStatistics.empty() {
    return const WalletStatistics(
      openingBalance: 0.0,
      closingBalance: 0.0,
      totalCredits: 0.0,
      totalDebits: 0.0,
      transactionCount: 0,
      byType: {},
    );
  }
}
