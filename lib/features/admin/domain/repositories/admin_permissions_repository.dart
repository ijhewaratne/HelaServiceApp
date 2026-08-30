import 'package:dartz/dartz.dart';

import '../../../../core/constants/admin_scope.dart';
import '../../../../core/errors/failures.dart';

abstract class AdminPermissionsRepository {
  /// Scopes currently granted to [adminUid]. Empty if none have been
  /// assigned yet — additive rollout means that does NOT mean the admin has
  /// no access, only that no scope has been recorded for them.
  Future<Either<Failure, Set<AdminScope>>> getScopes(String adminUid);

  /// Overwrites the full scope set for [adminUid]. This is the low-level
  /// persistence primitive the applyApprovedChange Cloud Function calls once
  /// a permission-grant proposal is approved — Firestore rules reject a
  /// direct client call to this, by design. The app UI proposes a change via
  /// ApprovalRepository.propose(ApprovalType.permissionGrant, ...) instead.
  Future<Either<Failure, void>> setScopes({
    required String adminUid,
    required Set<AdminScope> scopes,
    required String grantedBy,
  });
}
