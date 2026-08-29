import 'package:equatable/equatable.dart';

/// Transaction types
enum TransactionType {
  topUp,
  payment,
  refund,
  referralReward,
  promoCredit,
  withdrawal,
}

/// Transaction status
enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled,
}

/// Transaction entity
///
/// [amount] and [balanceAfter] are integer minor units (cents), matching
/// [WalletEntity.balance]. Use [formattedAmount] for LKR display.
class TransactionEntity extends Equatable {
  final String id;
  final String userId;
  final TransactionType type;
  final int amount;
  final int balanceAfter;
  final String? description;
  final String? relatedBookingId;
  final String? paymentMethod;
  final TransactionStatus status;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const TransactionEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.description,
    this.relatedBookingId,
    this.paymentMethod,
    this.status = TransactionStatus.completed,
    required this.createdAt,
    this.metadata,
  });

  /// Empty transaction
  static final empty = TransactionEntity(
    id: '',
    userId: '',
    type: TransactionType.topUp,
    amount: 0,
    balanceAfter: 0,
    createdAt: DateTime(2000, 1, 1),
  );

  bool get isEmpty => id.isEmpty;

  /// Get formatted amount with sign (LKR, converted from cents)
  String get formattedAmount {
    final sign = _isCredit ? '+' : '-';
    return '$sign LKR ${(amount.abs() / 100).toStringAsFixed(2)}';
  }

  /// Get display icon based on transaction type
  String get icon {
    switch (type) {
      case TransactionType.topUp:
        return '💰';
      case TransactionType.payment:
        return '💳';
      case TransactionType.refund:
        return '↩️';
      case TransactionType.referralReward:
        return '🎁';
      case TransactionType.promoCredit:
        return '🎉';
      case TransactionType.withdrawal:
        return '🏧';
    }
  }

  bool get _isCredit =>
      type == TransactionType.topUp ||
      type == TransactionType.refund ||
      type == TransactionType.referralReward ||
      type == TransactionType.promoCredit;

  TransactionEntity copyWith({
    String? id,
    String? userId,
    TransactionType? type,
    int? amount,
    int? balanceAfter,
    String? description,
    String? relatedBookingId,
    String? paymentMethod,
    TransactionStatus? status,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      description: description ?? this.description,
      relatedBookingId: relatedBookingId ?? this.relatedBookingId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        amount,
        status,
        createdAt,
      ];
}

/// Wallet entity
///
/// Phase 7: Business Features - In-App Wallet
///
/// [balance], [heldBalance], [totalCredited], and [totalDebited] are integer
/// minor units (cents) to avoid floating-point drift across many
/// FieldValue.increment() writes. There is no separately-stored
/// "availableBalance" field anywhere (client or server) — it is always
/// derived as [availableBalance] below, so it can never disagree with
/// balance/heldBalance.
class WalletEntity extends Equatable {
  final String userId;
  final int balance;
  final int heldBalance; // funds locked pending booking completion
  final int totalCredited;
  final int totalDebited;
  final List<TransactionEntity> transactions;
  final bool isActive;
  final bool isFrozen;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const WalletEntity({
    required this.userId,
    this.balance = 0,
    this.heldBalance = 0,
    this.totalCredited = 0,
    this.totalDebited = 0,
    this.transactions = const [],
    this.isActive = true,
    this.isFrozen = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// Empty wallet
  static final empty = WalletEntity(
    userId: '',
    createdAt: DateTime(2000, 1, 1),
  );

  bool get isEmpty => userId.isEmpty;

  /// Check if wallet has sufficient balance (cents)
  int get availableBalance => balance - heldBalance;

  /// [availableBalance] converted to LKR, for display/comparison against
  /// other LKR-denominated values (e.g. booking prices).
  double get availableBalanceLKR => availableBalance / 100;

  bool hasSufficientBalance(int amountCents) =>
      availableBalance >= amountCents && !isFrozen;

  /// Get formatted balance (LKR, converted from cents)
  String get formattedBalance => 'LKR ${(balance / 100).toStringAsFixed(2)}';

  /// Get formatted total credited (LKR, converted from cents)
  String get formattedTotalCredited =>
      'LKR ${(totalCredited / 100).toStringAsFixed(2)}';

  /// Get formatted total debited (LKR, converted from cents)
  String get formattedTotalDebited =>
      'LKR ${(totalDebited / 100).toStringAsFixed(2)}';

  /// Get recent transactions (last 10)
  List<TransactionEntity> get recentTransactions =>
      transactions.take(10).toList();

  /// Get transactions for a specific period
  List<TransactionEntity> getTransactionsForPeriod(
    DateTime start,
    DateTime end,
  ) {
    return transactions
        .where((t) => t.createdAt.isAfter(start) && t.createdAt.isBefore(end))
        .toList();
  }

  /// Get total credits for a period (cents)
  int getTotalCreditsForPeriod(DateTime start, DateTime end) {
    return getTransactionsForPeriod(start, end)
        .where((t) =>
            t.type == TransactionType.topUp ||
            t.type == TransactionType.refund ||
            t.type == TransactionType.referralReward ||
            t.type == TransactionType.promoCredit)
        .fold(0, (sum, t) => sum + t.amount);
  }

  /// Get total debits for a period (cents)
  int getTotalDebitsForPeriod(DateTime start, DateTime end) {
    return getTransactionsForPeriod(start, end)
        .where((t) =>
            t.type == TransactionType.payment ||
            t.type == TransactionType.withdrawal)
        .fold(0, (sum, t) => sum + t.amount.abs());
  }

  WalletEntity copyWith({
    String? userId,
    int? balance,
    int? heldBalance,
    int? totalCredited,
    int? totalDebited,
    List<TransactionEntity>? transactions,
    bool? isActive,
    bool? isFrozen,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WalletEntity(
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      heldBalance: heldBalance ?? this.heldBalance,
      totalCredited: totalCredited ?? this.totalCredited,
      totalDebited: totalDebited ?? this.totalDebited,
      transactions: transactions ?? this.transactions,
      isActive: isActive ?? this.isActive,
      isFrozen: isFrozen ?? this.isFrozen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        balance,
        heldBalance,
        isActive,
        isFrozen,
      ];
}

/// Extension for wallet operations
extension WalletEntityX on WalletEntity {
  /// Check if wallet can perform a transaction (amount in cents)
  bool canPerformTransaction(int amount, {bool allowNegative = false}) {
    if (!isActive || isFrozen) return false;
    if (amount <= 0) return true;
    return allowNegative || balance >= amount;
  }
}
