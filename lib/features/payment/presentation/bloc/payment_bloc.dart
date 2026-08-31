import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../../../core/services/analytics_service.dart';
import '../../domain/entities/payment_result.dart';
import '../../domain/repositories/payment_repository.dart';

/// BLoC for managing payment operations
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository _paymentRepository;
  final AnalyticsService _analytics;

  PaymentBloc({
    required PaymentRepository paymentRepository,
    AnalyticsService? analytics,
  }) : _paymentRepository = paymentRepository,
       _analytics = analytics ?? AnalyticsService(),
       super(PaymentInitial()) {
    on<ProcessPayment>(_onProcessPayment);
    on<CheckPaymentStatus>(_onCheckPaymentStatus);
    on<LoadPaymentHistory>(_onLoadPaymentHistory);
    on<RequestRefund>(_onRequestRefund);
  }

  Future<void> _onProcessPayment(
    ProcessPayment event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentProcessing());

    firebase_auth.User? currentUser;
    try {
      currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    } catch (_) {
      // FirebaseAuth not initialized (e.g., in tests) — use event fields directly.
    }

    // Get user details for payment, falling back to Firebase user fields.
    final customerName =
        event.customerName ??
        currentUser?.displayName ??
        'HelaService Customer';
    final customerPhone = event.customerPhone ?? currentUser?.phoneNumber ?? '';
    final customerEmail = event.customerEmail ?? currentUser?.email ?? '';

    final result = await _paymentRepository.processPayment(
      bookingId: event.bookingId,
      amount: event.amount,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      customerAddress: event.customerAddress,
      customerCity: event.customerCity,
      description: event.description,
    );

    if (result.isLeft()) {
      final failure = result.fold((l) => l, (_) => throw StateError(''));
      await _analytics.logPaymentFailed(
        bookingId: event.bookingId,
        amount: event.amount / 100,
        reason: failure.message,
      );
      emit(PaymentError(message: failure.message));
      return;
    }

    final paymentResult = result.getOrElse(() => throw StateError(''));

    if (paymentResult.success) {
      if (paymentResult.status == PaymentStatus.pending &&
          paymentResult.checkoutUrl != null) {
        emit(
          PaymentInitiated(
            checkoutUrl: paymentResult.checkoutUrl!,
            orderId: paymentResult.orderId ?? event.bookingId,
          ),
        );
      } else {
        await _analytics.logPaymentSuccess(
          paymentId: paymentResult.paymentId ?? 'unknown',
          bookingId: event.bookingId,
          amount: event.amount / 100,
          method: paymentResult.currency ?? 'unknown',
        );
        if (!emit.isDone) emit(PaymentSuccess(payment: paymentResult));
      }
    } else {
      await _analytics.logPaymentFailed(
        bookingId: event.bookingId,
        amount: event.amount / 100,
        reason: paymentResult.message ?? 'Payment failed',
        errorCode: paymentResult.status.toString(),
      );
      if (!emit.isDone) {
        emit(
          PaymentFailed(
            message: paymentResult.message ?? 'Payment failed',
            status: paymentResult.status,
          ),
        );
      }
    }
  }

  Future<void> _onCheckPaymentStatus(
    CheckPaymentStatus event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());

    final result = await _paymentRepository.checkPaymentStatus(event.orderId);

    result.fold(
      (failure) => emit(PaymentError(message: failure.message)),
      (status) => emit(PaymentStatusChecked(status: status)),
    );
  }

  Future<void> _onLoadPaymentHistory(
    LoadPaymentHistory event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());

    final result = await _paymentRepository.getCustomerPaymentHistory(
      event.customerId,
    );

    result.fold(
      (failure) => emit(PaymentError(message: failure.message)),
      (payments) => emit(PaymentHistoryLoaded(payments: payments)),
    );
  }

  Future<void> _onRequestRefund(
    RequestRefund event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentProcessing());

    final result = await _paymentRepository.refundPayment(
      paymentId: event.paymentId,
      amount: event.amount,
      reason: event.reason,
    );

    result.fold(
      (failure) {
        _analytics.logError(
          error: 'Refund failed: ${failure.message}',
          context: 'payment_bloc',
        );
        emit(PaymentError(message: failure.message));
      },
      (refundResult) {
        emit(RefundProcessed(refund: refundResult));
      },
    );
  }
}

// ==================== EVENTS ====================

abstract class PaymentEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Initiate payment processing
class ProcessPayment extends PaymentEvent {
  final String bookingId;
  final int amount; // Amount in cents (e.g., 150000 = LKR 1,500.00)
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String? customerAddress;
  final String? customerCity;
  final String? description;

  ProcessPayment({
    required this.bookingId,
    required this.amount,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.customerAddress,
    this.customerCity,
    this.description,
  });

  @override
  List<Object?> get props => [
    bookingId,
    amount,
    customerName,
    customerPhone,
    customerEmail,
    customerAddress,
    customerCity,
    description,
  ];
}

/// Check status of a payment
class CheckPaymentStatus extends PaymentEvent {
  final String orderId;

  CheckPaymentStatus({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}

/// Load payment history for customer
class LoadPaymentHistory extends PaymentEvent {
  final String customerId;

  LoadPaymentHistory({required this.customerId});

  @override
  List<Object?> get props => [customerId];
}

/// Request a refund
class RequestRefund extends PaymentEvent {
  final String paymentId;
  final int? amount;
  final String? reason;

  RequestRefund({required this.paymentId, this.amount, this.reason});

  @override
  List<Object?> get props => [paymentId, amount, reason];
}

// ==================== STATES ====================

abstract class PaymentState extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Initial state
class PaymentInitial extends PaymentState {}

/// Loading state
class PaymentLoading extends PaymentState {}

/// Payment is being processed (PayHere UI shown)
class PaymentProcessing extends PaymentState {}

/// Payment initiated — checkout URL generated, awaiting PayHere webhook.
/// The UI should launch [checkoutUrl] and then poll for status.
class PaymentInitiated extends PaymentState {
  final String checkoutUrl;
  final String orderId;

  PaymentInitiated({required this.checkoutUrl, required this.orderId});

  @override
  List<Object?> get props => [checkoutUrl, orderId];
}

/// Payment completed successfully
class PaymentSuccess extends PaymentState {
  final PaymentResult payment;

  PaymentSuccess({required this.payment});

  @override
  List<Object?> get props => [payment];
}

/// Payment failed
class PaymentFailed extends PaymentState {
  final String message;
  final PaymentStatus status;

  PaymentFailed({required this.message, required this.status});

  @override
  List<Object?> get props => [message, status];
}

/// Payment status checked
class PaymentStatusChecked extends PaymentState {
  final PaymentStatus status;

  PaymentStatusChecked({required this.status});

  @override
  List<Object?> get props => [status];
}

/// Payment history loaded
class PaymentHistoryLoaded extends PaymentState {
  final List<PaymentResult> payments;

  PaymentHistoryLoaded({required this.payments});

  @override
  List<Object?> get props => [payments];
}

/// Refund processed
class RefundProcessed extends PaymentState {
  final PaymentResult refund;

  RefundProcessed({required this.refund});

  @override
  List<Object?> get props => [refund];
}

/// Error state
class PaymentError extends PaymentState {
  final String message;

  PaymentError({required this.message});

  @override
  List<Object?> get props => [message];
}
