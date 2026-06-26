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
      // Rating is only recalculated after admin approval, not on submission
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
      final batch = _firestore.batch();
      batch.update(_col.doc(reviewId), {
        'moderationStatus': 'approved',
        'moderatedAt': FieldValue.serverTimestamp(),
      });
      batch.set(_firestore.collection('audit_logs').doc(), {
        'adminUserId': adminId,
        'actionType': 'approve_review',
        'entityType': 'reviews',
        'entityId': reviewId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      // Recalculate rating after approval changes the approved-review set
      final doc = await _col.doc(reviewId).get();
      final providerId = (doc.data() as Map<String, dynamic>?)?['providerId'] as String?;
      if (providerId != null) await _updateProviderRating(providerId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> hideReview(
      String reviewId, String adminId, String note) async {
    try {
      final batch = _firestore.batch();
      batch.update(_col.doc(reviewId), {
        'moderationStatus': 'hidden',
        'adminNote': note,
        'moderatedAt': FieldValue.serverTimestamp(),
      });
      batch.set(_firestore.collection('audit_logs').doc(), {
        'adminUserId': adminId,
        'actionType': 'hide_review',
        'entityType': 'reviews',
        'entityId': reviewId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      // Recalculate: a previously-approved review being hidden reduces the count
      final doc = await _col.doc(reviewId).get();
      final providerId = (doc.data() as Map<String, dynamic>?)?['providerId'] as String?;
      if (providerId != null) await _updateProviderRating(providerId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> flagReview(
      String reviewId, String adminId) async {
    try {
      final batch = _firestore.batch();
      batch.update(_col.doc(reviewId), {
        'moderationStatus': 'flagged',
        'moderatedAt': FieldValue.serverTimestamp(),
      });
      batch.set(_firestore.collection('audit_logs').doc(), {
        'adminUserId': adminId,
        'actionType': 'flag_review',
        'entityType': 'reviews',
        'entityId': reviewId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      // Recalculate: a previously-approved review being flagged reduces the count
      final doc = await _col.doc(reviewId).get();
      final providerId = (doc.data() as Map<String, dynamic>?)?['providerId'] as String?;
      if (providerId != null) await _updateProviderRating(providerId);
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

}
