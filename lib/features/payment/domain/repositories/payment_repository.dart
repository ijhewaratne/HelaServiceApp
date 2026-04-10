import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/payment_result.dart';

/// Abstract repository for payment operations using PayHere
abstract class PaymentRepository {
  /// Process payment via PayHere
  /// 
  /// [bookingId] - The booking/job ID to associate with payment
  /// [amount] - Amount in cents (e.g., 150000 = LKR 1,500.00)
  /// [customerName] - Full name of customer
  /// [customerPhone] - Phone number (Sri Lankan format)
  /// [customerEmail] - Email address
  /// [customerAddress] - Physical address (optional)
  /// [customerCity] - City (optional, defaults to Colombo)
  /// [description] - Payment description shown to user
  Future<Either<Failure, PaymentResult>> processPayment({
    required String bookingId,
    required int amount,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    String? customerAddress,
    String? customerCity,
    String? description,
  });

  /// Check payment status by order ID
  Future<Either<Failure, PaymentStatus>> checkPaymentStatus(String orderId);

  /// Refund a payment (admin only)
  Future<Either<Failure, PaymentResult>> refundPayment({
    required String paymentId,
    int? amount,
    String? reason,
  });

  /// Get payment history for customer
  Future<Either<Failure, List<PaymentResult>>> getCustomerPaymentHistory(
    String customerId,
  );

  /// Get payment details by ID
  Future<Either<Failure, PaymentResult>> getPaymentById(String paymentId);
}
