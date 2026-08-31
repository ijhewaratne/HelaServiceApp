import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/review.dart';

abstract class ReviewRepository {
  Future<Either<Failure, Review>> submitReview(Review review);
  Future<Either<Failure, List<Review>>> getReviewsForProvider(
    String providerId,
  );
  Future<Either<Failure, List<Review>>> getReviewsByCustomer(String customerId);
  Future<Either<Failure, Review?>> getReviewForRequest(String requestId);
  Future<Either<Failure, List<Review>>> getPendingModerationReviews();
  Future<Either<Failure, void>> approveReview(String reviewId, String adminId);
  Future<Either<Failure, void>> hideReview(
    String reviewId,
    String adminId,
    String note,
  );
  Future<Either<Failure, void>> flagReview(String reviewId, String adminId);
}
