import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/payment_result.dart';
import '../../domain/repositories/payment_repository.dart';

/// PayHere payment repository implementation
/// 
/// Phase 3: Essential Features - Complete Payment Integration
/// 
/// Note: This is a stub implementation since flutter_payhere package
/// is not available. In production, integrate with actual PayHere SDK.
class PayHereRepository implements PaymentRepository {
  final FirebaseFirestore _firestore;
  final bool _sandbox;
  final String _merchantId;
  final String _merchantSecret;
  final String _notifyUrl;

  PayHereRepository(
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

      // Build PayHere payment object
      final paymentObject = {
        'sandbox': _sandbox,
        'merchant_id': _merchantId,
        'merchant_secret': _merchantSecret,
        'notify_url': _notifyUrl,
        'order_id': 'ORDER_${DateTime.now().millisecondsSinceEpoch}_$bookingId',
        'items': description ?? 'HelaService Booking',
        'amount': (amount / 100.0).toStringAsFixed(2), // Convert cents to rupees
        'currency': 'LKR',
        'first_name': _parseFirstName(customerName),
        'last_name': _parseLastName(customerName),
        'email': customerEmail,
        'phone': customerPhone,
        'address': customerAddress ?? 'Sri Lanka',
        'city': customerCity ?? 'Colombo',
        'country': 'Sri Lanka',
        'delivery_address': customerAddress ?? 'Sri Lanka',
        'delivery_city': customerCity ?? 'Colombo',
        'delivery_country': 'Sri Lanka',
        'custom_1': bookingId,
        'custom_2': customerPhone,
      };

      // TODO: Integrate with actual PayHere SDK
      // This is a stub implementation for development
      // In production, use:
      // PayHere.startPayment(paymentObject, onSuccess, onError);

      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 2));

      // Create payment result
      final paymentResult = PaymentResult.success(
        paymentId: 'PAY_${DateTime.now().millisecondsSinceEpoch}',
        orderId: bookingId,
        amount: amount / 100.0,
        currency: 'LKR',
      );

      // Save payment to Firestore
      await _savePaymentToFirestore(paymentResult, bookingId);

      return Right(paymentResult);
    } on PaymentFailure catch (e) {
      return Left(e);
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
      final statusString = data['status'] as String?;
      
      return Right(_parsePaymentStatus(statusString));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Save payment result to Firestore
  Future<void> _savePaymentToFirestore(
    PaymentResult result,
    String bookingId,
  ) async {
    await _firestore.collection('payments').add({
      'paymentId': result.paymentId,
      'orderId': bookingId,
      'amount': result.amount,
      'currency': result.currency,
      'status': result.status.name,
      'success': result.success,
      'message': result.message,
      'processedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Parse first name from full name
  String _parseFirstName(String fullName) {
    final parts = fullName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : fullName;
  }

  /// Parse last name from full name
  String _parseLastName(String fullName) {
    final parts = fullName.trim().split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }

  /// Parse payment status from string
  PaymentStatus _parsePaymentStatus(String? status) {
    switch (status) {
      case 'pending':
        return PaymentStatus.pending;
      case 'processing':
        return PaymentStatus.processing;
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      case 'cancelled':
        return PaymentStatus.cancelled;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.unknown;
    }
  }

  /// Generate MD5 hash for PayHere signature verification
  /// 
  /// Format: md5(merchant_id + order_id + amount + currency + merchant_secret)
  String _generateSignature({
    required String orderId,
    required double amount,
    required String currency,
  }) {
    // TODO: Implement MD5 hash generation
    // return md5('$_merchantId$orderId$amount$currency$_merchantSecret');
    return 'signature_stub';
  }

  /// Verify PayHere notification
  /// 
  /// Called by the webhook handler to verify payment notifications
  bool verifyNotification(Map<String, dynamic> notificationData) {
    final receivedSignature = notificationData['signature'] as String?;
    final orderId = notificationData['order_id'] as String? ?? '';
    final amount = (notificationData['amount'] as num?)?.toDouble() ?? 0.0;
    final currency = notificationData['currency'] as String? ?? 'LKR';

    final expectedSignature = _generateSignature(
      orderId: orderId,
      amount: amount,
      currency: currency,
    );

    return receivedSignature == expectedSignature;
  }
}
