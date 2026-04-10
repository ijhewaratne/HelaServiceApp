import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/incident.dart';

abstract class IncidentRepository {
  /// Report a new incident
  Future<Either<Failure, Incident>> reportIncident(Incident incident);
  
  /// Get incidents reported by a user
  Future<Either<Failure, List<Incident>>> getUserIncidents(String userId);
  
  /// Get all incidents (for admin)
  Future<Either<Failure, List<Incident>>> getAllIncidents({
    IncidentStatus? status,
    int limit = 50,
  });
  
  /// Update incident status
  Future<Either<Failure, Incident>> updateIncidentStatus({
    required String incidentId,
    required IncidentStatus status,
    String? resolution,
    String? resolvedBy,
  });
  
  /// Get incident by ID
  Future<Either<Failure, Incident>> getIncidentById(String incidentId);
  
  /// Stream incidents for realtime updates
  Stream<Either<Failure, List<Incident>>> watchIncidents({
    String? userId,
    IncidentStatus? status,
  });
}
