import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/feedback.dart';

/// Repository interface for feedback operations
abstract class FeedbackRepository {
  /// Submit new feedback
  Future<Either<Failure, Feedback>> submitFeedback({
    required String userId,
    required String userType,
    required FeedbackCategory category,
    required String message,
    int? rating,
    List<String>? attachments,
  });

  /// Get all feedback submitted by a user
  Future<Either<Failure, List<Feedback>>> getUserFeedback(String userId);

  /// Get feedback by ID
  Future<Either<Failure, Feedback>> getFeedbackById(String feedbackId);

  /// Update feedback (e.g., mark as resolved - admin only)
  Future<Either<Failure, Feedback>> updateFeedback({
    required String feedbackId,
    bool? isResolved,
    String? adminResponse,
  });

  /// Delete feedback (user can delete their own)
  Future<Either<Failure, void>> deleteFeedback(String feedbackId);

  /// Stream of user's feedback for real-time updates
  Stream<Either<Failure, List<Feedback>>> watchUserFeedback(String userId);
}
