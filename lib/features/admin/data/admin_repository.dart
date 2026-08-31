import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../worker/domain/entities/worker_profile.dart';
import '../../customer/domain/booking.dart';
import '../../incident/domain/entities/incident.dart' as incident_entity;

/// A blue-tier upgrade request submitted by a worker.
class BlueTierVerification {
  final String workerId;
  final String status;
  final DateTime submittedAt;
  final String? workerName;
  final List<ReferenceContact> references;
  final String? policeClearanceFrontUrl;

  const BlueTierVerification({
    required this.workerId,
    required this.status,
    required this.submittedAt,
    this.workerName,
    required this.references,
    this.policeClearanceFrontUrl,
  });
}

class ReferenceContact {
  final int index;
  final String name;
  final String phone;
  final String relation;
  final String
  verificationStatus; // pending / called_confirmed / called_refused / no_answer
  final String? callNotes;

  const ReferenceContact({
    required this.index,
    required this.name,
    required this.phone,
    required this.relation,
    required this.verificationStatus,
    this.callNotes,
  });
}

class AdminRepository {
  final FirebaseFirestore _firestore;

  AdminRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Either<Failure, List<BlueTierVerification>>>
  getBlueTierPendingVerifications() async {
    try {
      final snap = await _firestore
          .collection('worker_verifications')
          .where('requestedTier', isEqualTo: 'blue')
          .where('status', isEqualTo: 'pending_review')
          .orderBy('submittedAt', descending: false)
          .get();

      final verifications = snap.docs.map((doc) {
        final d = doc.data();
        final refs = (d['references'] as List<dynamic>? ?? [])
            .asMap()
            .entries
            .map((e) {
              final r = e.value as Map<String, dynamic>;
              return ReferenceContact(
                index: e.key,
                name: r['name'] as String? ?? '',
                phone: r['phone'] as String? ?? '',
                relation: r['relation'] as String? ?? '',
                verificationStatus:
                    r['verificationStatus'] as String? ?? 'pending',
                callNotes: r['callNotes'] as String?,
              );
            })
            .toList();
        return BlueTierVerification(
          workerId: doc.id,
          status: d['status'] as String? ?? 'pending_review',
          submittedAt:
              (d['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          workerName: d['workerName'] as String?,
          references: refs,
          policeClearanceFrontUrl:
              (d['policeClearance'] as Map<String, dynamic>?)?['frontUrl']
                  as String?,
        );
      }).toList();

      return Right(verifications);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  Future<Either<Failure, void>> logReferenceCallOutcome({
    required String workerId,
    required int referenceIndex,
    required String outcome, // called_confirmed / called_refused / no_answer
    required String notes,
  }) async {
    try {
      final doc = await _firestore
          .collection('worker_verifications')
          .doc(workerId)
          .get();
      if (!doc.exists) {
        return const Left(NotFoundFailure('Worker verification not found'));
      }

      final refs = List<Map<String, dynamic>>.from(
        doc.data()!['references'] as List,
      );
      if (referenceIndex < refs.length) {
        refs[referenceIndex] = {
          ...refs[referenceIndex],
          'verificationStatus': outcome,
          'callNotes': notes,
          'calledAt': FieldValue.serverTimestamp(),
        };
      }
      await _firestore.collection('worker_verifications').doc(workerId).update({
        'references': refs,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  Future<Either<Failure, void>> approveBlueTierUpgrade(String workerId) async {
    try {
      final batch = _firestore.batch();
      batch
          .update(_firestore.collection('worker_verifications').doc(workerId), {
            'status': 'approved',
            'approvedAt': FieldValue.serverTimestamp(),
            'currentTier': 'blue',
          });
      batch.update(_firestore.collection('workers').doc(workerId), {
        'verificationTier': 'blue',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  Future<Either<Failure, void>> rejectBlueTierUpgrade(
    String workerId,
    String reason,
  ) async {
    try {
      await _firestore.collection('worker_verifications').doc(workerId).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('workers').doc(workerId).update({
        'verificationStatus': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  Future<Either<Failure, List<WorkerProfile>>> getPendingWorkers() async {
    try {
      final snap = await _firestore
          .collection('workers')
          .where(
            'verificationStatus',
            whereIn: ['pending_review', 'documents_submitted'],
          )
          .orderBy('createdAt', descending: false)
          .limit(50)
          .get();

      final workers = snap.docs.map((doc) {
        final d = doc.data();
        return WorkerProfile(
          uid: doc.id,
          nic: d['nic'] as String? ?? '',
          name: d['fullName'] as String? ?? d['name'] as String? ?? 'Worker',
          phone: d['mobileNumber'] as String? ?? d['phone'] as String? ?? '',
          district: d['district'] as String? ?? 'Colombo',
          serviceTypes:
              (d['services'] as List<dynamic>?)
                  ?.map((s) => s as String)
                  .toList() ??
              [],
          languages:
              (d['languages'] as List<dynamic>?)
                  ?.map((l) => l as String)
                  .toList() ??
              ['Sinhala'],
          verificationStatus: d['verificationStatus'] as String? ?? 'pending',
          rating: (d['rating'] as num?)?.toDouble() ?? 0.0,
          completedJobs: d['totalJobs'] as int? ?? 0,
          isAvailable: d['isOnline'] as bool? ?? false,
          availabilityMode: 'full_time',
        );
      }).toList();

      return Right(workers);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  Future<Either<Failure, void>> updateWorkerStatus(
    String workerId,
    String status,
  ) async {
    try {
      await _firestore.collection('workers').doc(workerId).update({
        'verificationStatus': status,
        if (status == 'approved') 'isVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  Future<Either<Failure, List<Booking>>> getActiveBookings() async {
    try {
      final snap = await _firestore
          .collection('bookings')
          .where(
            'status',
            whereIn: [
              'pending',
              'confirmed',
              'workerAssigned',
              'workerEnRoute',
              'workerArrived',
              'inProgress',
            ],
          )
          .orderBy('createdAt', descending: true)
          .limit(30)
          .get();

      final bookings = snap.docs.map((doc) {
        final d = doc.data();
        // Map new Booking schema → legacy admin Booking model
        final scheduledDate = d['scheduledDate'];
        String bookingDate = '';
        if (scheduledDate is Timestamp) {
          final dt = scheduledDate.toDate();
          bookingDate =
              '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        } else if (scheduledDate is String) {
          bookingDate = scheduledDate;
        }

        final addr = d['address'] as Map<String, dynamic>?;
        final addressText = addr != null
            ? '${addr['houseNumber'] ?? ''}, ${addr['city'] ?? ''}'
            : d['addressText'] as String? ?? '-';

        return Booking(
          bookingId: doc.id,
          customerId: d['customerId'] as String? ?? '',
          workerId: d['workerId'] as String?,
          serviceType: d['serviceType'] as String? ?? 'cleaning',
          packageType: '${d['durationHours'] ?? 4}_hours',
          bookingDate: bookingDate,
          startTime: d['scheduledTime'] as String? ?? '09:00',
          durationHours: d['durationHours'] as int? ?? 4,
          addressText: addressText,
          addressLat: addr != null
              ? (addr['latitude'] as num?)?.toDouble() ?? 6.89
              : 6.89,
          addressLng: addr != null
              ? (addr['longitude'] as num?)?.toDouble() ?? 79.86
              : 79.86,
          specialNotes: d['notes'] as String? ?? '',
          status: d['status'] as String? ?? 'pending',
          price: (d['estimatedPrice'] as num?)?.toDouble() ?? 0.0,
          paymentStatus: d['paymentStatus'] as String? ?? 'unpaid',
          createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();

      return Right(bookings);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  Future<Either<Failure, void>> assignWorkerToBooking(
    String bookingId,
    String workerId,
  ) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'workerId': workerId,
        'status': 'workerAssigned',
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Also update job_request so dispatch knows this is taken
      await _firestore.collection('job_requests').doc(bookingId).set({
        'assignedWorkerId': workerId,
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  Future<Either<Failure, List<incident_entity.Incident>>>
  getOpenIncidents() async {
    try {
      final unresolvedStatuses = [
        incident_entity.IncidentStatus.pending.name,
        incident_entity.IncidentStatus.investigating.name,
        incident_entity.IncidentStatus.escalated.name,
      ];

      final snap = await _firestore
          .collection('incidents')
          .where('status', whereIn: unresolvedStatuses)
          .orderBy('reportedAt', descending: true)
          .limit(50)
          .get();

      return Right(snap.docs.map(_mapIncident).toList());
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  Future<Either<Failure, void>> updateIncidentStatus({
    required String incidentId,
    required incident_entity.IncidentStatus status,
    String? resolution,
    String? resolvedBy,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (resolution != null && resolution.trim().isNotEmpty) {
        updateData['resolution'] = resolution.trim();
      }
      if (resolvedBy != null && resolvedBy.isNotEmpty) {
        updateData['resolvedBy'] = resolvedBy;
      }
      if (status == incident_entity.IncidentStatus.resolved) {
        updateData['resolvedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection('incidents')
          .doc(incidentId)
          .update(updateData);
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  incident_entity.Incident _mapIncident(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    return incident_entity.Incident(
      id: doc.id,
      reporterId:
          data['reporterId'] as String? ?? data['reportedBy'] as String? ?? '',
      reporterType: data['reporterType'] as String? ?? 'customer',
      jobId: data['jobId'] as String? ?? data['bookingId'] as String?,
      subjectId: data['subjectId'] as String?,
      type: _parseIncidentType(data['type'] as String?),
      description: data['description'] as String? ?? '',
      audioUrl: data['audioUrl'] as String?,
      imageUrl: data['imageUrl'] as String?,
      reportedAt: _asDateTime(data['reportedAt'] ?? data['createdAt']),
      status: _parseIncidentStatus(data['status'] as String?),
      resolvedBy: data['resolvedBy'] as String?,
      resolvedAt: _asNullableDateTime(data['resolvedAt']),
      resolution: data['resolution'] as String?,
    );
  }

  incident_entity.IncidentType _parseIncidentType(String? rawType) {
    return incident_entity.IncidentType.values.firstWhere(
      (value) => value.name == rawType,
      orElse: () => incident_entity.IncidentType.other,
    );
  }

  incident_entity.IncidentStatus _parseIncidentStatus(String? rawStatus) {
    switch (rawStatus) {
      case 'investigating':
        return incident_entity.IncidentStatus.investigating;
      case 'resolved':
        return incident_entity.IncidentStatus.resolved;
      case 'escalated':
        return incident_entity.IncidentStatus.escalated;
      case 'open':
      case 'pending':
      default:
        return incident_entity.IncidentStatus.pending;
    }
  }

  DateTime _asDateTime(dynamic value) {
    return _asNullableDateTime(value) ?? DateTime.now();
  }

  DateTime? _asNullableDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
