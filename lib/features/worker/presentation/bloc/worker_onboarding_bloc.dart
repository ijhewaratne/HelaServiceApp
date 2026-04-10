import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/worker_application.dart';
import '../../domain/repositories/worker_repository.dart';

part 'worker_onboarding_event.dart';
part 'worker_onboarding_state.dart';

class WorkerOnboardingBloc extends Bloc<WorkerOnboardingEvent, WorkerOnboardingState> {
  final WorkerRepository repository;

  WorkerOnboardingBloc({required this.repository}) : super(WorkerOnboardingInitial()) {
    on<SubmitPersonalInfo>(_onSubmitPersonalInfo);
    on<SelectServices>(_onSelectServices);
    on<UploadNICFront>(_onUploadNICFront);
    on<UploadNICBack>(_onUploadNICBack);
    on<UploadProfilePhoto>(_onUploadProfilePhoto);
    on<CheckApplicationStatus>(_onCheckStatus);
    on<CompleteTraining>(_onCompleteTraining);
  }

  Future<void> _onSubmitPersonalInfo(
    SubmitPersonalInfo event,
    Emitter<WorkerOnboardingState> emit,
  ) async {
    emit(WorkerOnboardingLoading());

    // Validate NIC
    final nicExists = await repository.checkNICExists(event.nic);
    if (nicExists.isRight() && nicExists.getOrElse(() => false)) {
      emit(WorkerOnboardingError('This NIC is already registered'));
      return;
    }

    final application = WorkerApplication(
      nic: event.nic,
      fullName: event.fullName,
      mobileNumber: event.mobileNumber,
      address: event.address,
      emergencyContactName: event.emergencyContactName,
      emergencyContactPhone: event.emergencyContactPhone,
      selectedServices: [], // Will be added next step
      appliedAt: DateTime.now(),
    );

    final result = await repository.submitApplication(application);
    
    result.fold(
      (failure) => emit(WorkerOnboardingError(failure.message)),
      (app) => emit(PersonalInfoSubmitted(app)),
    );
  }

  Future<void> _onSelectServices(
    SelectServices event,
    Emitter<WorkerOnboardingState> emit,
  ) async {
    final current = state;
    if (current is PersonalInfoSubmitted) {
      final updated = current.application.copyWith(
        selectedServices: event.services,
        status: ApplicationStatus.pendingDocs,
      );
      emit(ServicesSelected(updated));
    }
  }

  Future<void> _onUploadNICFront(
    UploadNICFront event,
    Emitter<WorkerOnboardingState> emit,
  ) async {
    final current = state;
    if (current is ServicesSelected || current is DocumentsUploading) {
      emit(DocumentsUploading(
        (current as dynamic).application,
        isFront: true,
      ));

      final result = await repository.uploadNICDocument(
        (current as dynamic).application.id!,
        event.file,
        true,
      );

      result.fold(
        (failure) => emit(WorkerOnboardingError(failure.message)),
        (url) => emit(NICFrontUploaded(
          (current as dynamic).application.copyWith(nicFrontUrl: url),
        )),
      );
    }
  }

  Future<void> _onUploadNICBack(
    UploadNICBack event,
    Emitter<WorkerOnboardingState> emit,
  ) async {
    final current = state;
    if (current is NICFrontUploaded) {
      emit(DocumentsUploading(current.application, isFront: false));

      final result = await repository.uploadNICDocument(
        current.application.id!,
        event.file,
        false,
      );

      result.fold(
        (failure) => emit(WorkerOnboardingError(failure.message)),
        (url) {
          final updated = current.application.copyWith(
            nicBackUrl: url,
            status: ApplicationStatus.underReview,
          );
          emit(DocumentsCompleted(updated));
        },
      );
    }
  }

  Future<void> _onUploadProfilePhoto(
    UploadProfilePhoto event,
    Emitter<WorkerOnboardingState> emit,
  ) async {
    final current = state;
    String? workerId;
    
    if (current is PersonalInfoSubmitted) workerId = current.application.id;
    else if (current is ServicesSelected) workerId = current.application.id;
    
    if (workerId != null) {
      final result = await repository.uploadProfilePhoto(workerId, event.file);
      result.fold(
        (failure) => emit(WorkerOnboardingError(failure.message)),
        (url) => emit(ProfilePhotoUploaded(url)),
      );
    }
  }

  Future<void> _onCheckStatus(
    CheckApplicationStatus event,
    Emitter<WorkerOnboardingState> emit,
  ) async {
    emit(WorkerOnboardingLoading());
    final result = await repository.getApplicationStatus(event.workerId);
    
    result.fold(
      (failure) => emit(WorkerOnboardingError(failure.message)),
      (application) {
        if (application.status == ApplicationStatus.approved) {
          emit(ApplicationApproved(application));
        } else if (application.status == ApplicationStatus.trainingRequired) {
          emit(TrainingRequired(application));
        } else if (application.status == ApplicationStatus.rejected) {
          emit(ApplicationRejected(application, application.rejectionReason));
        } else {
          emit(ApplicationUnderReview(application));
        }
      },
    );
  }

  Future<void> _onCompleteTraining(
    CompleteTraining event,
    Emitter<WorkerOnboardingState> emit,
  ) async {
    final current = state;
    if (current is TrainingRequired) {
      emit(WorkerOnboardingLoading());
      final result = await repository.completeTraining(current.application.id!);
      
      result.fold(
        (failure) => emit(WorkerOnboardingError(failure.message)),
        (_) => emit(ApplicationApproved(
          current.application.copyWith(
            hasCompletedTraining: true,
            status: ApplicationStatus.approved,
          ),
        )),
      );
    }
  }
}