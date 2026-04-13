import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/services/location_service.dart';
import '../../domain/entities/worker.dart';
import '../../domain/entities/worker_application.dart';
import '../../domain/repositories/worker_repository.dart';

/// BLoC for managing worker-related state
class WorkerBloc extends Bloc<WorkerEvent, WorkerState> {
  final WorkerRepository _workerRepository;
  final LocationService _locationService;

  WorkerBloc({
    required WorkerRepository workerRepository,
    required LocationService locationService,
  })  : _workerRepository = workerRepository,
        _locationService = locationService,
        super(WorkerInitial()) {
    on<LoadWorker>(_onLoadWorker);
    on<CheckNICExists>(_onCheckNICExists);
    on<SubmitApplication>(_onSubmitApplication);
    on<GetApplicationStatus>(_onGetApplicationStatus);
    on<UpdateOnlineStatus>(_onUpdateOnlineStatus);
    on<UpdateLocation>(_onUpdateLocation);
    on<StartLocationTracking>(_onStartLocationTracking);
    on<StopLocationTracking>(_onStopLocationTracking);
    on<CompleteTraining>(_onCompleteTraining);
    on<UploadDocument>(_onUploadDocument);
    on<UploadProfilePhoto>(_onUploadProfilePhoto);
    on<AcceptContract>(_onAcceptContract);
  }

  Future<void> _onLoadWorker(LoadWorker event, Emitter<WorkerState> emit) async {
    emit(WorkerLoading());
    final result = await _workerRepository.getWorker(event.workerId);
    result.fold(
      (failure) => emit(WorkerError(message: failure.message)),
      (worker) => emit(WorkerLoaded(worker: worker)),
    );
  }

  Future<void> _onCheckNICExists(
    CheckNICExists event,
    Emitter<WorkerState> emit,
  ) async {
    emit(WorkerLoading());
    final result = await _workerRepository.checkNICExists(event.nic);
    result.fold(
      (failure) => emit(WorkerError(message: failure.message)),
      (exists) => emit(WorkerNICCheckResult(exists: exists)),
    );
  }

  Future<void> _onSubmitApplication(
    SubmitApplication event,
    Emitter<WorkerState> emit,
  ) async {
    emit(WorkerLoading());
    final result = await _workerRepository.submitApplication(event.application);
    result.fold(
      (failure) => emit(WorkerError(message: failure.message)),
      (application) => emit(WorkerApplicationSubmitted(application: application)),
    );
  }

  Future<void> _onGetApplicationStatus(
    GetApplicationStatus event,
    Emitter<WorkerState> emit,
  ) async {
    emit(WorkerLoading());
    final result = await _workerRepository.getApplicationStatus(event.workerId);
    result.fold(
      (failure) => emit(WorkerError(message: failure.message)),
      (application) => emit(WorkerApplicationStatusLoaded(application: application)),
    );
  }

  Future<void> _onUpdateOnlineStatus(
    UpdateOnlineStatus event,
    Emitter<WorkerState> emit,
  ) async {
    emit(WorkerLoading());
    final result = await _workerRepository.updateOnlineStatus(
      workerId: event.workerId,
      isOnline: event.isOnline,
      lat: event.lat,
      lng: event.lng,
    );
    result.fold(
      (failure) => emit(WorkerError(message: failure.message)),
      (_) {
        if (event.isOnline) {
          add(StartLocationTracking(workerId: event.workerId));
        } else {
          add(StopLocationTracking());
        }
        emit(WorkerOnlineStatusUpdated(isOnline: event.isOnline));
      },
    );
  }

  Future<void> _onUpdateLocation(
    UpdateLocation event,
    Emitter<WorkerState> emit,
  ) async {
    final result = await _workerRepository.updateLocation(
      workerId: event.workerId,
      lat: event.latitude,
      lng: event.longitude,
    );
    result.fold(
      (failure) => emit(WorkerError(message: failure.message)),
      (_) => emit(WorkerLocationUpdated()),
    );
  }

  Future<void> _onStartLocationTracking(
    StartLocationTracking event,
    Emitter<WorkerState> emit,
  ) async {
    try {
      await _locationService.startTracking(event.workerId);
      emit(WorkerTrackingStarted());
    } catch (e) {
      emit(WorkerError(message: 'Failed to start location tracking: $e'));
    }
  }

  Future<void> _onStopLocationTracking(
    StopLocationTracking event,
    Emitter<WorkerState> emit,
  ) async {
    try {
      await _locationService.stopTracking();
      emit(WorkerTrackingStopped());
    } catch (e) {
      emit(WorkerError(message: 'Failed to stop location tracking: $e'));
    }
  }

  Future<void> _onCompleteTraining(
    CompleteTraining event,
    Emitter<WorkerState> emit,
  ) async {
    emit(WorkerLoading());
    final result = await _workerRepository.completeTraining(event.workerId);
    result.fold(
      (failure) => emit(WorkerError(message: failure.message)),
      (_) => emit(WorkerTrainingCompleted()),
    );
  }

  Future<void> _onUploadDocument(
    UploadDocument event,
    Emitter<WorkerState> emit,
  ) async {
    emit(WorkerLoading());
    final result = await _workerRepository.uploadNICDocument(
      workerId: event.workerId,
      file: event.file,
      isFront: event.isFront,
    );
    result.fold(
      (failure) => emit(WorkerError(message: failure.message)),
      (url) => emit(WorkerDocumentUploaded(documentUrl: url, isFront: event.isFront)),
    );
  }

  Future<void> _onUploadProfilePhoto(
    UploadProfilePhoto event,
    Emitter<WorkerState> emit,
  ) async {
    emit(WorkerLoading());
    final result = await _workerRepository.uploadProfilePhoto(
      workerId: event.workerId,
      file: event.file,
    );
    result.fold(
      (failure) => emit(WorkerError(message: failure.message)),
      (url) => emit(WorkerProfilePhotoUploaded(photoUrl: url)),
    );
  }

  Future<void> _onAcceptContract(
    AcceptContract event,
    Emitter<WorkerState> emit,
  ) async {
    emit(WorkerLoading());
    final result = await _workerRepository.acceptContract(event.workerId);
    result.fold(
      (failure) => emit(WorkerError(message: failure.message)),
      (_) => emit(WorkerContractAccepted()),
    );
  }
}

// ==================== EVENTS ====================

abstract class WorkerEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Load worker data
class LoadWorker extends WorkerEvent {
  final String workerId;

  LoadWorker({required this.workerId});

  @override
  List<Object?> get props => [workerId];
}

/// Check if NIC exists
class CheckNICExists extends WorkerEvent {
  final String nic;

  CheckNICExists({required this.nic});

  @override
  List<Object?> get props => [nic];
}

/// Submit worker application
class SubmitApplication extends WorkerEvent {
  final WorkerApplication application;

  SubmitApplication({required this.application});

  @override
  List<Object?> get props => [application];
}

/// Get application status
class GetApplicationStatus extends WorkerEvent {
  final String workerId;

  GetApplicationStatus({required this.workerId});

  @override
  List<Object?> get props => [workerId];
}

/// Update online status
class UpdateOnlineStatus extends WorkerEvent {
  final String workerId;
  final bool isOnline;
  final double? lat;
  final double? lng;

  UpdateOnlineStatus({
    required this.workerId,
    required this.isOnline,
    this.lat,
    this.lng,
  });

  @override
  List<Object?> get props => [workerId, isOnline, lat, lng];
}

/// Update location manually
class UpdateLocation extends WorkerEvent {
  final String workerId;
  final double latitude;
  final double longitude;

  UpdateLocation({
    required this.workerId,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [workerId, latitude, longitude];
}

/// Start location tracking
class StartLocationTracking extends WorkerEvent {
  final String workerId;

  StartLocationTracking({required this.workerId});

  @override
  List<Object?> get props => [workerId];
}

/// Stop location tracking
class StopLocationTracking extends WorkerEvent {}

/// Complete training
class CompleteTraining extends WorkerEvent {
  final String workerId;

  CompleteTraining({required this.workerId});

  @override
  List<Object?> get props => [workerId];
}

/// Upload NIC document
class UploadDocument extends WorkerEvent {
  final String workerId;
  final File file;
  final bool isFront;

  UploadDocument({
    required this.workerId,
    required this.file,
    required this.isFront,
  });

  @override
  List<Object?> get props => [workerId, file, isFront];
}

/// Upload profile photo
class UploadProfilePhoto extends WorkerEvent {
  final String workerId;
  final File file;

  UploadProfilePhoto({required this.workerId, required this.file});

  @override
  List<Object?> get props => [workerId, file];
}

/// Accept independent contractor agreement
class AcceptContract extends WorkerEvent {
  final String workerId;

  AcceptContract({required this.workerId});

  @override
  List<Object?> get props => [workerId];
}

// ==================== STATES ====================

abstract class WorkerState extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Initial state
class WorkerInitial extends WorkerState {}

/// Loading state
class WorkerLoading extends WorkerState {}

/// Worker loaded successfully
class WorkerLoaded extends WorkerState {
  final Worker worker;

  WorkerLoaded({required this.worker});

  @override
  List<Object?> get props => [worker];
}

/// NIC check result
class WorkerNICCheckResult extends WorkerState {
  final bool exists;

  WorkerNICCheckResult({required this.exists});

  @override
  List<Object?> get props => [exists];
}

/// Application submitted successfully
class WorkerApplicationSubmitted extends WorkerState {
  final WorkerApplication application;

  WorkerApplicationSubmitted({required this.application});

  @override
  List<Object?> get props => [application];
}

/// Application status loaded
class WorkerApplicationStatusLoaded extends WorkerState {
  final WorkerApplication application;

  WorkerApplicationStatusLoaded({required this.application});

  @override
  List<Object?> get props => [application];
}

/// Online status updated
class WorkerOnlineStatusUpdated extends WorkerState {
  final bool isOnline;

  WorkerOnlineStatusUpdated({required this.isOnline});

  @override
  List<Object?> get props => [isOnline];
}

/// Location updated
class WorkerLocationUpdated extends WorkerState {}

/// Tracking started
class WorkerTrackingStarted extends WorkerState {}

/// Tracking stopped
class WorkerTrackingStopped extends WorkerState {}

/// Training completed
class WorkerTrainingCompleted extends WorkerState {}

/// Document uploaded
class WorkerDocumentUploaded extends WorkerState {
  final String documentUrl;
  final bool isFront;

  WorkerDocumentUploaded({required this.documentUrl, required this.isFront});

  @override
  List<Object?> get props => [documentUrl, isFront];
}

/// Profile photo uploaded
class WorkerProfilePhotoUploaded extends WorkerState {
  final String photoUrl;

  WorkerProfilePhotoUploaded({required this.photoUrl});

  @override
  List<Object?> get props => [photoUrl];
}

/// Contract accepted
class WorkerContractAccepted extends WorkerState {}

/// Error state
class WorkerError extends WorkerState {
  final String message;

  WorkerError({required this.message});

  @override
  List<Object?> get props => [message];
}
