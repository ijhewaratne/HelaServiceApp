import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final FirebaseFirestore _firestore;

  ReviewRepositoryImpl(this._firestore);

  CollectionReference get _col => _firestore.collection('reviews');

  @override
  Future<Either<Failure, Review>> submitReview(Review review) async {
    try {
      final docRef = _col.doc();
      final newReview = review.copyWith(id: docRef.id);
      await docRef.set(newReview.toJson());
      // Update provider average rating
      await _updateProviderRating(review.providerId);
      return Right(newReview);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Review>>> getReviewsForProvider(
      String providerId) async {
    try {
      final snap = await _col
          .where('providerId', isEqualTo: providerId)
          .where('moderationStatus', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .get();
      return Right(
          snap.docs.map((d) => Review.fromFirestore(d)).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Review>>> getReviewsByCustomer(
      String customerId) async {
    try {
      final snap = await _col
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();
      return Right(
          snap.docs.map((d) => Review.fromFirestore(d)).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Review?>> getReviewForRequest(
      String requestId) async {
    try {
      final snap = await _col
          .where('requestId', isEqualTo: requestId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return const Right(null);
      return Right(Review.fromFirestore(snap.docs.first));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Review>>> getPendingModerationReviews() async {
    try {
      final snap = await _col
          .where('moderationStatus', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();
      return Right(
          snap.docs.map((d) => Review.fromFirestore(d)).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> approveReview(
      String reviewId, String adminId) async {
    try {
      await _col.doc(reviewId).update({
        'moderationStatus': 'approved',
        'moderatedAt': FieldValue.serverTimestamp(),
      });
      // Log admin action
      await _logAdminAction(adminId, 'approve_review', 'reviews', reviewId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> hideReview(
      String reviewId, String adminId, String note) async {
    try {
      await _col.doc(reviewId).update({
        'moderationStatus': 'hidden',
        'adminNote': note,
        'moderatedAt': FieldValue.serverTimestamp(),
      });
      await _logAdminAction(adminId, 'hide_review', 'reviews', reviewId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> flagReview(
      String reviewId, String adminId) async {
    try {
      await _col.doc(reviewId).update({
        'moderationStatus': 'flagged',
        'moderatedAt': FieldValue.serverTimestamp(),
      });
      await _logAdminAction(adminId, 'flag_review', 'reviews', reviewId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<void> _updateProviderRating(String providerId) async {
    final snap = await _col
        .where('providerId', isEqualTo: providerId)
        .where('moderationStatus', isEqualTo: 'approved')
        .get();
    if (snap.docs.isEmpty) return;
    final ratings = snap.docs
        .map((d) => (d.data() as Map<String, dynamic>)['rating'] as int? ?? 0)
        .toList();
    final avg = ratings.reduce((a, b) => a + b) / ratings.length;
    await _firestore.collection('workers').doc(providerId).update({
      'rating': avg,
    });
  }

  Future<void> _logAdminAction(
      String adminId, String action, String entityType, String entityId) async {
    await _firestore.collection('audit_logs').add({
      'adminUserId': adminId,
      'actionType': action,
      'entityType': entityType,
      'entityId': entityId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
