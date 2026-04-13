import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/wallet_entity.dart';

/// Transaction model for Firestore
class TransactionModel {
  final String id;
  final String userId;
  final String type;
  final double amount;
  final double balanceAfter;
  final String? description;
  final String? relatedBookingId;
  final String? paymentMethod;
  final String status;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.description,
    this.relatedBookingId,
    this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.metadata,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? 'topUp',
      amount: (data['amount'] ?? 0.0).toDouble(),
      balanceAfter: (data['balanceAfter'] ?? 0.0).toDouble(),
      description: data['description'],
      relatedBookingId: data['relatedBookingId'],
      paymentMethod: data['paymentMethod'],
      status: data['status'] ?? 'completed',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
      'amount': amount,
      'balanceAfter': balanceAfter,
      'description': description,
      'relatedBookingId': relatedBookingId,
      'paymentMethod': paymentMethod,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
    };
  }

  TransactionEntity toEntity() {
    return TransactionEntity(
      id: id,
      userId: userId,
      type: _parseTransactionType(type),
      amount: amount,
      balanceAfter: balanceAfter,
      description: description,
      relatedBookingId: relatedBookingId,
      paymentMethod: paymentMethod,
      status: _parseTransactionStatus(status),
      createdAt: createdAt,
      metadata: metadata,
    );
  }

  static TransactionType _parseTransactionType(String type) {
    switch (type) {
      case 'topUp':
        return TransactionType.topUp;
      case 'payment':
        return TransactionType.payment;
      case 'refund':
        return TransactionType.refund;
      case 'referralReward':
        return TransactionType.referralReward;
      case 'promoCredit':
        return TransactionType.promoCredit;
      case 'withdrawal':
        return TransactionType.withdrawal;
      default:
        return TransactionType.topUp;
    }
  }

  static TransactionStatus _parseTransactionStatus(String status) {
    switch (status) {
      case 'pending':
        return TransactionStatus.pending;
      case 'completed':
        return TransactionStatus.completed;
      case 'failed':
        return TransactionStatus.failed;
      case 'cancelled':
        return TransactionStatus.cancelled;
      default:
        return TransactionStatus.completed;
    }
  }

  static String transactionTypeToString(TransactionType type) {
    return type.name;
  }

  static String transactionStatusToString(TransactionStatus status) {
    return status.name;
  }
}
