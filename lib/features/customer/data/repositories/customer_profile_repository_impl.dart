import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/customer_profile.dart';
import '../../domain/repositories/customer_profile_repository.dart';

class CustomerProfileRepositoryImpl implements CustomerProfileRepository {
  final FirebaseFirestore _firestore;

  CustomerProfileRepositoryImpl(this._firestore);

  CollectionReference get _col => _firestore.collection('customer_profiles');

  @override
  Future<Either<Failure, CustomerProfile>> getProfile(String userId) async {
    try {
      final doc = await _col.doc(userId).get();
      if (!doc.exists) return Left(ServerFailure('Profile not found'));
      return Right(CustomerProfile.fromFirestore(doc));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CustomerProfile>> createProfile(
    CustomerProfile profile,
  ) async {
    try {
      await _col.doc(profile.userId).set(profile.toJson());
      return Right(profile);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CustomerProfile>> updateProfile(
    CustomerProfile profile,
  ) async {
    try {
      final data = profile.toJson()
        ..['updatedAt'] = FieldValue.serverTimestamp();
      await _col.doc(profile.userId).update(data);
      return Right(profile);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CustomerProfile>>> getAllCustomers() async {
    try {
      final snap = await _col.orderBy('createdAt', descending: true).get();
      final profiles = snap.docs.map(CustomerProfile.fromFirestore).toList();
      return Right(profiles);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> suspendCustomer(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': 'suspended',
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> reactivateCustomer(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': 'active',
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<CustomerProfile> watchProfile(String userId) {
    return _col.doc(userId).snapshots().map(CustomerProfile.fromFirestore);
  }
}
