import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/wallet_entity.dart';
import 'transaction_model.dart';

/// Wallet model for Firestore
class WalletModel {
  final String userId;
  final double balance;
  final double totalCredited;
  final double totalDebited;
  final bool isActive;
  final bool isFrozen;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<TransactionModel>? transactions;

  WalletModel({
    required this.userId,
    required this.balance,
    required this.totalCredited,
    required this.totalDebited,
    required this.isActive,
    required this.isFrozen,
    required this.createdAt,
    this.updatedAt,
    this.transactions,
  });

  factory WalletModel.fromFirestore(DocumentSnapshot doc, {QuerySnapshot? transactionsSnapshot}) {
    final data = doc.data() as Map<String, dynamic>;
    
    List<TransactionModel>? transactions;
    if (transactionsSnapshot != null) {
      transactions = transactionsSnapshot.docs
          .map((d) => TransactionModel.fromFirestore(d))
          .toList();
    }

    return WalletModel(
      userId: doc.id,
      balance: (data['balance'] ?? 0.0).toDouble(),
      totalCredited: (data['totalCredited'] ?? 0.0).toDouble(),
      totalDebited: (data['totalDebited'] ?? 0.0).toDouble(),
      isActive: data['isActive'] ?? true,
      isFrozen: data['isFrozen'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      transactions: transactions,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'balance': balance,
      'totalCredited': totalCredited,
      'totalDebited': totalDebited,
      'isActive': isActive,
      'isFrozen': isFrozen,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  WalletEntity toEntity() {
    return WalletEntity(
      userId: userId,
      balance: balance,
      totalCredited: totalCredited,
      totalDebited: totalDebited,
      transactions: transactions?.map((t) => t.toEntity()).toList() ?? [],
      isActive: isActive,
      isFrozen: isFrozen,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  WalletModel copyWith({
    double? balance,
    double? totalCredited,
    double? totalDebited,
    bool? isActive,
    bool? isFrozen,
    DateTime? updatedAt,
    List<TransactionModel>? transactions,
  }) {
    return WalletModel(
      userId: userId,
      balance: balance ?? this.balance,
      totalCredited: totalCredited ?? this.totalCredited,
      totalDebited: totalDebited ?? this.totalDebited,
      isActive: isActive ?? this.isActive,
      isFrozen: isFrozen ?? this.isFrozen,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      transactions: transactions ?? this.transactions,
    );
  }
}
