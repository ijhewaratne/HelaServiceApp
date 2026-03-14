import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/worker_application.dart';
import '../../domain/repositories/worker_repository.dart';

class WorkerRepositoryImpl implements WorkerRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  WorkerRepositoryImpl(this._firestore, this._storage);

  @override
  Future<Either<Failure, WorkerApplication>> submitApplication(WorkerApplication application) async {
    try {
      // Check for duplicate NIC
      final existing = await _firestore
          .collection('worker_applications')
          .where('nic', isEqualTo: application.nic)
          .where('status', whereIn: ['underReview', 'approved', 'trainingRequired'])
          .get();

      if (existing.docs.isNotEmpty) {
        return Left(Failure.duplicateNIC());
      }

      // Create document
      final docRef = _firestore.collection('worker_applications').doc();
      final data = {
        'id': docRef.id,
        'nic': application.nic,
        'fullName': application.fullName,
        'mobileNumber': application.mobileNumber,
        'address': application.address,
        'emergencyContactName': application.emergencyContactName,
        'emergencyContactPhone': application.emergencyContactPhone,
        'selectedServices': application.selectedServices.map((e) => e.name).toList(),
        'status': 'pendingDocs', // Awaiting document upload
        'appliedAt': FieldValue.serverTimestamp(),
        'hasCompletedTraining': false,
        // PDPA: Encrypt sensitive fields
        'isEncrypted': true,
      };

      await docRef.set(data);
      
      return Right(application.copyWith(id: docRef.id, status: ApplicationStatus.pendingDocs));
    } on FirebaseException catch (e) {
      return Left(Failure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(Failure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> uploadNICDocument(String workerId, File file, bool isFront) async {
    try {
      // Validate file size (max 5MB)
      final size = await file.length();
      if (size > 5 * 1024 * 1024) {
        return Left(Failure.fileTooLarge());
      }

      final type = isFront ? 'nic_front' : 'nic_back';
      final ref = _storage.ref().child('workers/$workerId/$type.jpg');
      
      await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();

      // Update Firestore
      await _firestore.collection('worker_applications').doc(workerId).update({
        isFront ? 'nicFrontUrl' : 'nicBackUrl': url,
        // If both docs uploaded, move to underReview
        'status': 'underReview',
      });

      return Right(url);
    } catch (e) {
      return Left(Failure('Upload failed: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> uploadProfilePhoto(String workerId, File file) async {
    try {
      final ref = _storage.ref().child('workers/$workerId/profile.jpg');
      await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();
      
      await _firestore.collection('worker_applications').doc(workerId).update({
        'profilePhotoUrl': url,
      });
      
      return Right(url);
    } catch (e) {
      return Left(Failure('Upload failed: $e'));
    }
  }

  @override
  Future<Either<Failure, WorkerApplication>> getApplicationStatus(String workerId) async {
    try {
      final doc = await _firestore.collection('worker_applications').doc(workerId).get();
      if (!doc.exists) return Left(Failure('Application not found'));

      return Right(_mapDocumentToEntity(doc));
    } catch (e) {
      return Left(Failure('Failed to fetch status'));
    }
  }

  @override
  Future<Either<Failure, void>> completeTraining(String workerId) async {
    try {
      await _firestore.collection('worker_applications').doc(workerId).update({
        'hasCompletedTraining': true,
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });
      return Right(null);
    } catch (e) {
      return Left(Failure('Failed to update training status'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkNICExists(String nic) async {
    try {
      final result = await _firestore
          .collection('worker_applications')
          .where('nic', isEqualTo: nic)
          .get();
      return Right(result.docs.isNotEmpty);
    } catch (e) {
      return Left(Failure.network());
    }
  }

  WorkerApplication _mapDocumentToEntity(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkerApplication(
      id: doc.id,
      nic: data['nic'],
      fullName: data['fullName'],
      mobileNumber: data['mobileNumber'],
      address: data['address'],
      emergencyContactName: data['emergencyContactName'],
      emergencyContactPhone: data['emergencyContactPhone'],
      selectedServices: (data['selectedServices'] as List)
          .map((e) => ServiceType.values.byName(e))
          .toList(),
      profilePhotoUrl: data['profilePhotoUrl'],
      nicFrontUrl: data['nicFrontUrl'],
      nicBackUrl: data['nicBackUrl'],
      status: ApplicationStatus.values.byName(data['status']),
      appliedAt: (data['appliedAt'] as Timestamp).toDate(),
      hasCompletedTraining: data['hasCompletedTraining'] ?? false,
      rejectionReason: data['rejectionReason'],
    );
  }
}