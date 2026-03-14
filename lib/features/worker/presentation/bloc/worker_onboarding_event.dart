part of 'worker_onboarding_bloc.dart';

abstract class WorkerOnboardingEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubmitPersonalInfo extends WorkerOnboardingEvent {
  final String nic;
  final String fullName;
  final String mobileNumber;
  final String address;
  final String emergencyContactName;
  final String emergencyContactPhone;

  SubmitPersonalInfo({
    required this.nic,
    required this.fullName,
    required this.mobileNumber,
    required this.address,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
  });

  @override
  List<Object?> get props => [nic, fullName, mobileNumber, address, emergencyContactName, emergencyContactPhone];
}

class SelectServices extends WorkerOnboardingEvent {
  final List<ServiceType> services;
  SelectServices(this.services);
  
  @override
  List<Object?> get props => [services];
}

class UploadNICFront extends WorkerOnboardingEvent {
  final File file;
  UploadNICFront(this.file);
  
  @override
  List<Object?> get props => [file];
}

class UploadNICBack extends WorkerOnboardingEvent {
  final File file;
  UploadNICBack(this.file);
  
  @override
  List<Object?> get props => [file];
}

class UploadProfilePhoto extends WorkerOnboardingEvent {
  final File file;
  UploadProfilePhoto(this.file);
}

class CheckApplicationStatus extends WorkerOnboardingEvent {
  final String workerId;
  CheckApplicationStatus(this.workerId);
}

class CompleteTraining extends WorkerOnboardingEvent {}