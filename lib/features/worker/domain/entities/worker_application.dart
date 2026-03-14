import 'package:equatable/equatable.dart';

class WorkerApplication extends Equatable {
  final String? id;
  final String nic;
  final String fullName;
  final String mobileNumber;
  final String address;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final List<ServiceType> selectedServices;
  final String? profilePhotoUrl;
  final String? nicFrontUrl;
  final String? nicBackUrl;
  final ApplicationStatus status;
  final DateTime appliedAt;
  final String? rejectionReason;
  final bool hasCompletedTraining;

  const WorkerApplication({
    this.id,
    required this.nic,
    required this.fullName,
    required this.mobileNumber,
    required this.address,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.selectedServices,
    this.profilePhotoUrl,
    this.nicFrontUrl,
    this.nicBackUrl,
    this.status = ApplicationStatus.draft,
    required this.appliedAt,
    this.rejectionReason,
    this.hasCompletedTraining = false,
  });

  WorkerApplication copyWith({
    String? id,
    String? nic,
    String? fullName,
    String? mobileNumber,
    String? address,
    String? emergencyContactName,
    String? emergencyContactPhone,
    List<ServiceType>? selectedServices,
    String? profilePhotoUrl,
    String? nicFrontUrl,
    String? nicBackUrl,
    ApplicationStatus? status,
    DateTime? appliedAt,
    String? rejectionReason,
    bool? hasCompletedTraining,
  }) {
    return WorkerApplication(
      id: id ?? this.id,
      nic: nic ?? this.nic,
      fullName: fullName ?? this.fullName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      address: address ?? this.address,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      selectedServices: selectedServices ?? this.selectedServices,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      nicFrontUrl: nicFrontUrl ?? this.nicFrontUrl,
      nicBackUrl: nicBackUrl ?? this.nicBackUrl,
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      hasCompletedTraining: hasCompletedTraining ?? this.hasCompletedTraining,
    );
  }

  @override
  List<Object?> get props => [
        id, nic, fullName, mobileNumber, address,
        emergencyContactName, emergencyContactPhone,
        selectedServices, profilePhotoUrl, nicFrontUrl, nicBackUrl,
        status, appliedAt, rejectionReason, hasCompletedTraining,
      ];
}

enum ServiceType { cleaning, babysitting, elderlyCare, cooking, laundry }
enum ApplicationStatus { 
  draft,           // Filling form
  pendingDocs,     // Awaiting NIC upload
  underReview,     // Admin checking
  trainingRequired,// Needs to watch videos
  approved,        // Can go online
  rejected         // Failed verification
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

  String get description {
    switch (this) {
      case ServiceType.cleaning:
        return 'General house cleaning, sweeping, mopping';
      case ServiceType.babysitting:
        return 'Child care (non-medical), feeding, playing';
      case ServiceType.elderlyCare:
        return 'Companion care, assistance with mobility (no medical tasks)';
      case ServiceType.cooking:
        return 'Meal preparation, kitchen help';
      case ServiceType.laundry:
        return 'Washing and ironing clothes';
    }
  }
}