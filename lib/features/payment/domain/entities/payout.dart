import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum PayoutStatus { pending, processing, completed, failed }

/// A payout record representing platform → worker transfer
class Payout extends Equatable {
  final String id;
  final String workerId;
  final double grossAmount; // total collected from customers
  final double platformFee; // 20% platform cut
  final double workerAmount; // 80% sent to worker
  final PayoutStatus status;
  final String? failureReason;
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<String> bookingIds; // bookings included in this payout
  final DateTime createdAt;
  final DateTime? processedAt;

  const Payout({
    required this.id,
    required this.workerId,
    required this.grossAmount,
    required this.platformFee,
    required this.workerAmount,
    this.status = PayoutStatus.pending,
    this.failureReason,
    required this.periodStart,
    required this.periodEnd,
    this.bookingIds = const [],
    required this.createdAt,
    this.processedAt,
  });

  static const double platformFeeRate = 0.20; // 20%
  static const double workerShareRate = 0.80; // 80%

  factory Payout.calculate({
    required String id,
    required String workerId,
    required double grossAmount,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<String> bookingIds,
  }) {
    final fee = grossAmount * platformFeeRate;
    return Payout(
      id: id,
      workerId: workerId,
      grossAmount: grossAmount,
      platformFee: fee,
      workerAmount: grossAmount - fee,
      periodStart: periodStart,
      periodEnd: periodEnd,
      bookingIds: bookingIds,
      createdAt: DateTime.now(),
    );
  }

  Payout copyWith({
    PayoutStatus? status,
    String? failureReason,
    DateTime? processedAt,
  }) => Payout(
    id: id,
    workerId: workerId,
    grossAmount: grossAmount,
    platformFee: platformFee,
    workerAmount: workerAmount,
    status: status ?? this.status,
    failureReason: failureReason ?? this.failureReason,
    periodStart: periodStart,
    periodEnd: periodEnd,
    bookingIds: bookingIds,
    createdAt: createdAt,
    processedAt: processedAt ?? this.processedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'workerId': workerId,
    'grossAmount': grossAmount,
    'platformFee': platformFee,
    'workerAmount': workerAmount,
    'status': status.name,
    'failureReason': failureReason,
    'periodStart': Timestamp.fromDate(periodStart),
    'periodEnd': Timestamp.fromDate(periodEnd),
    'bookingIds': bookingIds,
    'createdAt': Timestamp.fromDate(createdAt),
    'processedAt': processedAt != null
        ? Timestamp.fromDate(processedAt!)
        : null,
  };

  factory Payout.fromJson(Map<String, dynamic> json) => Payout(
    id: json['id'] as String? ?? '',
    workerId: json['workerId'] as String? ?? '',
    grossAmount: (json['grossAmount'] as num?)?.toDouble() ?? 0.0,
    platformFee: (json['platformFee'] as num?)?.toDouble() ?? 0.0,
    workerAmount: (json['workerAmount'] as num?)?.toDouble() ?? 0.0,
    status: PayoutStatus.values.firstWhere(
      (e) => e.name == (json['status'] as String?),
      orElse: () => PayoutStatus.pending,
    ),
    failureReason: json['failureReason'] as String?,
    periodStart: (json['periodStart'] as Timestamp).toDate(),
    periodEnd: (json['periodEnd'] as Timestamp).toDate(),
    bookingIds:
        (json['bookingIds'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
    createdAt: (json['createdAt'] as Timestamp).toDate(),
    processedAt: json['processedAt'] != null
        ? (json['processedAt'] as Timestamp).toDate()
        : null,
  );

  factory Payout.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Payout.fromJson({...data, 'id': doc.id});
  }

  @override
  List<Object?> get props => [id, workerId, grossAmount, status];
}
