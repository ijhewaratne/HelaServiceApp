import 'package:equatable/equatable.dart';

/// Result of a payment operation
class PaymentResult extends Equatable {
  final bool success;
  final String? paymentId;
  final String? orderId;
  final String? message;
  final PaymentStatus status;
  final double? amount;
  final String? currency;
  final DateTime? processedAt;

  const PaymentResult({
    required this.success,
    this.paymentId,
    this.orderId,
    this.message,
    this.status = PaymentStatus.unknown,
    this.amount,
    this.currency,
    this.processedAt,
  });

  /// Create from PayHere success response
  factory PaymentResult.success({
    required String paymentId,
    required String orderId,
    double? amount,
    String? currency,
  }) {
    return PaymentResult(
      success: true,
      paymentId: paymentId,
      orderId: orderId,
      status: PaymentStatus.completed,
      amount: amount,
      currency: currency ?? 'LKR',
      processedAt: DateTime.now(),
    );
  }

  /// Create from PayHere failure response
  factory PaymentResult.failure({
    required String message,
    String? orderId,
    PaymentStatus status = PaymentStatus.failed,
  }) {
    return PaymentResult(
      success: false,
      orderId: orderId,
      message: message,
      status: status,
      processedAt: DateTime.now(),
    );
  }

  PaymentResult copyWith({
    bool? success,
    String? paymentId,
    String? orderId,
    String? message,
    PaymentStatus? status,
    double? amount,
    String? currency,
    DateTime? processedAt,
  }) {
    return PaymentResult(
      success: success ?? this.success,
      paymentId: paymentId ?? this.paymentId,
      orderId: orderId ?? this.orderId,
      message: message ?? this.message,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      processedAt: processedAt ?? this.processedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'paymentId': paymentId,
      'orderId': orderId,
      'message': message,
      'status': status.name,
      'amount': amount,
      'currency': currency,
      'processedAt': processedAt?.toIso8601String(),
    };
  }

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      success: json['success'] ?? false,
      paymentId: json['paymentId'],
      orderId: json['orderId'],
      message: json['message'],
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.unknown,
      ),
      amount: json['amount']?.toDouble(),
      currency: json['currency'],
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'])
          : null,
    );
  }

  @override
  List<Object?> get props => [
        success,
        paymentId,
        orderId,
        message,
        status,
        amount,
        currency,
        processedAt,
      ];
}

/// Payment status enumeration
enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
  unknown,
}

/// Extension for PaymentStatus display
extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.unknown:
        return 'Unknown';
    }
  }

  bool get isSuccessful => this == PaymentStatus.completed;
  bool get isTerminal =>
      this == PaymentStatus.completed ||
      this == PaymentStatus.failed ||
      this == PaymentStatus.cancelled ||
      this == PaymentStatus.refunded;
}
