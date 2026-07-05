import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/geohash_helper.dart';
import '../../domain/entities/worker.dart';
import '../../domain/entities/worker_application.dart' as app;
import '../../domain/entities/worker_profile.dart';
import '../../domain/entities/worker_document.dart';
import '../../domain/repositories/worker_repository.dart';

class WorkerRepositoryImpl implements WorkerRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  WorkerRepositoryImpl(this._firestore, this._storage);

  @override
  Future<Either<Failure, Worker>> createWorker(Worker worker) async {
    try {
      final docRef = _firestore.collection('workers').doc(worker.id);
      await docRef.set({
        'nic': worker.nic,
        'fullName': worker.fullName,
        'mobileNumber': worker.mobileNumber,
        'address': worker.address,
        'emergencyContactName': worker.emergencyContactName,
        'emergencyContactPhone': worker.emergencyContactPhone,
        'services': worker.services.map((s) => s.name).toList(),
        'status': worker.status.name,
        'createdAt': Timestamp.fromDate(worker.createdAt),
        'rating': worker.rating,
        'totalJobs': worker.totalJobs,
        'hasAcceptedContract': worker.hasAcceptedContract,
      });
      return Right(worker);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Worker>> getWorker(String workerId) async {
    try {
      final doc = await _firestore.collection('workers').doc(workerId).get();
      if (!doc.exists) {
        return const Left(NotFoundFailure('Worker not found'));
      }
      return Right(_workerFromDoc(doc));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadNICDocument({
    required String workerId,
    required File file,
    required bool isFront,
  }) async {
    try {
      final ref = _storage
        .ref()
        .child('workers')
        .child(workerId)
        .child(isFront ? 'nic_front.jpg' : 'nic_back.jpg');
      
      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      final url = await uploadTask.ref.getDownloadURL();
      
      // Update worker document
      await _firestore.collection('workers').doc(workerId).update({
        isFront ? 'nicFrontUrl' : 'nicBackUrl': url,
      });
      
      return Right(url);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadProfilePhoto({
    required String workerId,
    required File file,
  }) async {
    try {
      final ref = _storage
        .ref()
        .child('workers')
        .child(workerId)
        .child('profile.jpg');
      
      final uploadTask = await ref.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();
      
      await _firestore.collection('workers').doc(workerId).update({
        'profilePhotoUrl': url,
      });
      
      return Right(url);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateOnlineStatus({
    required String workerId,
    required bool isOnline,
    double? lat,
    double? lng,
  }) async {
    try {
      final data = <String, dynamic>{
        'isOnline': isOnline,
        'lastStatusChange': FieldValue.serverTimestamp(),
      };

      if (isOnline && lat != null && lng != null) {
        data['currentLat'] = lat;
        data['currentLng'] = lng;
      }

      await _firestore.collection('workers').doc(workerId).update(data);

      // Build the worker_locations document. When going online, include the
      // dispatch contract fields (skills, isVerified, homeLocation) so the
      // Cloud Function matching query never fails with missing fields.
      final locationDoc = <String, dynamic>{
        'status': isOnline ? 'online' : 'offline',
        'updatedAt': FieldValue.serverTimestamp(),
        if (isOnline && lat != null && lng != null) ...{
          'lat': lat,
          'lng': lng,
          'location': GeoPoint(lat, lng),
          'geohash': GeohashHelper.encode(lat, lng),
        },
      };

      if (isOnline) {
        final workerDoc =
            await _firestore.collection('workers').doc(workerId).get();
        if (workerDoc.exists) {
          final d = workerDoc.data()!;
          final services = (d['services'] as List<dynamic>?)
                  ?.map((s) => s as String)
                  .toList() ??
              [];
          final status = d['status'] as String? ?? 'pending';
          final homeLat = (d['homeLat'] as num?)?.toDouble();
          final homeLng = (d['homeLng'] as num?)?.toDouble();

          locationDoc['skills'] = services;
          locationDoc['isVerified'] = status == 'approved';
          locationDoc['rating'] = (d['rating'] as num?)?.toDouble() ?? 4.0;
          final lastJobCompletedAt = d['lastJobCompletedAt'];
          if (lastJobCompletedAt is Timestamp) {
            locationDoc['lastJobCompletedAt'] = lastJobCompletedAt;
          }
          if (homeLat != null && homeLng != null) {
            locationDoc['homeLocation'] = {
              'latitude': homeLat,
              'longitude': homeLng,
            };
          }
        }
      }

      await _firestore
          .collection('worker_locations')
          .doc(workerId)
          .set(locationDoc, SetOptions(merge: true));

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> acceptContract(String workerId) async {
    try {
      await _firestore.collection('workers').doc(workerId).update({
        'hasAcceptedContract': true,
        'contractAcceptedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ==================== ONBOARDING IMPLEMENTATIONS ====================

  @override
  Future<Either<Failure, bool>> checkNICExists(String nic) async {
    try {
      final query = await _firestore
        .collection('workers')
        .where('nic', isEqualTo: nic)
        .limit(1)
        .get();
      
      return Right(query.docs.isNotEmpty);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, app.WorkerApplication>> submitApplication(app.WorkerApplication application) async {
    try {
      String? workerId;
      try {
        workerId = FirebaseAuth.instance.currentUser?.uid;
      } catch (_) {
        workerId = null;
      }
      final applications = _firestore.collection('worker_applications');
      final docRef =
          workerId == null ? applications.doc() : applications.doc(workerId);
      final data = application.copyWith(id: docRef.id).toJson();
      await docRef.set(data);
      return Right(application.copyWith(id: docRef.id));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, app.WorkerApplication>> getApplicationStatus(String workerId) async {
    try {
      final doc = await _firestore
        .collection('worker_applications')
        .doc(workerId)
        .get();
      
      if (!doc.exists) {
        return const Left(NotFoundFailure('Application not found'));
      }
      
      return Right(app.WorkerApplication.fromJson(doc.data()!));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> completeTraining(String workerId) async {
    try {
      // Update worker document
      await _firestore.collection('workers').doc(workerId).update({
        'hasCompletedTraining': true,
        'trainingCompletedAt': FieldValue.serverTimestamp(),
      });
      
      final applicationRef =
          _firestore.collection('worker_applications').doc(workerId);
      final applicationDoc = await applicationRef.get();
      if (applicationDoc.exists) {
        await applicationRef.update({
          'hasCompletedTraining': true,
          'trainingCompletedAt': FieldValue.serverTimestamp(),
        });
      }
      
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLocation({
    required String workerId,
    required double lat,
    required double lng,
  }) async {
    try {
      await _firestore.collection('workers').doc(workerId).update({
        'currentLat': lat,
        'currentLng': lng,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
      
      // Also update worker_locations for matching
      await _firestore.collection('worker_locations').doc(workerId).set({
        'lat': lat,
        'lng': lng,
        'location': GeoPoint(lat, lng),
        'geohash': GeohashHelper.encode(lat, lng),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ==================== HELPER METHODS ====================

  Worker _workerFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Worker(
      id: doc.id,
      nic: (data['nic'] as String?) ?? '',
      fullName: (data['fullName'] as String?) ?? '',
      mobileNumber: (data['mobileNumber'] as String?) ?? '',
      address: (data['address'] as String?) ?? '',
      emergencyContactName: (data['emergencyContactName'] as String?) ?? '',
      emergencyContactPhone: (data['emergencyContactPhone'] as String?) ?? '',
      services: (data['services'] as List<dynamic>?)
        ?.map((s) => ServiceType.values.byName(s as String))
        .toList() ?? [],
      profilePhotoUrl: data['profilePhotoUrl'] as String?,
      nicFrontUrl: data['nicFrontUrl'] as String?,
      nicBackUrl: data['nicBackUrl'] as String?,
      status: WorkerStatus.values.byName(data['status'] as String? ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: data['approvedAt'] != null 
        ? (data['approvedAt'] as Timestamp).toDate() 
        : null,
      isOnline: data['isOnline'] as bool? ?? false,
      currentLat: (data['currentLat'] as num?)?.toDouble(),
      currentLng: (data['currentLng'] as num?)?.toDouble(),
      homeLat: (data['homeLat'] as num?)?.toDouble(),
      homeLng: (data['homeLng'] as num?)?.toDouble(),
      rating: (data['rating'] as num?)?.toDouble() ?? 4.0,
      totalJobs: data['totalJobs'] as int? ?? 0,
      lastJobCompletedAt: data['lastJobCompletedAt'] != null
        ? (data['lastJobCompletedAt'] as Timestamp).toDate()
        : null,
      hasAcceptedContract: data['hasAcceptedContract'] as bool? ?? false,
    );
  }

  @override
  Future<WorkerProfile?> getWorkerProfile(String workerId) async {
    final result = await getWorker(workerId);
    return result.fold((_) => null, (worker) => WorkerProfile(
      uid: worker.id,
      nic: worker.nic,
      name: worker.fullName,
      phone: worker.mobileNumber,
      district: '',
      serviceTypes: worker.services.map((s) => s.name).toList(),
      languages: [],
      verificationStatus: worker.status.name,
      rating: worker.rating,
      completedJobs: worker.totalJobs,
      isAvailable: worker.isOnline,
      availabilityMode: 'part_time',
      homeLat: worker.homeLat,
      homeLng: worker.homeLng,
    ));
  }

  @override
  Future<WorkerDocument?> getWorkerDocuments(String workerId) async {
    try {
      final doc = await _firestore.collection('worker_documents').doc(workerId).get();
      if (!doc.exists) return null;
      return WorkerDocument.fromJson(doc.data()!);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateWorkerProfile(WorkerProfile profile) async {}

  @override
  Future<void> uploadDocument(String workerId, String docType, String filePath) async {}

  @override
  Future<void> updateAvailability(String workerId, bool isAvailable) async {
    await updateOnlineStatus(workerId: workerId, isOnline: isAvailable);
  }
}
