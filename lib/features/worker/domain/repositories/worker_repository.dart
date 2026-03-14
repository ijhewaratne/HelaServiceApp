import 'dart:io';
import 'package:dartz/dartz.dart';
import '../entities/worker_application.dart';

abstract class WorkerRepository {
  /// Submit initial application
  Future<Either<Failure, WorkerApplication>> submitApplication(WorkerApplication application);
  
  /// Upload NIC document (front or back)
  Future<Either<Failure, String>> uploadNICDocument(String workerId, File file, bool isFront);
  
  /// Upload profile photo
  Future<Either<Failure, String>> uploadProfilePhoto(String workerId, File file);
  
  /// Get current application status
  Future<Either<Failure, WorkerApplication>> getApplicationStatus(String workerId);
  
  /// Mark training as complete
  Future<Either<Failure, void>> completeTraining(String workerId);
  
  /// Check if NIC already exists (prevent duplicates)
  Future<Either<Failure, bool>> checkNICExists(String nic);
}

class Failure {
  final String message;
  final FailureType type;

  Failure(this.message, {this.type = FailureType.unknown});

  factory Failure.network() => Failure('No internet connection', type: FailureType.network);
  factory Failure.server() => Failure('Server error', type: FailureType.server);
  factory Failure.invalidNIC() => Failure('Invalid NIC format', type: FailureType.validation);
  factory Failure.duplicateNIC() => Failure('This NIC is already registered', type: FailureType.duplicate);
  factory Failure.fileTooLarge() => Failure('Image must be less than 5MB', type: FailureType.validation);
}

enum FailureType { network, server, validation, duplicate, unknown }