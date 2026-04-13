import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';

/// Implementation of WalletRepository using Firebase Firestore
///
/// Phase 7: Business Features - In-App Wallet
class WalletRepositoryImpl implements WalletRepository {
  final FirebaseFirestore _firestore;

  WalletRepositoryImpl(this._firestore);

  @override
  Future<Either<Failure, WalletEntity>> getWallet(String userId) async {
    try {
      final doc = await _firestore.collection('wallets').doc(userId).get();

      if (!doc.exists) {
        // Create new wallet
        final newWallet = WalletModel(
          userId: userId,
          balance: 0.0,
          totalCredited: 0.0,
          totalDebited: 0.0,
          isActive: true,
          isFrozen: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore.collection('wallets').doc(userId).set({
          ...newWallet.toFirestore(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return Right(newWallet.toEntity());
      }

      return Right(WalletModel.fromFirestore(doc).toEntity());
    } catch (e) {
      return Left(ServerFailure('Failed to get wallet: $e'));
    }
  }

  @override
  Future<Either<Failure, WalletEntity>> getWalletWithTransactions(
    String userId, {
    int limit = 50,
    String? startAfter,
  }) async {
    try {
      final walletDoc = await _firestore.collection('wallets').doc(userId).get();

      if (!walletDoc.exists) {
        return await getWallet(userId);
      }

      // Get transactions
      Query query = _firestore
          .collection('wallet_transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        final startDoc = await _firestore
            .collection('wallet_transactions')
            .doc(startAfter)
            .get();
        if (startDoc.exists) {
          query = query.startAfterDocument(startDoc);
        }
      }

      final transactionsSnapshot = await query.get();

      return Right(WalletModel.fromFirestore(
        walletDoc,
        transactionsSnapshot: transactionsSnapshot,
      ).toEntity());
    } catch (e) {
      return Left(ServerFailure('Failed to get wallet with transactions: $e'));
    }
  }

  @override
  Future<Either<Failure, WalletEntity>> topUp({
    required String userId,
    required double amount,
    required WalletPaymentMethod method,
    String? description,
  }) async {
    try {
      if (amount <= 0) {
        return Left(ValidationFailure('Amount must be greater than 0'));
      }

      // Use Firestore transaction for atomic operation
      return await _firestore.runTransaction<Either<Failure, WalletEntity>>(
        (transaction) async {
          final walletRef = _firestore.collection('wallets').doc(userId);
          final snapshot = await transaction.get(walletRef);

          if (!snapshot.exists) {
            // Create wallet first
            transaction.set(walletRef, {
              'balance': amount,
              'totalCredited': amount,
              'totalDebited': 0.0,
              'isActive': true,
              'isFrozen': false,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            final currentBalance =
                ((snapshot.data()?['balance'] ?? 0.0) as num).toDouble();
            final currentTotalCredited =
                ((snapshot.data()?['totalCredited'] ?? 0.0) as num).toDouble();

            final newBalance = currentBalance + amount;
            final newTotalCredited = currentTotalCredited + amount;

            transaction.update(walletRef, {
              'balance': newBalance,
              'totalCredited': newTotalCredited,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }

          // Add transaction record
          final transactionRef =
              _firestore.collection('wallet_transactions').doc();
          transaction.set(transactionRef, {
            'userId': userId,
            'type': 'topUp',
            'amount': amount,
            'balanceAfter': !snapshot.exists
                ? amount
                : ((snapshot.data()?['balance'] ?? 0.0) as num).toDouble() +
                    amount,
            'description': description ?? 'Wallet top-up',
            'paymentMethod': method.name,
            'status': 'completed',
            'createdAt': FieldValue.serverTimestamp(),
          });

          final updatedWallet = WalletModel(
            userId: userId,
            balance: !snapshot.exists
                ? amount
                : ((snapshot.data()?['balance'] ?? 0.0) as num).toDouble() +
                    amount,
            totalCredited: !snapshot.exists
                ? amount
                : ((snapshot.data()?['totalCredited'] ?? 0.0) as num)
                        .toDouble() +
                    amount,
            totalDebited: (snapshot.data()?['totalDebited'] ?? 0.0) as double,
            isActive: true,
            isFrozen: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          return Right(updatedWallet.toEntity());
        },
      );
    } catch (e) {
      return Left(ServerFailure('Failed to top up wallet: $e'));
    }
  }

  @override
  Future<Either<Failure, WalletEntity>> processPayment({
    required String userId,
    required double amount,
    required String bookingId,
    String? description,
  }) async {
    try {
      if (amount <= 0) {
        return Left(ValidationFailure('Amount must be greater than 0'));
      }

      return await _firestore.runTransaction<Either<Failure, WalletEntity>>(
        (transaction) async {
          final walletRef = _firestore.collection('wallets').doc(userId);
          final snapshot = await transaction.get(walletRef);

          if (!snapshot.exists) {
            return Left(ValidationFailure('Wallet not found'));
          }

          final walletData = snapshot.data()!;
          final currentBalance = (walletData['balance'] ?? 0.0) as double;
          final isFrozen = walletData['isFrozen'] ?? false;
          final isActive = walletData['isActive'] ?? true;

          if (!isActive) {
            return Left(ValidationFailure('Wallet is inactive'));
          }

          if (isFrozen) {
            return Left(ValidationFailure('Wallet is frozen'));
          }

          if (currentBalance < amount) {
            return Left(ValidationFailure('Insufficient balance'));
          }

          final currentTotalDebited =
              (walletData['totalDebited'] ?? 0.0) as double;
          final newBalance = currentBalance - amount;
          final newTotalDebited = currentTotalDebited + amount;

          transaction.update(walletRef, {
            'balance': newBalance,
            'totalDebited': newTotalDebited,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Add transaction record
          final transactionRef =
              _firestore.collection('wallet_transactions').doc();
          transaction.set(transactionRef, {
            'userId': userId,
            'type': 'payment',
            'amount': -amount,
            'balanceAfter': newBalance,
            'description': description ?? 'Payment for booking',
            'relatedBookingId': bookingId,
            'status': 'completed',
            'createdAt': FieldValue.serverTimestamp(),
          });

          return Right(WalletModel.fromFirestore(snapshot).copyWith(
            balance: newBalance,
            totalDebited: newTotalDebited,
          ).toEntity());
        },
      );
    } catch (e) {
      return Left(ServerFailure('Failed to process payment: $e'));
    }
  }

  @override
  Future<Either<Failure, WalletEntity>> processRefund({
    required String userId,
    required double amount,
    required String bookingId,
    String? description,
  }) async {
    try {
      return await _firestore.runTransaction<Either<Failure, WalletEntity>>(
        (transaction) async {
          final walletRef = _firestore.collection('wallets').doc(userId);
          final snapshot = await transaction.get(walletRef);

          if (!snapshot.exists) {
            return Left(ValidationFailure('Wallet not found'));
          }

          final walletData = snapshot.data()!;
          final currentBalance = (walletData['balance'] ?? 0.0) as double;
          final currentTotalCredited =
              (walletData['totalCredited'] ?? 0.0) as double;

          final newBalance = currentBalance + amount;
          final newTotalCredited = currentTotalCredited + amount;

          transaction.update(walletRef, {
            'balance': newBalance,
            'totalCredited': newTotalCredited,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Add transaction record
          final transactionRef =
              _firestore.collection('wallet_transactions').doc();
          transaction.set(transactionRef, {
            'userId': userId,
            'type': 'refund',
            'amount': amount,
            'balanceAfter': newBalance,
            'description': description ?? 'Refund for cancelled booking',
            'relatedBookingId': bookingId,
            'status': 'completed',
            'createdAt': FieldValue.serverTimestamp(),
          });

          return Right(WalletModel.fromFirestore(snapshot).copyWith(
            balance: newBalance,
            totalCredited: newTotalCredited,
          ).toEntity());
        },
      );
    } catch (e) {
      return Left(ServerFailure('Failed to process refund: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    required String userId,
    int limit = 50,
    String? startAfter,
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('wallet_transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      if (startDate != null) {
        query = query.where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      if (startAfter != null) {
        final startDoc = await _firestore
            .collection('wallet_transactions')
            .doc(startAfter)
            .get();
        if (startDoc.exists) {
          query = query.startAfterDocument(startDoc);
        }
      }

      final snapshot = await query.get();

      return Right(snapshot.docs
          .map((d) => TransactionModel.fromFirestore(d).toEntity())
          .toList());
    } catch (e) {
      return Left(ServerFailure('Failed to get transactions: $e'));
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> getTransaction(
    String transactionId,
  ) async {
    try {
      final doc = await _firestore
          .collection('wallet_transactions')
          .doc(transactionId)
          .get();

      if (!doc.exists) {
        return Left(NotFoundFailure('Transaction not found'));
      }

      return Right(TransactionModel.fromFirestore(doc).toEntity());
    } catch (e) {
      return Left(ServerFailure('Failed to get transaction: $e'));
    }
  }

  @override
  Future<Either<Failure, WalletEntity>> freezeWallet(String userId) async {
    try {
      await _firestore.collection('wallets').doc(userId).update({
        'isFrozen': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final updated = await _firestore.collection('wallets').doc(userId).get();
      return Right(WalletModel.fromFirestore(updated).toEntity());
    } catch (e) {
      return Left(ServerFailure('Failed to freeze wallet: $e'));
    }
  }

  @override
  Future<Either<Failure, WalletEntity>> unfreezeWallet(String userId) async {
    try {
      await _firestore.collection('wallets').doc(userId).update({
        'isFrozen': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final updated = await _firestore.collection('wallets').doc(userId).get();
      return Right(WalletModel.fromFirestore(updated).toEntity());
    } catch (e) {
      return Left(ServerFailure('Failed to unfreeze wallet: $e'));
    }
  }

  @override
  Stream<Either<Failure, double>> watchBalance(String userId) {
    return _firestore
        .collection('wallets')
        .doc(userId)
        .snapshots()
        .map<Either<Failure, double>>((snapshot) {
      if (!snapshot.exists) {
        return const Right(0.0);
      }
      final data = snapshot.data();
      return Right((data?['balance'] ?? 0.0) as double);
    }).handleError((e) {
      return Left<Failure, double>(ServerFailure('Failed to watch balance: $e'));
    });
  }

  @override
  Future<Either<Failure, bool>> hasSufficientBalance(
    String userId,
    double amount,
  ) async {
    final walletResult = await getWallet(userId);
    return walletResult.map((wallet) => wallet.hasSufficientBalance(amount));
  }

  @override
  Future<Either<Failure, WalletStatistics>> getWalletStatistics(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final walletResult = await getWallet(userId);
      if (walletResult.isLeft()) {
        return Left(
            walletResult.fold((l) => l, (r) => ServerFailure('Unknown error')));
      }

      final wallet = walletResult.getOrElse(() => throw Exception());

      DateTime start = startDate ??
          DateTime.now().subtract(const Duration(days: 30));
      DateTime end = endDate ?? DateTime.now();

      final transactions = await getTransactions(
        userId: userId,
        startDate: start,
        endDate: end,
        limit: 1000,
      );

      return transactions.map((txList) {
        double totalCredits = 0.0;
        double totalDebits = 0.0;
        Map<TransactionType, double> byType = {};

        for (final tx in txList) {
          if (tx.amount > 0) {
            totalCredits += tx.amount;
          } else {
            totalDebits += tx.amount.abs();
          }

          byType[tx.type] = (byType[tx.type] ?? 0.0) + tx.amount.abs();
        }

        return WalletStatistics(
          openingBalance: wallet.balance - totalCredits + totalDebits,
          closingBalance: wallet.balance,
          totalCredits: totalCredits,
          totalDebits: totalDebits,
          transactionCount: txList.length,
          byType: byType,
        );
      });
    } catch (e) {
      return Left(ServerFailure('Failed to get wallet statistics: $e'));
    }
  }
}
