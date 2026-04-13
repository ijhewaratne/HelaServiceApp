import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/repositories/customer_repository.dart';

/// Implementation of CustomerRepository using Firebase Firestore
class CustomerRepositoryImpl implements CustomerRepository {
  final FirebaseFirestore _firestore;

  CustomerRepositoryImpl(this._firestore);

  @override
  Future<Either<Failure, Map<String, dynamic>>> getCustomerProfile(String customerId) async {
    try {
      final doc = await _firestore.collection('customers').doc(customerId).get();
      if (!doc.exists) {
        return Left(GenericFailure('Customer not found'));
      }
      return Right(doc.data()!);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> createCustomerProfile(
    String customerId,
    Map<String, dynamic> data,
  ) async {
    try {
      final customerData = {
        ...data,
        'id': customerId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await _firestore.collection('customers').doc(customerId).set(customerData);
      return Right(customerData);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> updateCustomerProfile(
    String customerId,
    Map<String, dynamic> data,
  ) async {
    try {
      final updateData = {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await _firestore.collection('customers').doc(customerId).update(updateData);
      
      // Get updated profile
      final doc = await _firestore.collection('customers').doc(customerId).get();
      return Right(doc.data()!);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomerProfile(String customerId) async {
    try {
      await _firestore.collection('customers').doc(customerId).delete();
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getCustomerBookings(
    String customerId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return Right(querySnapshot.docs.map((doc) => doc.data()).toList());
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getSavedAddresses(
    String customerId,
  ) async {
    try {
      final doc = await _firestore.collection('customers').doc(customerId).get();
      if (!doc.exists) {
        return const Right([]);
      }
      
      final data = doc.data();
      final addresses = (data?['savedAddresses'] as List<dynamic>?) ?? [];
      return Right(addresses.cast<Map<String, dynamic>>());
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> addSavedAddress(
    String customerId,
    Map<String, dynamic> address,
  ) async {
    try {
      final addressWithId = {
        ...address,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      
      await _firestore.collection('customers').doc(customerId).update({
        'savedAddresses': FieldValue.arrayUnion([addressWithId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return Right(addressWithId);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> updateSavedAddress(
    String customerId,
    String addressId,
    Map<String, dynamic> address,
  ) async {
    try {
      // Get current addresses
      final doc = await _firestore.collection('customers').doc(customerId).get();
      if (!doc.exists) {
        return Left(GenericFailure('Customer not found'));
      }
      
      final data = doc.data();
      final addresses = List<Map<String, dynamic>>.from(
        (data?['savedAddresses'] as List<dynamic>?) ?? [],
      );
      
      // Find and update the address
      final index = addresses.indexWhere((a) => a['id'] == addressId);
      if (index == -1) {
        return Left(GenericFailure('Address not found'));
      }
      
      addresses[index] = {...address, 'id': addressId};
      
      await _firestore.collection('customers').doc(customerId).update({
        'savedAddresses': addresses,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return Right(addresses[index]);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSavedAddress(
    String customerId,
    String addressId,
  ) async {
    try {
      // Get current addresses
      final doc = await _firestore.collection('customers').doc(customerId).get();
      if (!doc.exists) {
        return Left(GenericFailure('Customer not found'));
      }
      
      final data = doc.data();
      final addresses = List<Map<String, dynamic>>.from(
        (data?['savedAddresses'] as List<dynamic>?) ?? [],
      );
      
      // Remove the address
      final addressToRemove = addresses.firstWhere(
        (a) => a['id'] == addressId,
        orElse: () => {},
      );
      
      if (addressToRemove.isEmpty) {
        return Left(GenericFailure('Address not found'));
      }
      
      await _firestore.collection('customers').doc(customerId).update({
        'savedAddresses': FieldValue.arrayRemove([addressToRemove]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }
}
