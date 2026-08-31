import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum AlertType {
  missedCheckIn, // worker didn't check in within grace period
  missedCheckOut, // worker didn't check out after expected end
  sosPanic, // worker triggered SOS button
  customerReport, // customer raised a safety concern mid-booking
  locationLost, // tracking went offline during active booking
}

enum AlertSeverity { low, medium, high, critical }

enum AlertStatus { open, acknowledged, resolved, escalated }

class SafetyAlert extends Equatable {
  final String id;
  final String bookingId;
  final String workerId;
  final String customerId;
  final AlertType type;
  final AlertSeverity severity;
  final AlertStatus status;
  final String message;
  final double? latitude;
  final double? longitude;
  final String? resolvedBy; // admin uid
  final String? resolutionNotes;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;

  const SafetyAlert({
    required this.id,
    required this.bookingId,
    required this.workerId,
    required this.customerId,
    required this.type,
    this.severity = AlertSeverity.medium,
    this.status = AlertStatus.open,
    required this.message,
    this.latitude,
    this.longitude,
    this.resolvedBy,
    this.resolutionNotes,
    required this.createdAt,
    this.acknowledgedAt,
    this.resolvedAt,
  });

  bool get isOpen => status == AlertStatus.open;
  bool get isCritical => severity == AlertSeverity.critical;

  SafetyAlert copyWith({
    AlertStatus? status,
    String? resolvedBy,
    String? resolutionNotes,
    DateTime? acknowledgedAt,
    DateTime? resolvedAt,
  }) => SafetyAlert(
    id: id,
    bookingId: bookingId,
    workerId: workerId,
    customerId: customerId,
    type: type,
    severity: severity,
    status: status ?? this.status,
    message: message,
    latitude: latitude,
    longitude: longitude,
    resolvedBy: resolvedBy ?? this.resolvedBy,
    resolutionNotes: resolutionNotes ?? this.resolutionNotes,
    createdAt: createdAt,
    acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
    resolvedAt: resolvedAt ?? this.resolvedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookingId': bookingId,
    'workerId': workerId,
    'customerId': customerId,
    'type': type.name,
    'severity': severity.name,
    'status': status.name,
    'message': message,
    'latitude': latitude,
    'longitude': longitude,
    'resolvedBy': resolvedBy,
    'resolutionNotes': resolutionNotes,
    'createdAt': Timestamp.fromDate(createdAt),
    'acknowledgedAt': acknowledgedAt != null
        ? Timestamp.fromDate(acknowledgedAt!)
        : null,
    'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
  };

  factory SafetyAlert.fromJson(Map<String, dynamic> json) => SafetyAlert(
    id: json['id'] as String? ?? '',
    bookingId: json['bookingId'] as String? ?? '',
    workerId: json['workerId'] as String? ?? '',
    customerId: json['customerId'] as String? ?? '',
    type: AlertType.values.firstWhere(
      (e) => e.name == (json['type'] as String?),
      orElse: () => AlertType.missedCheckIn,
    ),
    severity: AlertSeverity.values.firstWhere(
      (e) => e.name == (json['severity'] as String?),
      orElse: () => AlertSeverity.medium,
    ),
    status: AlertStatus.values.firstWhere(
      (e) => e.name == (json['status'] as String?),
      orElse: () => AlertStatus.open,
    ),
    message: json['message'] as String? ?? '',
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    resolvedBy: json['resolvedBy'] as String?,
    resolutionNotes: json['resolutionNotes'] as String?,
    createdAt: (json['createdAt'] as Timestamp).toDate(),
    acknowledgedAt: json['acknowledgedAt'] != null
        ? (json['acknowledgedAt'] as Timestamp).toDate()
        : null,
    resolvedAt: json['resolvedAt'] != null
        ? (json['resolvedAt'] as Timestamp).toDate()
        : null,
  );

  factory SafetyAlert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SafetyAlert.fromJson({...data, 'id': doc.id});
  }

  @override
  List<Object?> get props => [id, bookingId, type, status];
}
