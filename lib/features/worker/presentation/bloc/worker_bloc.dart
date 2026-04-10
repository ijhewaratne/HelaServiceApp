import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

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
    on<SubmitApplication>(_onSubmitApplication);
    on<UpdateOnlineStatus>(_onUpdateOnlineStatus);
    on<UpdateLocation>(_onUpdateLocation);
    on<StartLocationTracking>(_onStartLocationTracking);
    on<StopLocationTracking>(_onStopLocationTracking);
    on<CompleteTraining>(_onCompleteTraining);
    on<UploadDocument>(_onUploadDocument);
  }

  Future<void> _onLoadWorker(LoadWorker event, Emitter<WorkerState> emit) async {
    emit(WorkerLoading());
    final result = await _workerRepository.getWorker(event.workerId);
    result.fold(
      (failure) => emit(WorkerError(message: failure.message)),
      (worker) => emit(WorkerLoaded(worker: worker)),
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

  Future<void> _onUpdateOnlineStatus(
    UpdateOnlineStatus event,
    Emitter<WorkerState> emit,
  ) async {
    emit(WorkerLoading());
    final result = await _workerRepository.updateOnlineStatus(
      event.workerId,
      event.isOnline,
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
      event.workerId,
      event.latitude,
      event.longitude,
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
      event.workerId,
      event.file,
      event.isFront,
    );
    result.fold(
      (failure) => emit(WorkerError(message: failure.message)),
      (url) => emit(WorkerDocumentUploaded(documentUrl: url, isFront: event.isFront)),
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

/// Submit worker application
class SubmitApplication extends WorkerEvent {
  final WorkerApplication application;

  SubmitApplication({required this.application});

  @override
  List<Object?> get props => [application];
}

/// Update online status
class UpdateOnlineStatus extends WorkerEvent {
  final String workerId;
  final bool isOnline;

  UpdateOnlineStatus({required this.workerId, required this.isOnline});

  @override
  List<Object?> get props => [workerId, isOnline];
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

/// Upload document
class UploadDocument extends WorkerEvent {
  final String workerId;
  final dynamic file;
  final bool isFront;

  UploadDocument({
    required this.workerId,
    required this.file,
    required this.isFront,
  });

  @override
  List<Object?> get props => [workerId, file, isFront];
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

/// Application submitted successfully
class WorkerApplicationSubmitted extends WorkerState {
  final WorkerApplication application;

  WorkerApplicationSubmitted({required this.application});

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

/// Error state
class WorkerError extends WorkerState {
  final String message;

  WorkerError({required this.message});

  @override
  List<Object?> get props => [message];
}
