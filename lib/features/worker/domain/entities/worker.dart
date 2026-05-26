import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

class Worker extends Equatable {
  final String id;
  final String nic;
  final String fullName;
  final String mobileNumber;
  final String address;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final List<ServiceType> services;
  final String? profilePhotoUrl;
  final String? nicFrontUrl;
  final String? nicBackUrl;
  final WorkerStatus status;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final bool isOnline;
  final double? currentLat;
  final double? currentLng;
  final double? homeLat;
  final double? homeLng;
  final double rating;
  final int totalJobs;
  final DateTime? lastJobCompletedAt;
  final bool hasAcceptedContract;

  const Worker({
    required this.id,
    required this.nic,
    required this.fullName,
    required this.mobileNumber,
    required this.address,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.services,
    this.profilePhotoUrl,
    this.nicFrontUrl,
    this.nicBackUrl,
    this.status = WorkerStatus.pending,
    required this.createdAt,
    this.approvedAt,
    this.isOnline = false,
    this.currentLat,
    this.currentLng,
    this.homeLat,
    this.homeLng,
    this.rating = 4.0,
    this.totalJobs = 0,
    this.lastJobCompletedAt,
    this.hasAcceptedContract = false,
  });

  Worker copyWith({
    String? id,
    String? nic,
    String? fullName,
    String? mobileNumber,
    String? address,
    String? emergencyContactName,
    String? emergencyContactPhone,
    List<ServiceType>? services,
    String? profilePhotoUrl,
    String? nicFrontUrl,
    String? nicBackUrl,
    WorkerStatus? status,
    DateTime? createdAt,
    DateTime? approvedAt,
    bool? isOnline,
    double? currentLat,
    double? currentLng,
    double? homeLat,
    double? homeLng,
    double? rating,
    int? totalJobs,
    DateTime? lastJobCompletedAt,
    bool? hasAcceptedContract,
  }) {
    return Worker(
      id: id ?? this.id,
      nic: nic ?? this.nic,
      fullName: fullName ?? this.fullName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      address: address ?? this.address,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      services: services ?? this.services,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      nicFrontUrl: nicFrontUrl ?? this.nicFrontUrl,
      nicBackUrl: nicBackUrl ?? this.nicBackUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      isOnline: isOnline ?? this.isOnline,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      homeLat: homeLat ?? this.homeLat,
      homeLng: homeLng ?? this.homeLng,
      rating: rating ?? this.rating,
      totalJobs: totalJobs ?? this.totalJobs,
      lastJobCompletedAt: lastJobCompletedAt ?? this.lastJobCompletedAt,
      hasAcceptedContract: hasAcceptedContract ?? this.hasAcceptedContract,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nic': nic,
      'fullName': fullName,
      'mobileNumber': mobileNumber,
      'address': address,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'services': services.map((s) => s.name).toList(),
      'profilePhotoUrl': profilePhotoUrl,
      'nicFrontUrl': nicFrontUrl,
      'nicBackUrl': nicBackUrl,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'isOnline': isOnline,
      'currentLat': currentLat,
      'currentLng': currentLng,
      'homeLat': homeLat,
      'homeLng': homeLng,
      'rating': rating,
      'totalJobs': totalJobs,
      'lastJobCompletedAt': lastJobCompletedAt?.toIso8601String(),
      'hasAcceptedContract': hasAcceptedContract,
    };
  }

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['id'] as String? ?? '',
      nic: json['nic'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      mobileNumber: json['mobileNumber'] as String? ?? '',
      address: json['address'] as String? ?? '',
      emergencyContactName: json['emergencyContactName'] as String? ?? '',
      emergencyContactPhone: json['emergencyContactPhone'] as String? ?? '',
      services: (json['services'] as List<dynamic>?)
          ?.map((s) => ServiceType.values.firstWhere(
            (e) => e.name == s as String?,
            orElse: () => ServiceType.cleaning,
          ))
          .toList() ?? [],
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      nicFrontUrl: json['nicFrontUrl'] as String?,
      nicBackUrl: json['nicBackUrl'] as String?,
      status: WorkerStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String?),
        orElse: () => WorkerStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'] as String)
          : null,
      isOnline: json['isOnline'] as bool? ?? false,
      currentLat: (json['currentLat'] as num?)?.toDouble(),
      currentLng: (json['currentLng'] as num?)?.toDouble(),
      homeLat: (json['homeLat'] as num?)?.toDouble(),
      homeLng: (json['homeLng'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 4.0,
      totalJobs: (json['totalJobs'] as int?) ?? 0,
      lastJobCompletedAt: json['lastJobCompletedAt'] != null
          ? DateTime.parse(json['lastJobCompletedAt'] as String)
          : null,
      hasAcceptedContract: json['hasAcceptedContract'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nic,
        fullName,
        mobileNumber,
        address,
        emergencyContactName,
        emergencyContactPhone,
        services,
        profilePhotoUrl,
        nicFrontUrl,
        nicBackUrl,
        status,
        createdAt,
        approvedAt,
        isOnline,
        currentLat,
        currentLng,
        homeLat,
        homeLng,
        rating,
        totalJobs,
        lastJobCompletedAt,
        hasAcceptedContract,
      ];
}

enum ServiceType { cleaning, babysitting, elderlyCare, cooking, laundry }

enum WorkerStatus { 
  pending,      // Applied, waiting for doc upload
  underReview,  // Docs uploaded, admin reviewing
  trainingRequired, // Needs to complete training
  approved,     // Can go online
  rejected,     // Application rejected
  suspended,    // Temporarily suspended
}

extension ServiceTypeExtension on ServiceType {
  String get displayName {
    switch (this) {
      case ServiceType.cleaning:
        return 'Home Cleaning';
      case ServiceType.babysitting:
        return 'Babysitting';
      case ServiceType.elderlyCare:
        return 'Elderly Care';
      case ServiceType.cooking:
        return 'Cooking Help';
      case ServiceType.laundry:
        return 'Laundry & Ironing';
    }
  }

  String get icon {
    switch (this) {
      case ServiceType.cleaning:
        return '🧹';
      case ServiceType.babysitting:
        return '👶';
      case ServiceType.elderlyCare:
        return '❤️';
      case ServiceType.cooking:
        return '🍳';
      case ServiceType.laundry:
        return '👕';
    }
  }
}

extension WorkerStatusExtension on WorkerStatus {
  String get displayName {
    switch (this) {
      case WorkerStatus.pending:
        return 'Pending';
      case WorkerStatus.underReview:
        return 'Under Review';
      case WorkerStatus.trainingRequired:
        return 'Training Required';
      case WorkerStatus.approved:
        return 'Approved';
      case WorkerStatus.rejected:
        return 'Rejected';
      case WorkerStatus.suspended:
        return 'Suspended';
    }
  }

  Color get color {
    switch (this) {
      case WorkerStatus.pending:
        return Colors.orange;
      case WorkerStatus.underReview:
        return Colors.blue;
      case WorkerStatus.trainingRequired:
        return Colors.purple;
      case WorkerStatus.approved:
        return Colors.green;
      case WorkerStatus.rejected:
        return Colors.red;
      case WorkerStatus.suspended:
        return Colors.grey;
    }
  }
}
