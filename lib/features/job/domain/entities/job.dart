import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../worker/domain/entities/worker.dart';

/// Core Job entity representing a customer service request.
/// Designed for minimal PDPA data footprint — only house number + landmark,
/// not full address, is stored until worker is actively en route.
class Job {
  final String id;
  final String customerId;
  final ServiceType serviceType;
  final double locationLat;
  final double locationLng;
  final String zoneId;          // Must match one of AppConstants.serviceZones
  final JobStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;    // Worker check-in
  final DateTime? completedAt;  // Worker check-out
  final String? assignedWorkerId;
  final double estimatedEarnings;
  final bool isCashPayment;     // v1: primarily cash

  // Safety & Trust
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  // PDPA Minimization — minimal address data until dispatch confirmed
  final String houseNumber;     // e.g. "12/A"
  final String? landmark;       // e.g. "Near Arpico Supercentre"

  Job({
    required this.id,
    required this.customerId,
    required this.serviceType,
    required this.locationLat,
    required this.locationLng,
    required this.zoneId,
    this.status = JobStatus.searching,
    required this.createdAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.assignedWorkerId,
    required this.estimatedEarnings,
    this.isCashPayment = true,
    this.emergencyContactName,
    this.emergencyContactPhone,
    required this.houseNumber,
    this.landmark,
  });

  factory Job.fromMap(Map<String, dynamic> map) {
    return Job(
      id: map['id'] as String,
      customerId: map['customerId'] as String,
      serviceType: ServiceType.values.firstWhere(
        (e) => e.name == map['serviceType'],
        orElse: () => ServiceType.cleaning,
      ),
      locationLat: (map['locationLat'] as num).toDouble(),
      locationLng: (map['locationLng'] as num).toDouble(),
      zoneId: map['zoneId'] as String,
      status: JobStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => JobStatus.searching,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      acceptedAt: map['acceptedAt'] != null
          ? (map['acceptedAt'] as Timestamp).toDate()
          : null,
      startedAt: map['startedAt'] != null
          ? (map['startedAt'] as Timestamp).toDate()
          : null,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      assignedWorkerId: map['assignedWorkerId'] as String?,
      estimatedEarnings: (map['estimatedEarnings'] as num).toDouble(),
      isCashPayment: map['isCashPayment'] as bool? ?? true,
      emergencyContactName: map['emergencyContactName'] as String?,
      emergencyContactPhone: map['emergencyContactPhone'] as String?,
      houseNumber: map['houseNumber'] as String,
      landmark: map['landmark'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerId': customerId,
        'serviceType': serviceType.name,
        'locationLat': locationLat,
        'locationLng': locationLng,
        'zoneId': zoneId,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
        'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
        'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'assignedWorkerId': assignedWorkerId,
        'estimatedEarnings': estimatedEarnings,
        'isCashPayment': isCashPayment,
        'emergencyContactName': emergencyContactName,
        'emergencyContactPhone': emergencyContactPhone,
        'houseNumber': houseNumber,
        'landmark': landmark,
      };

  Job copyWith({JobStatus? status, String? assignedWorkerId, DateTime? acceptedAt}) {
    return Job(
      id: id,
      customerId: customerId,
      serviceType: serviceType,
      locationLat: locationLat,
      locationLng: locationLng,
      zoneId: zoneId,
      status: status ?? this.status,
      createdAt: createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      startedAt: startedAt,
      completedAt: completedAt,
      assignedWorkerId: assignedWorkerId ?? this.assignedWorkerId,
      estimatedEarnings: estimatedEarnings,
      isCashPayment: isCashPayment,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      houseNumber: houseNumber,
      landmark: landmark,
    );
  }
}

/// Strict state machine — all valid transitions enforced in Firestore Rules too.
enum JobStatus {
  searching,
  assigned,
  accepted,
  enRoute,
  arrived,
  inProgress,
  completed,
  cancelled,
}

/// Lookup table for valid next states used in Firestore Rules and dispatch logic.
const Map<JobStatus, List<JobStatus>> validJobTransitions = {
  JobStatus.searching: [JobStatus.assigned, JobStatus.cancelled],
  JobStatus.assigned: [JobStatus.accepted, JobStatus.cancelled],
  JobStatus.accepted: [JobStatus.enRoute, JobStatus.cancelled],
  JobStatus.enRoute: [JobStatus.arrived],
  JobStatus.arrived: [JobStatus.inProgress],
  JobStatus.inProgress: [JobStatus.completed],
  JobStatus.completed: [],
  JobStatus.cancelled: [],
};
