import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/payout.dart';

/// Settles a completed booking: releases the held amount from the customer's
/// wallet, records the 80/20 split, and creates a pending payout for the worker.
///
/// This runs inside a Firestore transaction so all writes are atomic.
class SplitPayment implements UseCase<Payout, SplitPaymentParams> {
  final FirebaseFirestore _db;

  SplitPayment({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Either<Failure, Payout>> call(SplitPaymentParams params) async {
    try {
      late Payout payout;

      // Wallet balance/heldBalance/totalDebited are stored in integer cents;
      // params.amount is LKR (matching Booking.finalPrice, Payout.grossAmount,
      // and the transactions log below, which all stay LKR).
      final amountCents = (params.amount * 100).round();

      await _db.runTransaction((tx) async {
        // 1. Read customer wallet
        final walletRef = _db.collection('wallets').doc(params.customerId);
        final walletSnap = await tx.get(walletRef);

        if (!walletSnap.exists) {
          throw Exception('Customer wallet not found');
        }

        final walletData = walletSnap.data()!;
        final held = (walletData['heldBalance'] as num?)?.toInt() ?? 0;
        final balance = (walletData['balance'] as num?)?.toInt() ?? 0;

        if (held < amountCents) {
          throw Exception(
            'Held amount ($held) less than requested ($amountCents)',
          );
        }

        // 2. Debit customer: release hold and debit from balance
        tx.update(walletRef, {
          'balance': balance - amountCents,
          'heldBalance': held - amountCents,
          'totalDebited': FieldValue.increment(amountCents),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 3. Log customer transaction (amount in cents, matching the wallet
        // fields above and every other writer of this collection)
        final txRef = _db.collection('transactions').doc();
        tx.set(txRef, {
          'id': txRef.id,
          'userId': params.customerId,
          'type': 'payment',
          'amount': amountCents,
          'description': 'Payment for booking ${params.bookingId}',
          'relatedBookingId': params.bookingId,
          'status': 'completed',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 4. Create payout record for worker
        final payoutRef = _db.collection('payouts').doc();
        payout = Payout.calculate(
          id: payoutRef.id,
          workerId: params.workerId,
          grossAmount: params.amount,
          periodStart: DateTime.now(),
          periodEnd: DateTime.now(),
          bookingIds: [params.bookingId],
        );
        tx.set(payoutRef, payout.toJson());

        // 5. Mark booking as paid
        final bookingRef = _db.collection('bookings').doc(params.bookingId);
        tx.update(bookingRef, {
          'finalPrice': params.amount,
          'heldAmount': 0.0,
          'payoutId': payoutRef.id,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      return Right(payout);
    } catch (e) {
      return Left(PaymentFailure('Split payment failed: $e'));
    }
  }
}

class SplitPaymentParams extends Equatable {
  final String bookingId;
  final String customerId;
  final String workerId;
  final double amount;

  const SplitPaymentParams({
    required this.bookingId,
    required this.customerId,
    required this.workerId,
    required this.amount,
  });

  @override
  List<Object?> get props => [bookingId, customerId, workerId, amount];
}
