import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/repositories/booking_repository.dart';

/// Implementation of BookingRepository using Firebase Firestore and Auth
class BookingRepositoryImpl implements BookingRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  BookingRepositoryImpl(this._firestore, this._firebaseAuth);

  @override
  Future<Either<Failure, Map<String, dynamic>>> createBooking(
    Map<String, dynamic> bookingData,
  ) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        return Left(GenericFailure('User not authenticated'));
      }

      final docRef = _firestore.collection('bookings').doc();
      final data = {
        ...bookingData,
        'id': docRef.id,
        'customerId': currentUser.uid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(data);
      return Right(data);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getBooking(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (!doc.exists) {
        return Left(GenericFailure('Booking not found'));
      }
      return Right(doc.data()!);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> updateBooking(
    String bookingId,
    Map<String, dynamic> data,
  ) async {
    try {
      final updateData = {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('bookings').doc(bookingId).update(updateData);

      // Get updated booking
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      return Right(doc.data()!);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelBooking(
    String bookingId, {
    String? reason,
  }) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'cancelled',
        'cancellationReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
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
  Future<Either<Failure, List<Map<String, dynamic>>>> getWorkerBookings(
    String workerId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('workerId', isEqualTo: workerId)
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
  Future<Either<Failure, Map<String, dynamic>?>> getActiveBookingForCustomer(
    String customerId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('customerId', isEqualTo: customerId)
          .where('status', whereIn: ['pending', 'assigned', 'inProgress'])
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return const Right(null);
      }
      return Right(querySnapshot.docs.first.data());
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>?>> getActiveBookingForWorker(
    String workerId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('workerId', isEqualTo: workerId)
          .where('status', whereIn: ['assigned', 'inProgress'])
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return const Right(null);
      }
      return Right(querySnapshot.docs.first.data());
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> assignWorker(
    String bookingId,
    String workerId,
  ) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'workerId': workerId,
        'status': 'assigned',
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      return Right(doc.data()!);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> updateBookingStatus(
    String bookingId,
    String status, {
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add status-specific timestamps
      switch (status) {
        case 'inProgress':
          updateData['startedAt'] = FieldValue.serverTimestamp();
          break;
        case 'completed':
          updateData['completedAt'] = FieldValue.serverTimestamp();
          break;
        case 'cancelled':
          updateData['cancelledAt'] = FieldValue.serverTimestamp();
          break;
      }

      if (additionalData != null) {
        updateData.addAll(additionalData);
      }

      await _firestore.collection('bookings').doc(bookingId).update(updateData);

      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      return Right(doc.data()!);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Stream<Either<Failure, Map<String, dynamic>>> watchBooking(String bookingId) {
    return _firestore
        .collection('bookings')
        .doc(bookingId)
        .snapshots()
        .map<Either<Failure, Map<String, dynamic>>>((snapshot) {
      if (!snapshot.exists) {
        return Left(GenericFailure('Booking not found'));
      }
      return Right(snapshot.data()!);
    }).handleError((Object e) {
      // Convert error to Left value
      return Left<Failure, Map<String, dynamic>>(GenericFailure('Stream error: $e'));
    });
  }
}
