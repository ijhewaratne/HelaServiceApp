import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';

/// Implementation of BookingRepository using Firebase Firestore and Auth
class BookingRepositoryImpl implements BookingRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  BookingRepositoryImpl(this._firestore, this._firebaseAuth);

  @override
  Future<Either<Failure, Booking>> createBooking(
    Booking booking,
  ) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        return Left(GenericFailure('User not authenticated'));
      }

      final docRef = _firestore.collection('bookings').doc();
      final bookingData = booking.copyWith(
        id: docRef.id,
        customerId: currentUser.uid,
      );

      await docRef.set(bookingData.toJson());
      return Right(bookingData);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, Booking>> getBooking(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (!doc.exists) {
        return Left(GenericFailure('Booking not found'));
      }
      return Right(Booking.fromFirestore(doc));
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, Booking>> updateBooking(
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
      return Right(Booking.fromFirestore(doc));
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
  Future<Either<Failure, List<Booking>>> getCustomerBookings(
    String customerId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      return Right(querySnapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Booking>>> getWorkerBookings(
    String workerId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('workerId', isEqualTo: workerId)
          .orderBy('createdAt', descending: true)
          .get();

      return Right(querySnapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, Booking?>> getActiveBookingForCustomer(
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
      return Right(Booking.fromFirestore(querySnapshot.docs.first));
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, Booking?>> getActiveBookingForWorker(
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
      return Right(Booking.fromFirestore(querySnapshot.docs.first));
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, Booking>> assignWorker(
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

      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      return Right(Booking.fromFirestore(doc));
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, Booking>> updateBookingStatus(
    String bookingId,
    BookingStatus status, {
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add status-specific timestamps
      switch (status) {
        case BookingStatus.inProgress:
          updateData['startedAt'] = FieldValue.serverTimestamp();
          break;
        case BookingStatus.completed:
          updateData['completedAt'] = FieldValue.serverTimestamp();
          break;
        case BookingStatus.cancelled:
          updateData['cancelledAt'] = FieldValue.serverTimestamp();
          break;
        default:
          break;
      }

      if (additionalData != null) {
        updateData.addAll(additionalData);
      }

      await _firestore.collection('bookings').doc(bookingId).update(updateData);

      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      return Right(Booking.fromFirestore(doc));
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Stream<Either<Failure, Booking>> watchBooking(String bookingId) {
    return _firestore
        .collection('bookings')
        .doc(bookingId)
        .snapshots()
        .map<Either<Failure, Booking>>((snapshot) {
      if (!snapshot.exists) {
        return Left(GenericFailure('Booking not found'));
      }
      return Right(Booking.fromFirestore(snapshot));
    }).handleError((Object e) {
      // Convert error to Left value
      return Left<Failure, Booking>(GenericFailure('Stream error: $e'));
    });
  }
}
