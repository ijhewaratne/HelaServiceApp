import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum WorkerType { independentContractor, employee }

class WorkerProfile {
  final String uid;
  final String nic; // Primary ID for Sri Lanka
  final String name;
  final String phone;
  final String district;
  final List<String> serviceTypes;
  final List<String> languages;
  final String verificationStatus;
  final double rating;
  final int completedJobs;
  bool isAvailable;
  
  // Location Tracking
  final double? homeLat; // Home loc for PickMe logic
  final double? homeLng;
  double? currentLat;
  double? currentLng;
  
  final WorkerType workerType; // Classification
  final String availabilityMode;
  final String? badge;

  WorkerProfile({
    required this.uid,
    required this.nic,
    required this.name,
    required this.phone,
    required this.district,
    required this.serviceTypes,
    required this.languages,
    required this.verificationStatus,
    required this.rating,
    required this.completedJobs,
    required this.isAvailable,
    this.homeLat,
    this.homeLng,
    this.currentLat,
    this.currentLng,
    this.workerType = WorkerType.independentContractor,
    required this.availabilityMode,
    this.badge,
  });

  bool canGoOnline(LatLng requestedLocation) {
    // Allow going online if worker is approved
    // Zone validation happens server-side
    return verificationStatus == 'approved';
  }

  void toggleAvailability(LatLng? currentLocation) {
    if (currentLocation == null) return;
    if (canGoOnline(currentLocation)) {
      isAvailable = !isAvailable;
    }
  }

  factory WorkerProfile.fromJson(Map<String, dynamic> json) {
    return WorkerProfile(
      uid: json['uid'] as String? ?? '',
      nic: json['nic'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      district: json['district'] as String? ?? '',
      serviceTypes: List<String>.from(json['serviceTypes'] as List<dynamic>? ?? []),
      languages: List<String>.from(json['languages'] as List<dynamic>? ?? []),
      verificationStatus: json['verificationStatus'] as String? ?? 'pending',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      completedJobs: json['completedJobs'] as int? ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? false,
      homeLat: (json['homeLat'] as num?)?.toDouble(),
      homeLng: (json['homeLng'] as num?)?.toDouble(),
      currentLat: (json['currentLat'] as num?)?.toDouble(),
      currentLng: (json['currentLng'] as num?)?.toDouble(),
      workerType: (json['workerType'] as String?) == 'employee' ? WorkerType.employee : WorkerType.independentContractor,
      availabilityMode: json['availabilityMode'] as String? ?? 'part_time',
      badge: json['badge'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'nic': nic,
      'name': name,
      'phone': phone,
      'district': district,
      'serviceTypes': serviceTypes,
      'languages': languages,
      'verificationStatus': verificationStatus,
      'rating': rating,
      'completedJobs': completedJobs,
      'isAvailable': isAvailable,
      'homeLat': homeLat,
      'homeLng': homeLng,
      'currentLat': currentLat,
      'currentLng': currentLng,
      'workerType': workerType == WorkerType.employee ? 'employee' : 'independent_contractor',
      'availabilityMode': availabilityMode,
      'badge': badge,
    };
  }
}
