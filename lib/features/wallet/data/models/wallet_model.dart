import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/wallet_entity.dart';
import 'transaction_model.dart';

/// Wallet model for Firestore.
///
/// balance/heldBalance/totalCredited/totalDebited are stored as integer
/// cents. There is no stored "availableBalance" field — every writer
/// (client and Cloud Functions) derives it as balance - heldBalance, so it
/// can never disagree with the two source fields.
class WalletModel {
  final String userId;
  final int balance;
  final int heldBalance;
  final int totalCredited;
  final int totalDebited;
  final bool isActive;
  final bool isFrozen;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<TransactionModel>? transactions;

  WalletModel({
    required this.userId,
    required this.balance,
    this.heldBalance = 0,
    required this.totalCredited,
    required this.totalDebited,
    required this.isActive,
    required this.isFrozen,
    required this.createdAt,
    this.updatedAt,
    this.transactions,
  });

  factory WalletModel.fromFirestore(
    DocumentSnapshot doc, {
    QuerySnapshot? transactionsSnapshot,
  }) {
    final data = doc.data() as Map<String, dynamic>;

    List<TransactionModel>? transactions;
    if (transactionsSnapshot != null) {
      transactions = transactionsSnapshot.docs
          .map((d) => TransactionModel.fromFirestore(d))
          .toList();
    }

    return WalletModel(
      userId: doc.id,
      balance: (data['balance'] as num?)?.toInt() ?? 0,
      heldBalance: (data['heldBalance'] as num?)?.toInt() ?? 0,
      totalCredited: (data['totalCredited'] as num?)?.toInt() ?? 0,
      totalDebited: (data['totalDebited'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      isFrozen: data['isFrozen'] as bool? ?? false,
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
      'heldBalance': heldBalance,
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
      heldBalance: heldBalance,
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
    int? balance,
    int? heldBalance,
    int? totalCredited,
    int? totalDebited,
    bool? isActive,
    bool? isFrozen,
    DateTime? updatedAt,
    List<TransactionModel>? transactions,
  }) {
    return WalletModel(
      userId: userId,
      balance: balance ?? this.balance,
      heldBalance: heldBalance ?? this.heldBalance,
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
