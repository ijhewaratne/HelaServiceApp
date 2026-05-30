import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../customer/domain/entities/address.dart';
import '../../../scheduling/domain/entities/booking_schedule.dart';
import '../../../scheduling/domain/entities/recurrence_rule.dart';

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

/// GPS-stamped check-in or check-out record
class CheckRecord extends Equatable {
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String? photoUrl;
  final String? notes;

  const CheckRecord({
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.photoUrl,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': Timestamp.fromDate(timestamp),
        'latitude': latitude,
        'longitude': longitude,
        'photoUrl': photoUrl,
        'notes': notes,
      };

  factory CheckRecord.fromJson(Map<String, dynamic> json) => CheckRecord(
        timestamp: (json['timestamp'] as Timestamp).toDate(),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        photoUrl: json['photoUrl'] as String?,
        notes: json['notes'] as String?,
      );

  @override
  List<Object?> get props => [timestamp, latitude, longitude];
}

/// Booking entity — extended with scheduling, recurrence, and check-in/out
class Booking extends Equatable {
  final String id;
  final String customerId;
  final String? workerId;
  final ServiceType serviceType;
  final String? serviceCatalogId; // link to ServiceCatalogItem
  final BookingStatus status;
  final Address address;
  final BookingSchedule? schedule; // null for legacy bookings
  // Legacy flat fields (kept for backwards compatibility)
  final DateTime scheduledDate;
  final String? scheduledTime;
  final int? durationHours;
  final double estimatedPrice;
  final double? finalPrice;
  final double heldAmount;      // amount locked in wallet pending completion
  final String? notes;
  final String? cancellationReason;
  // Check-in / check-out
  final CheckRecord? checkIn;
  final CheckRecord? checkOut;
  // Legacy timestamps
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
    this.serviceCatalogId,
    this.status = BookingStatus.draft,
    required this.address,
    this.schedule,
    required this.scheduledDate,
    this.scheduledTime,
    this.durationHours,
    required this.estimatedPrice,
    this.finalPrice,
    this.heldAmount = 0.0,
    this.notes,
    this.cancellationReason,
    this.checkIn,
    this.checkOut,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  static final empty = Booking(
    id: '',
    customerId: '',
    serviceType: ServiceType.other,
    address: Address.empty,
    scheduledDate: DateTime(2000, 1, 1),
    estimatedPrice: 0.0,
    createdAt: DateTime(2000, 1, 1),
  );

  bool get isEmpty => id.isEmpty;
  bool get isActive =>
      status != BookingStatus.completed && status != BookingStatus.cancelled;
  bool get canCancel =>
      status == BookingStatus.pending ||
      status == BookingStatus.confirmed ||
      status == BookingStatus.workerAssigned;
  bool get hasWorker => workerId != null && workerId!.isNotEmpty;
  bool get isCheckedIn => checkIn != null;
  bool get isCheckedOut => checkOut != null;
  bool get isRecurring => schedule?.isRecurring ?? false;

  Duration? get duration {
    if (checkIn != null && checkOut != null) {
      return checkOut!.timestamp.difference(checkIn!.timestamp);
    }
    if (startedAt != null && completedAt != null) {
      return completedAt!.difference(startedAt!);
    }
    return null;
  }

  Booking copyWith({
    String? id,
    String? customerId,
    String? workerId,
    ServiceType? serviceType,
    String? serviceCatalogId,
    BookingStatus? status,
    Address? address,
    BookingSchedule? schedule,
    DateTime? scheduledDate,
    String? scheduledTime,
    int? durationHours,
    double? estimatedPrice,
    double? finalPrice,
    double? heldAmount,
    String? notes,
    String? cancellationReason,
    CheckRecord? checkIn,
    CheckRecord? checkOut,
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
      serviceCatalogId: serviceCatalogId ?? this.serviceCatalogId,
      status: status ?? this.status,
      address: address ?? this.address,
      schedule: schedule ?? this.schedule,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      durationHours: durationHours ?? this.durationHours,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      finalPrice: finalPrice ?? this.finalPrice,
      heldAmount: heldAmount ?? this.heldAmount,
      notes: notes ?? this.notes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'workerId': workerId,
      'serviceType': serviceType.name,
      'serviceCatalogId': serviceCatalogId,
      'status': status.name,
      'address': address.toJson(),
      'schedule': schedule?.toJson(),
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'scheduledTime': scheduledTime,
      'durationHours': durationHours,
      'estimatedPrice': estimatedPrice,
      'finalPrice': finalPrice,
      'heldAmount': heldAmount,
      'notes': notes,
      'cancellationReason': cancellationReason,
      'checkIn': checkIn?.toJson(),
      'checkOut': checkOut?.toJson(),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'cancelledAt':
          cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'metadata': metadata,
    };
  }

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking.fromJson(data, id: doc.id);
  }

  factory Booking.fromJson(Map<String, dynamic> json, {String? id}) {
    return Booking(
      id: id ?? json['id'] as String? ?? '',
      customerId: json['customerId'] as String? ?? '',
      workerId: json['workerId'] as String?,
      serviceType: _parseServiceType(json['serviceType'] as String?),
      serviceCatalogId: json['serviceCatalogId'] as String?,
      status: _parseBookingStatus(json['status'] as String?),
      address:
          Address.fromJson(json['address'] as Map<String, dynamic>? ?? {}),
      schedule: json['schedule'] != null
          ? BookingSchedule.fromJson(
              json['schedule'] as Map<String, dynamic>)
          : null,
      scheduledDate: json['scheduledDate'] is Timestamp
          ? (json['scheduledDate'] as Timestamp).toDate()
          : DateTime.parse(
              json['scheduledDate'] as String? ??
                  DateTime.now().toIso8601String()),
      scheduledTime: json['scheduledTime'] as String?,
      durationHours: json['durationHours'] as int?,
      estimatedPrice:
          (json['estimatedPrice'] as num?)?.toDouble() ?? 0.0,
      finalPrice: (json['finalPrice'] as num?)?.toDouble(),
      heldAmount: (json['heldAmount'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
      checkIn: json['checkIn'] != null
          ? CheckRecord.fromJson(json['checkIn'] as Map<String, dynamic>)
          : null,
      checkOut: json['checkOut'] != null
          ? CheckRecord.fromJson(json['checkOut'] as Map<String, dynamic>)
          : null,
      startedAt: _parseTimestamp(json['startedAt']),
      completedAt: _parseTimestamp(json['completedAt']),
      cancelledAt: _parseTimestamp(json['cancelledAt']),
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(
              json['createdAt'] as String? ??
                  DateTime.now().toIso8601String()),
      updatedAt: _parseTimestamp(json['updatedAt']),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return null;
  }

  static ServiceType _parseServiceType(String? type) {
    switch (type) {
      case 'cleaning':   return ServiceType.cleaning;
      case 'plumbing':   return ServiceType.plumbing;
      case 'electrical': return ServiceType.electrical;
      case 'acRepair':   return ServiceType.acRepair;
      case 'gardening':  return ServiceType.gardening;
      case 'babysitting':return ServiceType.babysitting;
      case 'elderlyCare':return ServiceType.elderlyCare;
      case 'cooking':    return ServiceType.cooking;
      case 'laundry':    return ServiceType.laundry;
      default:           return ServiceType.other;
    }
  }

  static BookingStatus _parseBookingStatus(String? status) {
    switch (status) {
      case 'pending':        return BookingStatus.pending;
      case 'confirmed':      return BookingStatus.confirmed;
      case 'workerAssigned': return BookingStatus.workerAssigned;
      case 'workerEnRoute':  return BookingStatus.workerEnRoute;
      case 'workerArrived':  return BookingStatus.workerArrived;
      case 'inProgress':     return BookingStatus.inProgress;
      case 'completed':      return BookingStatus.completed;
      case 'cancelled':      return BookingStatus.cancelled;
      case 'disputed':       return BookingStatus.disputed;
      default:               return BookingStatus.draft;
    }
  }

  @override
  List<Object?> get props =>
      [id, customerId, workerId, serviceType, status, scheduledDate];

  @override
  String toString() =>
      'Booking($id: ${serviceType.name} on ${scheduledDate.toIso8601String()})';
}

extension BookingX on Booking {
  String get formattedPrice =>
      'LKR ${(finalPrice ?? estimatedPrice).toStringAsFixed(2)}';

  String get formattedScheduledTime {
    if (schedule != null) return schedule!.displayLabel;
    final date =
        '${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year}';
    final time = scheduledTime ?? 'Any time';
    return '$date at $time';
  }

  bool get isTerminal =>
      status == BookingStatus.completed ||
      status == BookingStatus.cancelled ||
      status == BookingStatus.disputed;

  /// Effective duration in hours for billing
  double get billableHours {
    final d = duration;
    if (d != null) return d.inMinutes / 60.0;
    return (durationHours ?? schedule?.durationHours ?? 0).toDouble();
  }
}
