import 'package:equatable/equatable.dart';

/// Feedback entity representing user feedback/complaints
class Feedback extends Equatable {
  final String id;
  final String userId;
  final String userType; // 'customer' or 'worker'
  final FeedbackCategory category;
  final String message;
  final int? rating; // 1-5 for app rating
  final List<String>? attachments;
  final DateTime createdAt;
  final bool isResolved;
  final String? adminResponse;
  final DateTime? resolvedAt;

  const Feedback({
    required this.id,
    required this.userId,
    required this.userType,
    required this.category,
    required this.message,
    this.rating,
    this.attachments,
    required this.createdAt,
    this.isResolved = false,
    this.adminResponse,
    this.resolvedAt,
  });

  Feedback copyWith({
    String? id,
    String? userId,
    String? userType,
    FeedbackCategory? category,
    String? message,
    int? rating,
    List<String>? attachments,
    DateTime? createdAt,
    bool? isResolved,
    String? adminResponse,
    DateTime? resolvedAt,
  }) {
    return Feedback(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userType: userType ?? this.userType,
      category: category ?? this.category,
      message: message ?? this.message,
      rating: rating ?? this.rating,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      isResolved: isResolved ?? this.isResolved,
      adminResponse: adminResponse ?? this.adminResponse,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userType,
        category,
        message,
        rating,
        attachments,
        createdAt,
        isResolved,
        adminResponse,
        resolvedAt,
      ];
}

enum FeedbackCategory { bug, feature, complaint, general }

extension FeedbackCategoryExtension on FeedbackCategory {
  String get displayName {
    switch (this) {
      case FeedbackCategory.bug:
        return 'Bug Report';
      case FeedbackCategory.feature:
        return 'Feature Request';
      case FeedbackCategory.complaint:
        return 'Complaint';
      case FeedbackCategory.general:
        return 'General Feedback';
    }
  }

  String get icon {
    switch (this) {
      case FeedbackCategory.bug:
        return '🐛';
      case FeedbackCategory.feature:
        return '💡';
      case FeedbackCategory.complaint:
        return '⚠️';
      case FeedbackCategory.general:
        return '💬';
    }
  }
}
