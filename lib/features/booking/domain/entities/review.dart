import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum ReviewModerationStatus { pending, approved, hidden, flagged }

class Review extends Equatable {
  final String id;
  final String requestId;
  final String customerId;
  final String providerId;
  final int rating; // 1-5
  final String? reviewText;
  final int? punctualityRating; // 1-5
  final int? qualityRating; // 1-5
  final bool? wouldRecommend;
  final bool? wasIssueResolved;
  final bool? wasProviderOnTime;
  final ReviewModerationStatus moderationStatus;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? moderatedAt;

  const Review({
    required this.id,
    required this.requestId,
    required this.customerId,
    required this.providerId,
    required this.rating,
    this.reviewText,
    this.punctualityRating,
    this.qualityRating,
    this.wouldRecommend,
    this.wasIssueResolved,
    this.wasProviderOnTime,
    this.moderationStatus = ReviewModerationStatus.pending,
    this.adminNote,
    required this.createdAt,
    this.moderatedAt,
  });

  bool get isVisible => moderationStatus == ReviewModerationStatus.approved;

  Review copyWith({
    String? id,
    String? requestId,
    String? customerId,
    String? providerId,
    int? rating,
    String? reviewText,
    int? punctualityRating,
    int? qualityRating,
    bool? wouldRecommend,
    bool? wasIssueResolved,
    bool? wasProviderOnTime,
    ReviewModerationStatus? moderationStatus,
    String? adminNote,
    DateTime? createdAt,
    DateTime? moderatedAt,
  }) =>
      Review(
        id: id ?? this.id,
        requestId: requestId ?? this.requestId,
        customerId: customerId ?? this.customerId,
        providerId: providerId ?? this.providerId,
        rating: rating ?? this.rating,
        reviewText: reviewText ?? this.reviewText,
        punctualityRating: punctualityRating ?? this.punctualityRating,
        qualityRating: qualityRating ?? this.qualityRating,
        wouldRecommend: wouldRecommend ?? this.wouldRecommend,
        wasIssueResolved: wasIssueResolved ?? this.wasIssueResolved,
        wasProviderOnTime: wasProviderOnTime ?? this.wasProviderOnTime,
        moderationStatus: moderationStatus ?? this.moderationStatus,
        adminNote: adminNote ?? this.adminNote,
        createdAt: createdAt ?? this.createdAt,
        moderatedAt: moderatedAt ?? this.moderatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'requestId': requestId,
        'customerId': customerId,
        'providerId': providerId,
        'rating': rating,
        'reviewText': reviewText,
        'punctualityRating': punctualityRating,
        'qualityRating': qualityRating,
        'wouldRecommend': wouldRecommend,
        'wasIssueResolved': wasIssueResolved,
        'wasProviderOnTime': wasProviderOnTime,
        'moderationStatus': moderationStatus.name,
        'adminNote': adminNote,
        'createdAt': Timestamp.fromDate(createdAt),
        'moderatedAt':
            moderatedAt != null ? Timestamp.fromDate(moderatedAt!) : null,
      };

  factory Review.fromJson(Map<String, dynamic> json, {String? id}) => Review(
        id: id ?? json['id'] as String? ?? '',
        requestId: json['requestId'] as String? ?? '',
        customerId: json['customerId'] as String? ?? '',
        providerId: json['providerId'] as String? ?? '',
        rating: json['rating'] as int? ?? 5,
        reviewText: json['reviewText'] as String?,
        punctualityRating: json['punctualityRating'] as int?,
        qualityRating: json['qualityRating'] as int?,
        wouldRecommend: json['wouldRecommend'] as bool?,
        wasIssueResolved: json['wasIssueResolved'] as bool?,
        wasProviderOnTime: json['wasProviderOnTime'] as bool?,
        moderationStatus: ReviewModerationStatus.values.firstWhere(
          (e) => e.name == (json['moderationStatus'] as String?),
          orElse: () => ReviewModerationStatus.pending,
        ),
        adminNote: json['adminNote'] as String?,
        createdAt: json['createdAt'] is Timestamp
            ? (json['createdAt'] as Timestamp).toDate()
            : DateTime.parse(
                json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
        moderatedAt: json['moderatedAt'] != null
            ? (json['moderatedAt'] is Timestamp
                ? (json['moderatedAt'] as Timestamp).toDate()
                : DateTime.parse(json['moderatedAt'] as String))
            : null,
      );

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review.fromJson(data, id: doc.id);
  }

  @override
  List<Object?> get props => [id, requestId, customerId, providerId, rating];
}
