import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/pending_approval.dart';

abstract class ApprovalRepository {
  /// Propose a high-risk change. Does not apply it — a different admin must
  /// approve first (see [decide]), at which point a server-side function
  /// applies the change.
  Future<Either<Failure, String>> propose({
    required ApprovalType type,
    required Map<String, dynamic> payload,
    required String proposedBy,
  });

  /// All approvals still awaiting a decision, oldest first.
  Future<Either<Failure, List<PendingApproval>>> getPending();

  /// Approve or reject a pending proposal. [decidedBy] must not equal the
  /// original proposer — enforced by Firestore rules as well as here.
  Future<Either<Failure, void>> decide({
    required String approvalId,
    required bool approve,
    required String decidedBy,
    String? reason,
  });
}
