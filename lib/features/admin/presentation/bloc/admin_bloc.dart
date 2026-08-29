import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../incident/domain/entities/incident.dart';
import '../../data/admin_repository.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository _adminRepository;

  AdminBloc(this._adminRepository) : super(AdminState.initial()) {
    on<FetchDashboardData>(_onFetchDashboardData);
    on<LogReferenceCallOutcome>(_onLogReferenceCallOutcome);
    on<ApproveBlueTierUpgrade>(_onApproveBlueTierUpgrade);
    on<RejectBlueTierUpgrade>(_onRejectBlueTierUpgrade);
    on<ApproveWorker>(_onApproveWorker);
    on<ManuallyAssignWorker>(_onManuallyAssignWorker);
    on<ResolveIncident>(_onResolveIncident);
  }

  Future<void> _onFetchDashboardData(
    FetchDashboardData event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final workersResult = await _adminRepository.getPendingWorkers();
    final workersFailure = workersResult.fold((f) => f, (workers) {
      emit(state.copyWith(pendingWorkers: workers));
      return null;
    });
    if (workersFailure != null) {
      emit(state.copyWith(isLoading: false, errorMessage: workersFailure.message));
      return;
    }

    final bookingsResult = await _adminRepository.getActiveBookings();
    final bookingsFailure = bookingsResult.fold((f) => f, (bookings) {
      emit(state.copyWith(activeBookings: bookings));
      return null;
    });
    if (bookingsFailure != null) {
      emit(state.copyWith(isLoading: false, errorMessage: bookingsFailure.message));
      return;
    }

    final incidentsResult = await _adminRepository.getOpenIncidents();
    final incidentsFailure = incidentsResult.fold((f) => f, (incidents) {
      emit(state.copyWith(openIncidents: incidents));
      return null;
    });
    if (incidentsFailure != null) {
      emit(state.copyWith(isLoading: false, errorMessage: incidentsFailure.message));
      return;
    }

    final blueTierResult =
        await _adminRepository.getBlueTierPendingVerifications();
    blueTierResult.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (verifications) => emit(state.copyWith(
        isLoading: false,
        blueTierPending: verifications,
      )),
    );
  }

  Future<void> _onLogReferenceCallOutcome(
    LogReferenceCallOutcome event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final outcomeResult = await _adminRepository.logReferenceCallOutcome(
      workerId: event.workerId,
      referenceIndex: event.referenceIndex,
      outcome: event.outcome,
      notes: event.notes,
    );

    final failure = outcomeResult.fold((f) => f, (_) => null);
    if (failure != null) {
      emit(state.copyWith(isLoading: false, errorMessage: failure.message));
      return;
    }

    final refreshResult =
        await _adminRepository.getBlueTierPendingVerifications();
    refreshResult.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (verifications) => emit(state.copyWith(
        isLoading: false,
        blueTierPending: verifications,
      )),
    );
  }

  Future<void> _onApproveBlueTierUpgrade(
    ApproveBlueTierUpgrade event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await _adminRepository.approveBlueTierUpgrade(event.workerId);
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (_) => emit(state.copyWith(
        isLoading: false,
        blueTierPending: state.blueTierPending
            .where((v) => v.workerId != event.workerId)
            .toList(),
      )),
    );
  }

  Future<void> _onRejectBlueTierUpgrade(
    RejectBlueTierUpgrade event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await _adminRepository.rejectBlueTierUpgrade(
      event.workerId,
      event.reason,
    );
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (_) => emit(state.copyWith(
        isLoading: false,
        blueTierPending: state.blueTierPending
            .where((v) => v.workerId != event.workerId)
            .toList(),
      )),
    );
  }

  Future<void> _onApproveWorker(
    ApproveWorker event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final result =
        await _adminRepository.updateWorkerStatus(event.workerId, 'approved');
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (_) => emit(state.copyWith(
        isLoading: false,
        pendingWorkers: state.pendingWorkers
            .where((w) => w.uid != event.workerId)
            .toList(),
      )),
    );
  }

  Future<void> _onManuallyAssignWorker(
    ManuallyAssignWorker event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final assignResult = await _adminRepository.assignWorkerToBooking(
      event.bookingId,
      event.workerId,
    );
    final failure = assignResult.fold((f) => f, (_) => null);
    if (failure != null) {
      emit(state.copyWith(isLoading: false, errorMessage: failure.message));
      return;
    }

    final bookingsResult = await _adminRepository.getActiveBookings();
    bookingsResult.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (bookings) => emit(state.copyWith(
        isLoading: false,
        activeBookings: bookings,
      )),
    );
  }

  Future<void> _onResolveIncident(
    ResolveIncident event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final updateResult = await _adminRepository.updateIncidentStatus(
      incidentId: event.incidentId,
      status: IncidentStatus.resolved,
      resolution: event.resolution,
      resolvedBy: event.resolvedBy,
    );
    final failure = updateResult.fold((f) => f, (_) => null);
    if (failure != null) {
      emit(state.copyWith(isLoading: false, errorMessage: failure.message));
      return;
    }

    final incidentsResult = await _adminRepository.getOpenIncidents();
    incidentsResult.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (incidents) => emit(state.copyWith(
        isLoading: false,
        openIncidents: incidents,
      )),
    );
  }
}
