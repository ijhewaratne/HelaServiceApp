import 'package:equatable/equatable.dart';

/// Incident entity for emergency reporting
class Incident extends Equatable {
  final String id;
  final String reporterId;
  final String reporterType; // 'customer' or 'worker'
  final String? jobId;
  final String? subjectId;
  final IncidentType type;
  final String description;
  final String? audioUrl;
  final String? imageUrl;
  final DateTime reportedAt;
  final IncidentStatus status;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final String? resolution;

  const Incident({
    required this.id,
    required this.reporterId,
    required this.reporterType,
    this.jobId,
    this.subjectId,
    required this.type,
    required this.description,
    this.audioUrl,
    this.imageUrl,
    required this.reportedAt,
    this.status = IncidentStatus.pending,
    this.resolvedBy,
    this.resolvedAt,
    this.resolution,
  });

  Incident copyWith({
    String? id,
    String? reporterId,
    String? reporterType,
    String? jobId,
    String? subjectId,
    IncidentType? type,
    String? description,
    String? audioUrl,
    String? imageUrl,
    DateTime? reportedAt,
    IncidentStatus? status,
    String? resolvedBy,
    DateTime? resolvedAt,
    String? resolution,
  }) {
    return Incident(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reporterType: reporterType ?? this.reporterType,
      jobId: jobId ?? this.jobId,
      subjectId: subjectId ?? this.subjectId,
      type: type ?? this.type,
      description: description ?? this.description,
      audioUrl: audioUrl ?? this.audioUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      reportedAt: reportedAt ?? this.reportedAt,
      status: status ?? this.status,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolution: resolution ?? this.resolution,
    );
  }

  @override
  List<Object?> get props => [
        id,
        reporterId,
        reporterType,
        jobId,
        subjectId,
        type,
        description,
        audioUrl,
        imageUrl,
        reportedAt,
        status,
        resolvedBy,
        resolvedAt,
        resolution,
      ];
}

enum IncidentType {
  safetyConcern,
  paymentDispute,
  harassment,
  propertyDamage,
  serviceIssue,
  other,
}

enum IncidentStatus {
  pending,
  investigating,
  resolved,
  escalated,
}

extension IncidentTypeExtension on IncidentType {
  String get displayName {
    switch (this) {
      case IncidentType.safetyConcern:
        return 'Safety Concern';
      case IncidentType.paymentDispute:
        return 'Payment Dispute';
      case IncidentType.harassment:
        return 'Harassment';
      case IncidentType.propertyDamage:
        return 'Property Damage';
      case IncidentType.serviceIssue:
        return 'Service Issue';
      case IncidentType.other:
        return 'Other';
    }
  }
}
