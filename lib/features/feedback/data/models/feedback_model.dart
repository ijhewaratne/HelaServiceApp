import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/feedback.dart';

/// Data model for Feedback - handles JSON serialization
class FeedbackModel {
  final String id;
  final String userId;
  final String userType;
  final String category;
  final String message;
  final int? rating;
  final List<String>? attachments;
  final DateTime createdAt;
  final bool isResolved;
  final String? adminResponse;
  final DateTime? resolvedAt;

  FeedbackModel({
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

  /// Create from Firestore document
  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedbackModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userType: data['userType'] ?? '',
      category: data['category'] ?? 'general',
      message: data['message'] ?? '',
      rating: data['rating'] as int?,
      attachments: data['attachments'] != null
          ? List<String>.from(data['attachments'])
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isResolved: data['isResolved'] ?? false,
      adminResponse: data['adminResponse'] as String?,
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userType': userType,
      'category': category,
      'message': message,
      'rating': rating,
      'attachments': attachments,
      'createdAt': Timestamp.fromDate(createdAt),
      'isResolved': isResolved,
      'adminResponse': adminResponse,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }

  /// Create from domain entity
  factory FeedbackModel.fromEntity(Feedback entity) {
    return FeedbackModel(
      id: entity.id,
      userId: entity.userId,
      userType: entity.userType,
      category: entity.category.name,
      message: entity.message,
      rating: entity.rating,
      attachments: entity.attachments,
      createdAt: entity.createdAt,
      isResolved: entity.isResolved,
      adminResponse: entity.adminResponse,
      resolvedAt: entity.resolvedAt,
    );
  }

  /// Convert to domain entity
  Feedback toEntity() {
    return Feedback(
      id: id,
      userId: userId,
      userType: userType,
      category: FeedbackCategory.values.byName(category),
      message: message,
      rating: rating,
      attachments: attachments,
      createdAt: createdAt,
      isResolved: isResolved,
      adminResponse: adminResponse,
      resolvedAt: resolvedAt,
    );
  }

  FeedbackModel copyWith({
    String? id,
    String? userId,
    String? userType,
    String? category,
    String? message,
    int? rating,
    List<String>? attachments,
    DateTime? createdAt,
    bool? isResolved,
    String? adminResponse,
    DateTime? resolvedAt,
  }) {
    return FeedbackModel(
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
}
