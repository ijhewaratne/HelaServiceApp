import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  })  : _paymentRepository = paymentRepository,
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

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      emit(const PaymentError(message: 'User not authenticated'));
      return;
    }

    // Get user details for payment
    final customerName = event.customerName ?? user.displayName ?? 'HelaService Customer';
    final customerPhone = event.customerPhone ?? user.phoneNumber ?? '';
    final customerEmail = event.customerEmail ?? user.email ?? '${user.uid}@helaservice.lk';

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

    result.fold(
      (failure) {
        // Track payment failure
        _analytics.logPaymentFailed(
          bookingId: event.bookingId,
          amount: event.amount / 100, // Convert cents to rupees
          reason: failure.message,
        );
        emit(PaymentError(message: failure.message));
      },
      (paymentResult) async {
        if (paymentResult.success) {
          // Track successful payment
          await _analytics.logPaymentSuccess(
            paymentId: paymentResult.paymentId ?? 'unknown',
            bookingId: event.bookingId,
            amount: event.amount / 100, // Convert cents to rupees
            method: paymentResult.paymentMethod ?? 'unknown',
          );
          emit(PaymentSuccess(payment: paymentResult));
        } else {
          // Track payment failure
          await _analytics.logPaymentFailed(
            bookingId: event.bookingId,
            amount: event.amount / 100,
            reason: paymentResult.message ?? 'Payment failed',
            errorCode: paymentResult.status.toString(),
          );
          emit(PaymentFailed(
            message: paymentResult.message ?? 'Payment failed',
            status: paymentResult.status,
          ));
        }
      },
    );
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

  RequestRefund({
    required this.paymentId,
    this.amount,
    this.reason,
  });

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

  PaymentFailed({
    required this.message,
    required this.status,
  });

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
