import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/feedback.dart';
import '../../domain/repositories/feedback_repository.dart';
import '../models/feedback_model.dart';

/// Firebase implementation of FeedbackRepository
class FeedbackRepositoryImpl implements FeedbackRepository {
  final FirebaseFirestore _firestore;

  FeedbackRepositoryImpl(this._firestore);

  @override
  Future<Either<Failure, Feedback>> submitFeedback({
    required String userId,
    required String userType,
    required FeedbackCategory category,
    required String message,
    int? rating,
    List<String>? attachments,
  }) async {
    try {
      final docRef = _firestore.collection('feedback').doc();
      
      final feedback = FeedbackModel(
        id: docRef.id,
        userId: userId,
        userType: userType,
        category: category.name,
        message: message,
        rating: rating,
        attachments: attachments,
        createdAt: DateTime.now(),
        isResolved: false,
      );

      await docRef.set(feedback.toFirestore());

      return Right(feedback.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Feedback>>> getUserFeedback(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('feedback')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final feedback = querySnapshot.docs
          .map((doc) => FeedbackModel.fromFirestore(doc).toEntity())
          .toList();

      return Right(feedback);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Feedback>> getFeedbackById(String feedbackId) async {
    try {
      final doc = await _firestore.collection('feedback').doc(feedbackId).get();

      if (!doc.exists) {
        return Left(NotFoundGenericFailure('Feedback not found'));
      }

      return Right(FeedbackModel.fromFirestore(doc).toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Feedback>> updateFeedback({
    required String feedbackId,
    bool? isResolved,
    String? adminResponse,
  }) async {
    try {
      final docRef = _firestore.collection('feedback').doc(feedbackId);
      
      final updates = <String, dynamic>{};
      if (isResolved != null) {
        updates['isResolved'] = isResolved;
        if (isResolved) {
          updates['resolvedAt'] = Timestamp.now();
        }
      }
      if (adminResponse != null) {
        updates['adminResponse'] = adminResponse;
      }

      await docRef.update(updates);

      final updatedDoc = await docRef.get();
      return Right(FeedbackModel.fromFirestore(updatedDoc).toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFeedback(String feedbackId) async {
    try {
      await _firestore.collection('feedback').doc(feedbackId).delete();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<Feedback>>> watchUserFeedback(String userId) {
    return _firestore
        .collection('feedback')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      try {
        final feedback = snapshot.docs
            .map((doc) => FeedbackModel.fromFirestore(doc).toEntity())
            .toList();
        return Right(feedback);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    });
  }
}
