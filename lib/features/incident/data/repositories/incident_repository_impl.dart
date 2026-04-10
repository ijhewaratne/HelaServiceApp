import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/incident.dart';
import '../../domain/repositories/incident_repository.dart';

class IncidentRepositoryImpl implements IncidentRepository {
  final FirebaseFirestore _firestore;

  IncidentRepositoryImpl(this._firestore);

  @override
  Future<Either<Failure, Incident>> reportIncident(Incident incident) async {
    try {
      final docRef = _firestore.collection('incidents').doc();
      final incidentWithId = incident.copyWith(id: docRef.id);
      
      await docRef.set(_incidentToMap(incidentWithId));
      
      return Right(incidentWithId);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Failed to report incident'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Incident>>> getUserIncidents(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('incidents')
          .where('reporterId', isEqualTo: userId)
          .orderBy('reportedAt', descending: true)
          .get();
      
      final incidents = snapshot.docs.map((doc) => _incidentFromMap(doc)).toList();
      return Right(incidents);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Failed to fetch incidents'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Incident>>> getAllIncidents({
    IncidentStatus? status,
    int limit = 50,
  }) async {
    try {
      var query = _firestore
          .collection('incidents')
          .orderBy('reportedAt', descending: true)
          .limit(limit);
      
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }
      
      final snapshot = await query.get();
      final incidents = snapshot.docs.map((doc) => _incidentFromMap(doc)).toList();
      return Right(incidents);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Failed to fetch incidents'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Incident>> updateIncidentStatus({
    required String incidentId,
    required IncidentStatus status,
    String? resolution,
    String? resolvedBy,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
      };
      
      if (resolution != null) {
        updateData['resolution'] = resolution;
      }
      if (resolvedBy != null) {
        updateData['resolvedBy'] = resolvedBy;
        updateData['resolvedAt'] = FieldValue.serverTimestamp();
      }
      
      await _firestore.collection('incidents').doc(incidentId).update(updateData);
      
      final doc = await _firestore.collection('incidents').doc(incidentId).get();
      return Right(_incidentFromMap(doc));
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Failed to update incident'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Incident>> getIncidentById(String incidentId) async {
    try {
      final doc = await _firestore.collection('incidents').doc(incidentId).get();
      
      if (!doc.exists) {
        return const Left(ServerFailure('Incident not found'));
      }
      
      return Right(_incidentFromMap(doc));
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Failed to fetch incident'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<Incident>>> watchIncidents({
    String? userId,
    IncidentStatus? status,
  }) {
    try {
      var query = _firestore.collection('incidents').orderBy('reportedAt', descending: true);
      
      if (userId != null) {
        query = query.where('reporterId', isEqualTo: userId);
      }
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }
      
      return query.snapshots().map((snapshot) {
        final incidents = snapshot.docs.map((doc) => _incidentFromMap(doc)).toList();
        return Right<Failure, List<Incident>>(incidents);
      });
    } catch (e) {
      return Stream.value(Left(UnknownFailure(e.toString())));
    }
  }

  // Helper methods
  Map<String, dynamic> _incidentToMap(Incident incident) {
    return {
      'id': incident.id,
      'reporterId': incident.reporterId,
      'reporterType': incident.reporterType,
      'jobId': incident.jobId,
      'subjectId': incident.subjectId,
      'type': incident.type.name,
      'description': incident.description,
      'audioUrl': incident.audioUrl,
      'imageUrl': incident.imageUrl,
      'reportedAt': Timestamp.fromDate(incident.reportedAt),
      'status': incident.status.name,
      'resolvedBy': incident.resolvedBy,
      'resolvedAt': incident.resolvedAt != null 
          ? Timestamp.fromDate(incident.resolvedAt!) 
          : null,
      'resolution': incident.resolution,
    };
  }

  Incident _incidentFromMap(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Incident(
      id: doc.id,
      reporterId: data['reporterId'] ?? '',
      reporterType: data['reporterType'] ?? '',
      jobId: data['jobId'],
      subjectId: data['subjectId'],
      type: IncidentType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => IncidentType.other,
      ),
      description: data['description'] ?? '',
      audioUrl: data['audioUrl'],
      imageUrl: data['imageUrl'],
      reportedAt: (data['reportedAt'] as Timestamp).toDate(),
      status: IncidentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => IncidentStatus.pending,
      ),
      resolvedBy: data['resolvedBy'],
      resolvedAt: data['resolvedAt'] != null 
          ? (data['resolvedAt'] as Timestamp).toDate() 
          : null,
      resolution: data['resolution'],
    );
  }
}
