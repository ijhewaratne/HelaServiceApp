import 'package:flutter/foundation.dart';
import '../../../worker/domain/entities/worker_profile.dart';
import '../../../../features/customer/domain/booking.dart';
import '../../../incident/domain/entities/incident.dart';
import '../../data/admin_repository.dart';

class AdminViewModel extends ChangeNotifier {
  final AdminRepository _adminRepository;

  bool _isLoading = false;
  String? _errorMessage;

  List<WorkerProfile> _pendingWorkers = [];
  List<Booking> _activeBookings = [];
  List<Incident> _openIncidents = [];
  List<BlueTierVerification> _blueTierPending = [];

  AdminViewModel(this._adminRepository);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<WorkerProfile> get pendingWorkers => _pendingWorkers;
  List<Booking> get activeBookings => _activeBookings;
  List<Incident> get openIncidents => _openIncidents;
  List<BlueTierVerification> get blueTierPending => _blueTierPending;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> fetchDashboardData() async {
    _setLoading(true);
    _setError(null);

    final workersResult = await _adminRepository.getPendingWorkers();
    final failure = workersResult.fold(
      (failure) => failure,
      (workers) {
        _pendingWorkers = workers;
        return null;
      },
    );
    if (failure != null) {
      _setError(failure.message);
      _setLoading(false);
      return;
    }

    final bookingsResult = await _adminRepository.getActiveBookings();
    final bookingsFailure = bookingsResult.fold(
      (failure) => failure,
      (bookings) {
        _activeBookings = bookings;
        return null;
      },
    );
    if (bookingsFailure != null) {
      _setError(bookingsFailure.message);
      _setLoading(false);
      return;
    }

    final incidentsResult = await _adminRepository.getOpenIncidents();
    final incidentsFailure = incidentsResult.fold(
      (failure) => failure,
      (incidents) {
        _openIncidents = incidents;
        return null;
      },
    );
    if (incidentsFailure != null) {
      _setError(incidentsFailure.message);
      _setLoading(false);
      return;
    }

    final blueTierResult =
        await _adminRepository.getBlueTierPendingVerifications();
    blueTierResult.fold(
      (failure) => _setError(failure.message),
      (verifications) => _blueTierPending = verifications,
    );

    _setLoading(false);
  }

  Future<void> logReferenceCallOutcome({
    required String workerId,
    required int referenceIndex,
    required String outcome,
    required String notes,
  }) async {
    _setLoading(true);

    final outcomeResult = await _adminRepository.logReferenceCallOutcome(
      workerId: workerId,
      referenceIndex: referenceIndex,
      outcome: outcome,
      notes: notes,
    );

    final failure = outcomeResult.fold((failure) => failure, (_) => null);
    if (failure != null) {
      _setError(failure.message);
      _setLoading(false);
      return;
    }

    final refreshResult =
        await _adminRepository.getBlueTierPendingVerifications();
    refreshResult.fold(
      (failure) => _setError(failure.message),
      (verifications) => _blueTierPending = verifications,
    );

    _setLoading(false);
  }

  Future<void> approveBlueTierUpgrade(String workerId) async {
    _setLoading(true);
    final result = await _adminRepository.approveBlueTierUpgrade(workerId);
    result.fold(
      (failure) => _setError(failure.message),
      (_) => _blueTierPending.removeWhere((v) => v.workerId == workerId),
    );
    _setLoading(false);
  }

  Future<void> rejectBlueTierUpgrade(String workerId, String reason) async {
    _setLoading(true);
    final result =
        await _adminRepository.rejectBlueTierUpgrade(workerId, reason);
    result.fold(
      (failure) => _setError(failure.message),
      (_) => _blueTierPending.removeWhere((v) => v.workerId == workerId),
    );
    _setLoading(false);
  }

  Future<void> approveWorker(String workerId) async {
    _setLoading(true);
    final result =
        await _adminRepository.updateWorkerStatus(workerId, 'approved');
    result.fold(
      (failure) => _setError(failure.message),
      (_) => _pendingWorkers.removeWhere((w) => w.uid == workerId),
    );
    _setLoading(false);
  }

  Future<void> manuallyAssignWorker(String bookingId, String workerId) async {
    _setLoading(true);

    final assignResult =
        await _adminRepository.assignWorkerToBooking(bookingId, workerId);
    final failure = assignResult.fold((failure) => failure, (_) => null);
    if (failure != null) {
      _setError(failure.message);
      _setLoading(false);
      return;
    }

    // Reload bookings to reflect the new assigned status state
    final bookingsResult = await _adminRepository.getActiveBookings();
    bookingsResult.fold(
      (failure) => _setError(failure.message),
      (bookings) => _activeBookings = bookings,
    );

    _setLoading(false);
  }

  Future<void> resolveIncident({
    required String incidentId,
    String? resolution,
    String? resolvedBy,
  }) async {
    _setLoading(true);

    final updateResult = await _adminRepository.updateIncidentStatus(
      incidentId: incidentId,
      status: IncidentStatus.resolved,
      resolution: resolution,
      resolvedBy: resolvedBy,
    );
    final failure = updateResult.fold((failure) => failure, (_) => null);
    if (failure != null) {
      _setError(failure.message);
      _setLoading(false);
      return;
    }

    final incidentsResult = await _adminRepository.getOpenIncidents();
    incidentsResult.fold(
      (failure) => _setError(failure.message),
      (incidents) => _openIncidents = incidents,
    );

    _setLoading(false);
  }
}
