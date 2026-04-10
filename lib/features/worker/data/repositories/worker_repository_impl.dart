import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/worker.dart';
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
        return Left(NotFoundFailure('Worker not found'));
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
      
      // Also update worker_locations collection for geohash queries
      await _firestore.collection('worker_locations').doc(workerId).set({
        'status': isOnline ? 'online' : 'offline',
        'updatedAt': FieldValue.serverTimestamp(),
        if (isOnline && lat != null && lng != null) ...{
          'lat': lat,
          'lng': lng,
        },
      }, SetOptions(merge: true));
      
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

  Worker _workerFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Worker(
      id: doc.id,
      nic: data['nic'],
      fullName: data['fullName'],
      mobileNumber: data['mobileNumber'],
      address: data['address'],
      emergencyContactName: data['emergencyContactName'],
      emergencyContactPhone: data['emergencyContactPhone'],
      services: (data['services'] as List)
        .map((s) => ServiceType.values.byName(s))
        .toList(),
      profilePhotoUrl: data['profilePhotoUrl'],
      nicFrontUrl: data['nicFrontUrl'],
      nicBackUrl: data['nicBackUrl'],
      status: WorkerStatus.values.byName(data['status']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      approvedAt: data['approvedAt'] != null 
        ? (data['approvedAt'] as Timestamp).toDate() 
        : null,
      isOnline: data['isOnline'] ?? false,
      currentLat: data['currentLat']?.toDouble(),
      currentLng: data['currentLng']?.toDouble(),
      homeLat: data['homeLat']?.toDouble(),
      homeLng: data['homeLng']?.toDouble(),
      rating: data['rating']?.toDouble() ?? 4.0,
      totalJobs: data['totalJobs'] ?? 0,
      lastJobCompletedAt: data['lastJobCompletedAt'] != null
        ? (data['lastJobCompletedAt'] as Timestamp).toDate()
        : null,
      hasAcceptedContract: data['hasAcceptedContract'] ?? false,
    );
  }
}
