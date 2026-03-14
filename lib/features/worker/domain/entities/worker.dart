import 'package:cloud_firestore/cloud_firestore.dart';

/// Core Worker entity representing a service provider on the HelaService platform.
/// Classification between IndependentContractor and PartTimeEmployee is enforced
/// here to satisfy Sri Lanka Department of Labour EPF/ETF requirements.
class Worker {
  final String id;
  final String nic;             // Primary identifier for Sri Lanka (old 9+V or new 12-digit)
  final String fullName;
  final String mobileNumber;    // Format: 07XXXXXXXX
  final WorkerStatus status;
  final List<ServiceType> skills;
  final GeoPoint homeLocation;  // Used for "near home" dispatch optimization
  final List<String> allowedZones; // Zone IDs matched against AppConstants.serviceZones
  final bool isVerified;        // Background check complete
  final DateTime? lastJobCompletedAt; // Used by DispatchEngine for idle-priority scoring
  final double? currentLat;
  final double? currentLng;
  bool isOnline;

  // Legal classification — determines EPF/ETF obligations
  final WorkerContractType contractType;

  // Onboarding progress
  final bool contractSigned;    // ContractAcceptancePage complete
  final bool trainingComplete;  // TrainingVideoPage complete

  Worker({
    required this.id,
    required this.nic,
    required this.fullName,
    required this.mobileNumber,
    this.status = WorkerStatus.pending,
    required this.skills,
    required this.homeLocation,
    this.allowedZones = const [],
    this.isVerified = false,
    this.lastJobCompletedAt,
    this.currentLat,
    this.currentLng,
    this.isOnline = false,
    this.contractType = WorkerContractType.independentContractor,
    this.contractSigned = false,
    this.trainingComplete = false,
  });

  factory Worker.fromMap(Map<String, dynamic> map) {
    return Worker(
      id: map['id'] as String,
      nic: map['nic'] as String,
      fullName: map['fullName'] as String,
      mobileNumber: map['mobileNumber'] as String,
      status: WorkerStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => WorkerStatus.pending,
      ),
      skills: (map['skills'] as List<dynamic>)
          .map((s) => ServiceType.values.firstWhere((e) => e.name == s))
          .toList(),
      homeLocation: map['homeLocation'] as GeoPoint,
      allowedZones: List<String>.from(map['allowedZones'] ?? []),
      isVerified: map['isVerified'] as bool? ?? false,
      lastJobCompletedAt: map['lastJobCompletedAt'] != null
          ? (map['lastJobCompletedAt'] as Timestamp).toDate()
          : null,
      currentLat: (map['currentLat'] as num?)?.toDouble(),
      currentLng: (map['currentLng'] as num?)?.toDouble(),
      isOnline: map['isOnline'] as bool? ?? false,
      contractType: WorkerContractType.values.firstWhere(
        (e) => e.name == map['contractType'],
        orElse: () => WorkerContractType.independentContractor,
      ),
      contractSigned: map['contractSigned'] as bool? ?? false,
      trainingComplete: map['trainingComplete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nic': nic,
        'fullName': fullName,
        'mobileNumber': mobileNumber,
        'status': status.name,
        'skills': skills.map((s) => s.name).toList(),
        'homeLocation': homeLocation,
        'allowedZones': allowedZones,
        'isVerified': isVerified,
        'lastJobCompletedAt': lastJobCompletedAt != null
            ? Timestamp.fromDate(lastJobCompletedAt!)
            : null,
        'currentLat': currentLat,
        'currentLng': currentLng,
        'isOnline': isOnline,
        'contractType': contractType.name,
        'contractSigned': contractSigned,
        'trainingComplete': trainingComplete,
      };

  Worker copyWith({
    bool? isOnline,
    WorkerStatus? status,
    double? currentLat,
    double? currentLng,
    DateTime? lastJobCompletedAt,
  }) {
    return Worker(
      id: id,
      nic: nic,
      fullName: fullName,
      mobileNumber: mobileNumber,
      status: status ?? this.status,
      skills: skills,
      homeLocation: homeLocation,
      allowedZones: allowedZones,
      isVerified: isVerified,
      lastJobCompletedAt: lastJobCompletedAt ?? this.lastJobCompletedAt,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      isOnline: isOnline ?? this.isOnline,
      contractType: contractType,
      contractSigned: contractSigned,
      trainingComplete: trainingComplete,
    );
  }
}

enum WorkerStatus {
  pending,
  documentReview,
  training,
  active,
  suspended,
  blacklisted
}

enum WorkerContractType { independentContractor, partTimeEmployee }

enum ServiceType {
  cleaning,
  babysitting,
  elderlyCare,
  cooking,
  laundry,
}
