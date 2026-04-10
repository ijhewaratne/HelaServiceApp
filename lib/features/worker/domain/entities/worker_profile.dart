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
      uid: json['uid'] ?? '',
      nic: json['nic'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      district: json['district'] ?? '',
      serviceTypes: List<String>.from(json['serviceTypes'] ?? []),
      languages: List<String>.from(json['languages'] ?? []),
      verificationStatus: json['verificationStatus'] ?? 'pending',
      rating: (json['rating'] ?? 0.0).toDouble(),
      completedJobs: json['completedJobs'] ?? 0,
      isAvailable: json['isAvailable'] ?? false,
      homeLat: json['homeLat']?.toDouble(),
      homeLng: json['homeLng']?.toDouble(),
      currentLat: json['currentLat']?.toDouble(),
      currentLng: json['currentLng']?.toDouble(),
      workerType: json['workerType'] == 'employee' ? WorkerType.employee : WorkerType.independentContractor,
      availabilityMode: json['availabilityMode'] ?? 'part_time',
      badge: json['badge'],
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
