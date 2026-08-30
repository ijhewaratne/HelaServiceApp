import 'package:equatable/equatable.dart';

enum ApprovalType { categoryDeactivation, permissionGrant }

enum ApprovalStatus { pending, approved, rejected }

/// A proposed high-risk change awaiting a second admin's sign-off. The
/// proposer cannot decide their own proposal — enforced by Firestore rules,
/// not just this entity.
class PendingApproval extends Equatable {
  final String id;
  final ApprovalType type;
  final Map<String, dynamic> payload;
  final String proposedBy;
  final DateTime proposedAt;
  final ApprovalStatus status;
  final String? decidedBy;
  final DateTime? decidedAt;
  final String? reason;

  const PendingApproval({
    required this.id,
    required this.type,
    required this.payload,
    required this.proposedBy,
    required this.proposedAt,
    this.status = ApprovalStatus.pending,
    this.decidedBy,
    this.decidedAt,
    this.reason,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        payload,
        proposedBy,
        proposedAt,
        status,
        decidedBy,
        decidedAt,
        reason,
      ];
}
