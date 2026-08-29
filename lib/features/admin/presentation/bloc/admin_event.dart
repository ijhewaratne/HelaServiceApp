import 'package:equatable/equatable.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

/// Load pending workers, active bookings, open incidents, and blue-tier
/// verifications in one shot.
class FetchDashboardData extends AdminEvent {
  const FetchDashboardData();
}

class LogReferenceCallOutcome extends AdminEvent {
  final String workerId;
  final int referenceIndex;
  final String outcome; // called_confirmed / called_refused / no_answer
  final String notes;

  const LogReferenceCallOutcome({
    required this.workerId,
    required this.referenceIndex,
    required this.outcome,
    required this.notes,
  });

  @override
  List<Object?> get props => [workerId, referenceIndex, outcome, notes];
}

class ApproveBlueTierUpgrade extends AdminEvent {
  final String workerId;

  const ApproveBlueTierUpgrade(this.workerId);

  @override
  List<Object?> get props => [workerId];
}

class RejectBlueTierUpgrade extends AdminEvent {
  final String workerId;
  final String reason;

  const RejectBlueTierUpgrade(this.workerId, this.reason);

  @override
  List<Object?> get props => [workerId, reason];
}

class ApproveWorker extends AdminEvent {
  final String workerId;

  const ApproveWorker(this.workerId);

  @override
  List<Object?> get props => [workerId];
}

class ManuallyAssignWorker extends AdminEvent {
  final String bookingId;
  final String workerId;

  const ManuallyAssignWorker(this.bookingId, this.workerId);

  @override
  List<Object?> get props => [bookingId, workerId];
}

class ResolveIncident extends AdminEvent {
  final String incidentId;
  final String? resolution;
  final String? resolvedBy;

  const ResolveIncident({
    required this.incidentId,
    this.resolution,
    this.resolvedBy,
  });

  @override
  List<Object?> get props => [incidentId, resolution, resolvedBy];
}
