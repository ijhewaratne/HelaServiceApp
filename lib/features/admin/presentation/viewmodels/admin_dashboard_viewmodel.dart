import 'package:flutter/foundation.dart';
import '../../../worker/domain/entities/worker_profile.dart';
import '../../../../features/customer/domain/booking.dart';
import '../../domain/incident.dart';
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
    try {
      _pendingWorkers = await _adminRepository.getPendingWorkers();
      _activeBookings = await _adminRepository.getActiveBookings();
      _openIncidents = await _adminRepository.getOpenIncidents();
      _blueTierPending =
          await _adminRepository.getBlueTierPendingVerifications();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logReferenceCallOutcome({
    required String workerId,
    required int referenceIndex,
    required String outcome,
    required String notes,
  }) async {
    _setLoading(true);
    try {
      await _adminRepository.logReferenceCallOutcome(
        workerId: workerId,
        referenceIndex: referenceIndex,
        outcome: outcome,
        notes: notes,
      );
      _blueTierPending =
          await _adminRepository.getBlueTierPendingVerifications();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> approveBlueTierUpgrade(String workerId) async {
    _setLoading(true);
    try {
      await _adminRepository.approveBlueTierUpgrade(workerId);
      _blueTierPending.removeWhere((v) => v.workerId == workerId);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> rejectBlueTierUpgrade(String workerId, String reason) async {
    _setLoading(true);
    try {
      await _adminRepository.rejectBlueTierUpgrade(workerId, reason);
      _blueTierPending.removeWhere((v) => v.workerId == workerId);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> approveWorker(String workerId) async {
    _setLoading(true);
    try {
      await _adminRepository.updateWorkerStatus(workerId, 'approved');
      _pendingWorkers.removeWhere((w) => w.uid == workerId);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> manuallyAssignWorker(String bookingId, String workerId) async {
    _setLoading(true);
    try {
      await _adminRepository.assignWorkerToBooking(bookingId, workerId);
      // Reload bookings to reflect the new assigned status state
      _activeBookings = await _adminRepository.getActiveBookings();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
}
