/// Granular admin permission scopes.
///
/// Additive rollout (see docs/SPEC_DECISIONS.md): granting/revoking scopes
/// here does not yet narrow anyone's access — every existing isAdmin()-gated
/// Firestore rule and screen keeps working exactly as before. This is the
/// mechanism the super admin can start assigning real scopes with; a
/// separate, deliberate follow-up decision is needed before any rule or
/// screen actually starts requiring a specific scope instead of isAdmin().
enum AdminScope {
  workerVerification,
  bookingIntervention,
  disputeResolution,
  categoryManagement,
  userManagement,
  auditView,
  financeView,
  reviewModeration,
  customerManagement,
}

extension AdminScopeX on AdminScope {
  String get label {
    switch (this) {
      case AdminScope.workerVerification:
        return 'Worker verification';
      case AdminScope.bookingIntervention:
        return 'Booking intervention';
      case AdminScope.disputeResolution:
        return 'Disputes & incidents';
      case AdminScope.categoryManagement:
        return 'Category management';
      case AdminScope.userManagement:
        return 'User management';
      case AdminScope.auditView:
        return 'Audit log access';
      case AdminScope.financeView:
        return 'Finance & revenue';
      case AdminScope.reviewModeration:
        return 'Review moderation';
      case AdminScope.customerManagement:
        return 'Customer management';
    }
  }
}
