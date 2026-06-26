import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum DisputeStatus { open, underReview, resolved, closed }

enum DisputeIssueType {
  qualityOfWork,
  noShow,
  unprofessionalBehavior,
  pricingDispute,
  cancellationIssue,
  safetyIncident,
  damagedProperty,
  other,
}

class Dispute extends Equatable {
  final String id;
  final String requestId;
  final String reportedByUserId;
  final String reportedUserId;
  final DisputeIssueType issueType;
  final String description;
  final DisputeStatus status;
  final String? adminNote;
  final String? resolvedByAdminId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  const Dispute({
    required this.id,
    required this.requestId,
    required this.reportedByUserId,
    required this.reportedUserId,
    required this.issueType,
    required this.description,
    this.status = DisputeStatus.open,
    this.adminNote,
    this.resolvedByAdminId,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
  });

  Dispute copyWith({
    String? id,
    String? requestId,
    String? reportedByUserId,
    String? reportedUserId,
    DisputeIssueType? issueType,
    String? description,
    DisputeStatus? status,
    String? adminNote,
    String? resolvedByAdminId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
  }) =>
      Dispute(
        id: id ?? this.id,
        requestId: requestId ?? this.requestId,
        reportedByUserId: reportedByUserId ?? this.reportedByUserId,
        reportedUserId: reportedUserId ?? this.reportedUserId,
        issueType: issueType ?? this.issueType,
        description: description ?? this.description,
        status: status ?? this.status,
        adminNote: adminNote ?? this.adminNote,
        resolvedByAdminId: resolvedByAdminId ?? this.resolvedByAdminId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        resolvedAt: resolvedAt ?? this.resolvedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'requestId': requestId,
        'reportedByUserId': reportedByUserId,
        'reportedUserId': reportedUserId,
        'issueType': issueType.name,
        'description': description,
        'status': status.name,
        'adminNote': adminNote,
        'resolvedByAdminId': resolvedByAdminId,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'resolvedAt':
            resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      };

  factory Dispute.fromJson(Map<String, dynamic> json, {String? id}) => Dispute(
        id: id ?? json['id'] as String? ?? '',
        requestId: json['requestId'] as String? ?? '',
        reportedByUserId: json['reportedByUserId'] as String? ?? '',
        reportedUserId: json['reportedUserId'] as String? ?? '',
        issueType: DisputeIssueType.values.firstWhere(
          (e) => e.name == (json['issueType'] as String?),
          orElse: () => DisputeIssueType.other,
        ),
        description: json['description'] as String? ?? '',
        status: DisputeStatus.values.firstWhere(
          (e) => e.name == (json['status'] as String?),
          orElse: () => DisputeStatus.open,
        ),
        adminNote: json['adminNote'] as String?,
        resolvedByAdminId: json['resolvedByAdminId'] as String?,
        createdAt: json['createdAt'] is Timestamp
            ? (json['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? (json['updatedAt'] is Timestamp
                ? (json['updatedAt'] as Timestamp).toDate()
                : DateTime.parse(json['updatedAt'] as String))
            : null,
        resolvedAt: json['resolvedAt'] != null
            ? (json['resolvedAt'] is Timestamp
                ? (json['resolvedAt'] as Timestamp).toDate()
                : DateTime.parse(json['resolvedAt'] as String))
            : null,
      );

  factory Dispute.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Dispute.fromJson(data, id: doc.id);
  }

  @override
  List<Object?> get props => [id, requestId, status];
}

extension DisputeIssueTypeX on DisputeIssueType {
  String get displayName {
    switch (this) {
      case DisputeIssueType.qualityOfWork:
        return 'Quality of Work';
      case DisputeIssueType.noShow:
        return 'Provider Did Not Show Up';
      case DisputeIssueType.unprofessionalBehavior:
        return 'Unprofessional Behavior';
      case DisputeIssueType.pricingDispute:
        return 'Pricing Dispute';
      case DisputeIssueType.cancellationIssue:
        return 'Cancellation Issue';
      case DisputeIssueType.safetyIncident:
        return 'Safety Incident';
      case DisputeIssueType.damagedProperty:
        return 'Damaged Property';
      case DisputeIssueType.other:
        return 'Other';
    }
  }
}

extension DisputeStatusX on DisputeStatus {
  String get displayName {
    switch (this) {
      case DisputeStatus.open:
        return 'Open';
      case DisputeStatus.underReview:
        return 'Under Review';
      case DisputeStatus.resolved:
        return 'Resolved';
      case DisputeStatus.closed:
        return 'Closed';
    }
  }
}
