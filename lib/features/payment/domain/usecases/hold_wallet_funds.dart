import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';

/// Moves [amount] from balance → heldBalance when a booking is confirmed.
/// Fails if the customer doesn't have enough available funds.
class HoldWalletFunds implements UseCase<void, HoldWalletFundsParams> {
  final FirebaseFirestore _db;
  HoldWalletFunds({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Either<Failure, void>> call(HoldWalletFundsParams params) async {
    try {
      await _db.runTransaction((tx) async {
        final ref = _db.collection('wallets').doc(params.customerId);
        final snap = await tx.get(ref);
        if (!snap.exists) throw Exception('Wallet not found');

        final data = snap.data()!;
        final balance = (data['balance'] as num?)?.toDouble() ?? 0.0;
        final held = (data['heldBalance'] as num?)?.toDouble() ?? 0.0;
        final available = balance - held;

        if (available < params.amount) {
          throw Exception(
              'Insufficient available balance: $available < ${params.amount}');
        }

        tx.update(ref, {
          'heldBalance': FieldValue.increment(params.amount),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Mirror held amount onto the booking
        final bookingRef =
            _db.collection('bookings').doc(params.bookingId);
        tx.update(bookingRef, {'heldAmount': params.amount});
      });
      return const Right(null);
    } catch (e) {
      return Left(PaymentFailure('Failed to hold funds: $e'));
    }
  }
}

class HoldWalletFundsParams extends Equatable {
  final String customerId;
  final String bookingId;
  final double amount;

  const HoldWalletFundsParams({
    required this.customerId,
    required this.bookingId,
    required this.amount,
  });

  @override
  List<Object?> get props => [customerId, bookingId, amount];
}
