import 'dart:io';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/worker.dart';
import '../entities/worker_application.dart';

abstract class WorkerRepository {
  /// Create a new worker
  Future<Either<Failure, Worker>> createWorker(Worker worker);

  /// Get worker by ID
  Future<Either<Failure, Worker>> getWorker(String workerId);

  /// Upload NIC document (front or back)
  Future<Either<Failure, String>> uploadNICDocument({
    required String workerId,
    required File file,
    required bool isFront,
  });

  /// Upload profile photo
  Future<Either<Failure, String>> uploadProfilePhoto({
    required String workerId,
    required File file,
  });

  /// Update online status and location
  Future<Either<Failure, void>> updateOnlineStatus({
    required String workerId,
    required bool isOnline,
    double? lat,
    double? lng,
  });

  /// Accept independent contractor agreement
  Future<Either<Failure, void>> acceptContract(String workerId);

  // ==================== ONBOARDING METHODS ====================

  /// Check if NIC already exists in system
  Future<Either<Failure, bool>> checkNICExists(String nic);

  /// Submit worker application
  Future<Either<Failure, WorkerApplication>> submitApplication(WorkerApplication application);

  /// Get application status by worker ID
  Future<Either<Failure, WorkerApplication>> getApplicationStatus(String workerId);

  /// Mark training as completed
  Future<Either<Failure, void>> completeTraining(String workerId);

  /// Update worker location
  Future<Either<Failure, void>> updateLocation({
    required String workerId,
    required double lat,
    required double lng,
  });
}
