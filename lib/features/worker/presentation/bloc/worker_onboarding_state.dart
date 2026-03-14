part of 'worker_onboarding_bloc.dart';

abstract class WorkerOnboardingState extends Equatable {
  @override
  List<Object?> get props => [];
}

class WorkerOnboardingInitial extends WorkerOnboardingState {}

class WorkerOnboardingLoading extends WorkerOnboardingState {}

class WorkerOnboardingError extends WorkerOnboardingState {
  final String message;
  WorkerOnboardingError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// Step 1: Personal Info
class PersonalInfoSubmitted extends WorkerOnboardingState {
  final WorkerApplication application;
  PersonalInfoSubmitted(this.application);
  
  @override
  List<Object?> get props => [application];
}

// Step 2: Services
class ServicesSelected extends WorkerOnboardingState {
  final WorkerApplication application;
  ServicesSelected(this.application);
  
  @override
  List<Object?> get props => [application];
}

// Step 3: Documents
class DocumentsUploading extends WorkerOnboardingState {
  final WorkerApplication application;
  final bool isFront;
  DocumentsUploading(this.application, {required this.isFront});
}

class NICFrontUploaded extends WorkerOnboardingState {
  final WorkerApplication application;
  NICFrontUploaded(this.application);
}

class DocumentsCompleted extends WorkerOnboardingState {
  final WorkerApplication application;
  DocumentsCompleted(this.application);
}

class ProfilePhotoUploaded extends WorkerOnboardingState {
  final String url;
  ProfilePhotoUploaded(this.url);
}

// Review States
class ApplicationUnderReview extends WorkerOnboardingState {
  final WorkerApplication application;
  ApplicationUnderReview(this.application);
}

class TrainingRequired extends WorkerOnboardingState {
  final WorkerApplication application;
  TrainingRequired(this.application);
}

class ApplicationApproved extends WorkerOnboardingState {
  final WorkerApplication application;
  ApplicationApproved(this.application);
}

class ApplicationRejected extends WorkerOnboardingState {
  final WorkerApplication application;
  final String? reason;
  ApplicationRejected(this.application, this.reason);
}