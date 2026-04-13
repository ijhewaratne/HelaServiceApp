import 'package:dartz/dartz.dart';
// import 'package:flutter_payhere/flutter_payhere.dart';  // Temporarily disabled
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/payment_result.dart';
import '../../domain/repositories/payment_repository.dart';

/// Implementation of PaymentRepository using PayHere (Sri Lanka)
class PaymentRepositoryImpl implements PaymentRepository {
  final FirebaseFirestore _firestore;
  final bool _sandbox;
  final String _merchantId;
  final String _merchantSecret;
  final String _notifyUrl;

  PaymentRepositoryImpl(
    this._firestore, {
    bool? sandbox,
    String? merchantId,
    String? merchantSecret,
    String? notifyUrl,
  })  : _sandbox = sandbox ??
            _getBoolFromEnv('PAYHERE_SANDBOX', fallback: true),
        _merchantId = merchantId ?? dotenv.get('PAYHERE_MERCHANT_ID', fallback: ''),
        _merchantSecret =
            merchantSecret ?? dotenv.get('PAYHERE_MERCHANT_SECRET', fallback: ''),
        _notifyUrl = notifyUrl ??
            dotenv.get(
              'PAYHERE_NOTIFY_URL',
              fallback:
                  'https://us-central1-helaservice-prod.cloudfunctions.net/payhereNotify',
            );

  static bool _getBoolFromEnv(String key, {bool fallback = false}) {
    final value = dotenv.get(key, fallback: fallback.toString());
    return value.toLowerCase() == 'true';
  }

  @override
  Future<Either<Failure, PaymentResult>> processPayment({
    required String bookingId,
    required int amount,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    String? customerAddress,
    String? customerCity,
    String? description,
  }) async {
    try {
      // Validate configuration
      if (_merchantId.isEmpty || _merchantSecret.isEmpty) {
        return const Left(
          PaymentFailure(
            'PayHere not configured. Check .env file.',
            type: PaymentFailureType.initialization,
          ),
        );
      }

      // Validate amount (must be at least LKR 10.00 = 1000 cents)
      if (amount < 1000) {
        return const Left(
          PaymentFailure(
            'Minimum payment amount is LKR 10.00',
            type: PaymentFailureType.invalidAmount,
          ),
        );
      }

      // Parse name into first and last
      final nameParts = _parseName(customerName);

      // Format phone number
      final formattedPhone = _formatPhoneNumber(customerPhone);

      // TODO: Implement PayHere payment
      // Stub implementation for demo
      await Future.delayed(const Duration(seconds: 2));
      
      final paymentResult = PaymentResult(
        success: true,
        paymentId: 'PAY_${DateTime.now().millisecondsSinceEpoch}',
        orderId: bookingId,
        amount: amount,
        currency: 'LKR',
        status: PaymentStatus.completed,
        timestamp: DateTime.now(),
      );

      // Save to Firestore if successful
      if (paymentResult.success && paymentResult.paymentId != null) {
        await _savePaymentToFirestore(paymentResult, bookingId);
      }

      return Right(paymentResult);
    } catch (e) {
      return Left(
        PaymentFailure(
          'Payment processing error: $e',
          type: PaymentFailureType.unknown,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, PaymentStatus>> checkPaymentStatus(
    String orderId,
  ) async {
    try {
      // Query Firestore for the latest payment with this order ID
      final query = await _firestore
          .collection('payments')
          .where('orderId', isEqualTo: orderId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return const Left(NotFoundFailure('Payment not found'));
      }

      final data = query.docs.first.data();
      final status = PaymentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => PaymentStatus.unknown,
      );

      return Right(status);
    } catch (e) {
      return Left(
        PaymentFailure('Failed to check payment status: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, PaymentResult>> refundPayment({
    required String paymentId,
    int? amount,
    String? reason,
  }) async {
    try {
      // In a real implementation, this would call PayHere API
      // For now, mark as refunded in Firestore
      await _firestore.collection('payments').doc(paymentId).update({
        'status': 'refunded',
        'refundAmount': amount,
        'refundReason': reason,
        'refundedAt': FieldValue.serverTimestamp(),
      });

      // Also update booking
      final paymentDoc = await _firestore.collection('payments').doc(paymentId).get();
      if (paymentDoc.exists) {
        final bookingId = paymentDoc.data()?['orderId'];
        if (bookingId != null) {
          await _firestore.collection('bookings').doc(bookingId).update({
            'paymentStatus': 'refunded',
            'refundedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return Right(
        PaymentResult.success(
          paymentId: 'ref_${DateTime.now().millisecondsSinceEpoch}',
          orderId: paymentId,
        ),
      );
    } catch (e) {
      return Left(PaymentFailure('Refund failed: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PaymentResult>>> getCustomerPaymentHistory(
    String customerId,
  ) async {
    try {
      final query = await _firestore
          .collection('payments')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      final payments = query.docs
          .map((doc) => PaymentResult.fromJson(doc.data()))
          .toList();

      return Right(payments);
    } catch (e) {
      return Left(PaymentFailure('Failed to get payment history: $e'));
    }
  }

  @override
  Future<Either<Failure, PaymentResult>> getPaymentById(
    String paymentId,
  ) async {
    try {
      final doc = await _firestore.collection('payments').doc(paymentId).get();

      if (!doc.exists) {
        return const Left(NotFoundFailure('Payment not found'));
      }

      return Right(PaymentResult.fromJson(doc.data()!));
    } catch (e) {
      return Left(PaymentFailure('Failed to get payment: $e'));
    }
  }

  // ==================== Helper Methods ====================

  /// Parse full name into first and last name parts
  _NameParts _parseName(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length == 1) {
      return _NameParts(parts[0], '');
    }
    return _NameParts(parts.first, parts.skip(1).join(' '));
  }

  /// Format Sri Lankan phone number for PayHere
  String _formatPhoneNumber(String phone) {
    // Remove all non-digit characters
    var digits = phone.replaceAll(RegExp(r'\D'), '');

    // Convert international format (94...) to local (0...)
    if (digits.startsWith('94') && digits.length == 11) {
      digits = '0${digits.substring(2)}';
    }
    // Add leading zero if missing
    else if (!digits.startsWith('0') && digits.length == 9) {
      digits = '0$digits';
    }

    return digits;
  }

  /// Map PayHere result to our PaymentResult entity
  PaymentResult _mapToPaymentResult(
    dynamic result,
    String orderId,
    int amount,
  ) {
    if (result is PayHerePaymentSuccessResult) {
      return PaymentResult.success(
        paymentId: result.paymentId,
        orderId: result.orderId ?? orderId,
        amount: amount / 100.0,
        currency: 'LKR',
      );
    } else if (result is PayHerePaymentErrorResult) {
      return PaymentResult.failure(
        message: result.message,
        orderId: orderId,
        status: PaymentStatus.failed,
      );
    } else if (result is PayHerePaymentDismissResult) {
      return PaymentResult.failure(
        message: 'Payment cancelled by user',
        orderId: orderId,
        status: PaymentStatus.cancelled,
      );
    }

    return PaymentResult.failure(
      message: 'Unknown payment result type',
      orderId: orderId,
      status: PaymentStatus.unknown,
    );
  }

  /// Save successful payment to Firestore
  Future<void> _savePaymentToFirestore(
    PaymentResult result,
    String bookingId,
  ) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    await _firestore.collection('payments').doc(result.paymentId).set({
      'paymentId': result.paymentId,
      'orderId': result.orderId,
      'bookingId': bookingId,
      'customerId': userId,
      'amount': result.amount,
      'currency': result.currency ?? 'LKR',
      'status': result.status.name,
      'processedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'method': 'payhere',
    });

    // Update booking with payment reference
    await _firestore.collection('bookings').doc(bookingId).update({
      'paymentId': result.paymentId,
      'paymentStatus': 'completed',
      'paidAmount': result.amount,
      'paidAt': FieldValue.serverTimestamp(),
    });
  }
}

/// Helper class for name parsing
class _NameParts {
  final String firstName;
  final String lastName;
  _NameParts(this.firstName, this.lastName);
}
