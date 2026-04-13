import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../customer/domain/entities/address.dart';

/// Booking status enumeration
enum BookingStatus {
  draft,
  pending,
  confirmed,
  workerAssigned,
  workerEnRoute,
  workerArrived,
  inProgress,
  completed,
  cancelled,
  disputed,
}

/// Service type enumeration
enum ServiceType {
  cleaning,
  plumbing,
  electrical,
  acRepair,
  gardening,
  babysitting,
  elderlyCare,
  cooking,
  laundry,
  other,
}

/// Booking entity
/// 
/// Phase 2: Architecture Refactoring - Replaces Map<String, dynamic>
class Booking extends Equatable {
  final String id;
  final String customerId;
  final String? workerId;
  final ServiceType serviceType;
  final BookingStatus status;
  final Address address;
  final DateTime scheduledDate;
  final String? scheduledTime;
  final int? durationHours;
  final double estimatedPrice;
  final double? finalPrice;
  final String? notes;
  final String? cancellationReason;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  const Booking({
    required this.id,
    required this.customerId,
    this.workerId,
    required this.serviceType,
    this.status = BookingStatus.draft,
    required this.address,
    required this.scheduledDate,
    this.scheduledTime,
    this.durationHours,
    required this.estimatedPrice,
    this.finalPrice,
    this.notes,
    this.cancellationReason,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  /// Empty booking (for initial states)
  static final empty = Booking(
    id: '',
    customerId: '',
    serviceType: ServiceType.other,
    address: Address.empty,
    scheduledDate: DateTime(2000, 1, 1),
    estimatedPrice: 0.0,
    createdAt: DateTime(2000, 1, 1),
  );

  /// Check if booking is empty
  bool get isEmpty => id.isEmpty;

  /// Check if booking is active
  bool get isActive => status != BookingStatus.completed && 
                       status != BookingStatus.cancelled;

  /// Check if booking can be cancelled
  bool get canCancel => status == BookingStatus.pending || 
                        status == BookingStatus.confirmed ||
                        status == BookingStatus.workerAssigned;

  /// Check if worker is assigned
  bool get hasWorker => workerId != null && workerId!.isNotEmpty;

  /// Get booking duration
  Duration? get duration {
    if (startedAt == null || completedAt == null) return null;
    return completedAt!.difference(startedAt!);
  }

  /// Create a copy with updated fields
  Booking copyWith({
    String? id,
    String? customerId,
    String? workerId,
    ServiceType? serviceType,
    BookingStatus? status,
    Address? address,
    DateTime? scheduledDate,
    String? scheduledTime,
    int? durationHours,
    double? estimatedPrice,
    double? finalPrice,
    String? notes,
    String? cancellationReason,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Booking(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      workerId: workerId ?? this.workerId,
      serviceType: serviceType ?? this.serviceType,
      status: status ?? this.status,
      address: address ?? this.address,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      durationHours: durationHours ?? this.durationHours,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      finalPrice: finalPrice ?? this.finalPrice,
      notes: notes ?? this.notes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON (for Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'workerId': workerId,
      'serviceType': serviceType.name,
      'status': status.name,
      'address': address.toJson(),
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'scheduledTime': scheduledTime,
      'durationHours': durationHours,
      'estimatedPrice': estimatedPrice,
      'finalPrice': finalPrice,
      'notes': notes,
      'cancellationReason': cancellationReason,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'metadata': metadata,
    };
  }

  /// Create from Firestore document
  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking.fromJson(data, id: doc.id);
  }

  /// Create from JSON
  factory Booking.fromJson(Map<String, dynamic> json, {String? id}) {
    return Booking(
      id: id ?? json['id'] ?? '',
      customerId: json['customerId'] ?? '',
      workerId: json['workerId'],
      serviceType: _parseServiceType(json['serviceType']),
      status: _parseBookingStatus(json['status']),
      address: Address.fromJson(json['address'] ?? {}),
      scheduledDate: json['scheduledDate'] is Timestamp
          ? (json['scheduledDate'] as Timestamp).toDate()
          : DateTime.parse(json['scheduledDate'] ?? DateTime.now().toIso8601String()),
      scheduledTime: json['scheduledTime'],
      durationHours: json['durationHours'],
      estimatedPrice: (json['estimatedPrice'] ?? 0.0).toDouble(),
      finalPrice: json['finalPrice']?.toDouble(),
      notes: json['notes'],
      cancellationReason: json['cancellationReason'],
      startedAt: json['startedAt'] != null
          ? (json['startedAt'] is Timestamp
              ? (json['startedAt'] as Timestamp).toDate()
              : DateTime.parse(json['startedAt']))
          : null,
      completedAt: json['completedAt'] != null
          ? (json['completedAt'] is Timestamp
              ? (json['completedAt'] as Timestamp).toDate()
              : DateTime.parse(json['completedAt']))
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? (json['cancelledAt'] is Timestamp
              ? (json['cancelledAt'] as Timestamp).toDate()
              : DateTime.parse(json['cancelledAt']))
          : null,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is Timestamp
              ? (json['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(json['updatedAt']))
          : null,
      metadata: json['metadata'],
    );
  }

  static ServiceType _parseServiceType(String? type) {
    switch (type) {
      case 'cleaning': return ServiceType.cleaning;
      case 'plumbing': return ServiceType.plumbing;
      case 'electrical': return ServiceType.electrical;
      case 'acRepair': return ServiceType.acRepair;
      case 'gardening': return ServiceType.gardening;
      case 'babysitting': return ServiceType.babysitting;
      case 'elderlyCare': return ServiceType.elderlyCare;
      case 'cooking': return ServiceType.cooking;
      case 'laundry': return ServiceType.laundry;
      default: return ServiceType.other;
    }
  }

  static BookingStatus _parseBookingStatus(String? status) {
    switch (status) {
      case 'pending': return BookingStatus.pending;
      case 'confirmed': return BookingStatus.confirmed;
      case 'workerAssigned': return BookingStatus.workerAssigned;
      case 'workerEnRoute': return BookingStatus.workerEnRoute;
      case 'workerArrived': return BookingStatus.workerArrived;
      case 'inProgress': return BookingStatus.inProgress;
      case 'completed': return BookingStatus.completed;
      case 'cancelled': return BookingStatus.cancelled;
      case 'disputed': return BookingStatus.disputed;
      default: return BookingStatus.draft;
    }
  }

  @override
  List<Object?> get props => [
        id,
        customerId,
        workerId,
        serviceType,
        status,
        scheduledDate,
      ];

  @override
  String toString() => 'Booking($id: ${serviceType.name} on ${scheduledDate.toIso8601String()})';
}

/// Extension for Booking utilities
extension BookingX on Booking {
  /// Get formatted price
  String get formattedPrice => 'LKR ${(finalPrice ?? estimatedPrice).toStringAsFixed(2)}';
  
  /// Get formatted scheduled time
  String get formattedScheduledTime {
    final date = '${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year}';
    final time = scheduledTime ?? 'Any time';
    return '$date at $time';
  }
  
  /// Check if booking is in terminal state
  bool get isTerminal => status == BookingStatus.completed || 
                         status == BookingStatus.cancelled ||
                         status == BookingStatus.disputed;
}
