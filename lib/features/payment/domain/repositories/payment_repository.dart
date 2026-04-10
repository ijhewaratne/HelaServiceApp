import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';

/// Abstract repository for payment operations
abstract class PaymentRepository {
  /// Process payment for a booking
  Future<Either<Failure, Map<String, dynamic>>> processPayment({
    required String bookingId,
    required double amount,
    required String currency,
    required String paymentMethod,
    Map<String, dynamic>? additionalData,
  });
  
  /// Get payment status
  Future<Either<Failure, Map<String, dynamic>>> getPaymentStatus(String paymentId);
  
  /// Refund payment
  Future<Either<Failure, Map<String, dynamic>>> refundPayment({
    required String paymentId,
    double? amount,
    String? reason,
  });
  
  /// Get payment history for customer
  Future<Either<Failure, List<Map<String, dynamic>>>> getCustomerPaymentHistory(
    String customerId,
  );
  
  /// Save payment method for customer
  Future<Either<Failure, Map<String, dynamic>>> savePaymentMethod({
    required String customerId,
    required Map<String, dynamic> paymentMethod,
  });
  
  /// Get saved payment methods
  Future<Either<Failure, List<Map<String, dynamic>>>> getSavedPaymentMethods(
    String customerId,
  );
  
  /// Delete saved payment method
  Future<Either<Failure, void>> deletePaymentMethod({
    required String customerId,
    required String paymentMethodId,
  });
}
