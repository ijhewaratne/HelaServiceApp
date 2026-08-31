import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';

/// Releases the hold on [amount] back to available balance (e.g. booking cancelled).
/// Does NOT debit the customer — use SplitPayment for completion.
class ReleaseWalletFunds implements UseCase<void, ReleaseWalletFundsParams> {
  final FirebaseFirestore _db;
  ReleaseWalletFunds({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Either<Failure, void>> call(ReleaseWalletFundsParams params) async {
    try {
      // Wallet heldBalance is stored in integer cents; params.amount is LKR
      // (matching Booking.heldAmount elsewhere in the app).
      final amountCents = (params.amount * 100).round();

      await _db.runTransaction((tx) async {
        final ref = _db.collection('wallets').doc(params.customerId);
        final snap = await tx.get(ref);
        if (!snap.exists) throw Exception('Wallet not found');

        final data = snap.data()!;
        final held = (data['heldBalance'] as num?)?.toInt() ?? 0;
        final release = held < amountCents ? held : amountCents;

        tx.update(ref, {
          'heldBalance': FieldValue.increment(-release),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final bookingRef = _db.collection('bookings').doc(params.bookingId);
        tx.update(bookingRef, {'heldAmount': 0.0});
      });
      return const Right(null);
    } catch (e) {
      return Left(PaymentFailure('Failed to release funds: $e'));
    }
  }
}

class ReleaseWalletFundsParams extends Equatable {
  final String customerId;
  final String bookingId;
  final double amount;

  const ReleaseWalletFundsParams({
    required this.customerId,
    required this.bookingId,
    required this.amount,
  });

  @override
  List<Object?> get props => [customerId, bookingId, amount];
}
