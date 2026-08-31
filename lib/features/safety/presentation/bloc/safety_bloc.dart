import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/safety_alert.dart';
import '../../domain/repositories/safety_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class SafetyEvent extends Equatable {
  const SafetyEvent();
  @override
  List<Object?> get props => [];
}

class WatchOpenAlerts extends SafetyEvent {}

class LoadBookingAlerts extends SafetyEvent {
  final String bookingId;
  const LoadBookingAlerts(this.bookingId);
  @override
  List<Object?> get props => [bookingId];
}

class TriggerSOS extends SafetyEvent {
  final String bookingId;
  final String workerId;
  final String customerId;
  final double? latitude;
  final double? longitude;
  const TriggerSOS({
    required this.bookingId,
    required this.workerId,
    required this.customerId,
    this.latitude,
    this.longitude,
  });
  @override
  List<Object?> get props => [bookingId, workerId];
}

class AcknowledgeAlert extends SafetyEvent {
  final String alertId;
  const AcknowledgeAlert(this.alertId);
  @override
  List<Object?> get props => [alertId];
}

class ResolveAlert extends SafetyEvent {
  final String alertId;
  final String adminId;
  final String notes;
  const ResolveAlert({
    required this.alertId,
    required this.adminId,
    required this.notes,
  });
  @override
  List<Object?> get props => [alertId];
}

class EscalateAlert extends SafetyEvent {
  final String alertId;
  const EscalateAlert(this.alertId);
  @override
  List<Object?> get props => [alertId];
}

class LogManualContact extends SafetyEvent {
  final String alertId;
  final String adminId;
  final String contactType; // 'phone' | 'sms' | 'police'
  final String notes;
  const LogManualContact({
    required this.alertId,
    required this.adminId,
    required this.contactType,
    required this.notes,
  });
  @override
  List<Object?> get props => [alertId, contactType];
}

class RunMissedCheckInScan extends SafetyEvent {}

class RunMissedCheckOutScan extends SafetyEvent {}

// ── States ────────────────────────────────────────────────────────────────────

abstract class SafetyState extends Equatable {
  const SafetyState();
  @override
  List<Object?> get props => [];
}

class SafetyInitial extends SafetyState {}

class SafetyLoading extends SafetyState {}

class OpenAlertsLoaded extends SafetyState {
  final List<SafetyAlert> alerts;
  const OpenAlertsLoaded(this.alerts);
  @override
  List<Object?> get props => [alerts];
}

class BookingAlertsLoaded extends SafetyState {
  final List<SafetyAlert> alerts;
  const BookingAlertsLoaded(this.alerts);
  @override
  List<Object?> get props => [alerts];
}

class AlertCreated extends SafetyState {
  final SafetyAlert alert;
  const AlertCreated(this.alert);
  @override
  List<Object?> get props => [alert];
}

class AlertUpdated extends SafetyState {}

class ScanComplete extends SafetyState {
  final List<SafetyAlert> detected;
  const ScanComplete(this.detected);
  @override
  List<Object?> get props => [detected];
}

class SafetyError extends SafetyState {
  final String message;
  const SafetyError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

class SafetyBloc extends Bloc<SafetyEvent, SafetyState> {
  final SafetyRepository _repository;
  StreamSubscription<List<SafetyAlert>>? _alertsSubscription;

  SafetyBloc({required SafetyRepository repository})
    : _repository = repository,
      super(SafetyInitial()) {
    on<WatchOpenAlerts>(_onWatch);
    on<LoadBookingAlerts>(_onLoadBookingAlerts);
    on<TriggerSOS>(_onTriggerSOS);
    on<AcknowledgeAlert>(_onAcknowledge);
    on<ResolveAlert>(_onResolve);
    on<EscalateAlert>(_onEscalate);
    on<LogManualContact>(_onLogManualContact);
    on<RunMissedCheckInScan>(_onCheckInScan);
    on<RunMissedCheckOutScan>(_onCheckOutScan);
  }

  Future<void> _onWatch(
    WatchOpenAlerts event,
    Emitter<SafetyState> emit,
  ) async {
    await _alertsSubscription?.cancel();
    await emit.forEach(
      _repository.watchOpenAlerts(),
      onData: OpenAlertsLoaded.new,
      onError: (e, _) => SafetyError(e.toString()),
    );
  }

  Future<void> _onLoadBookingAlerts(
    LoadBookingAlerts event,
    Emitter<SafetyState> emit,
  ) async {
    emit(SafetyLoading());
    final result = await _repository.getAlertsForBooking(event.bookingId);
    result.fold(
      (f) => emit(SafetyError(f.message)),
      (alerts) => emit(BookingAlertsLoaded(alerts)),
    );
  }

  Future<void> _onTriggerSOS(
    TriggerSOS event,
    Emitter<SafetyState> emit,
  ) async {
    emit(SafetyLoading());
    final alert = SafetyAlert(
      id: '',
      bookingId: event.bookingId,
      workerId: event.workerId,
      customerId: event.customerId,
      type: AlertType.sosPanic,
      severity: AlertSeverity.critical,
      message: 'SOS triggered by worker during booking ${event.bookingId}',
      latitude: event.latitude,
      longitude: event.longitude,
      createdAt: DateTime.now(),
    );
    final result = await _repository.createAlert(alert);
    result.fold(
      (f) => emit(SafetyError(f.message)),
      (created) => emit(AlertCreated(created)),
    );
  }

  Future<void> _onAcknowledge(
    AcknowledgeAlert event,
    Emitter<SafetyState> emit,
  ) async {
    final result = await _repository.acknowledgeAlert(event.alertId);
    result.fold(
      (f) => emit(SafetyError(f.message)),
      (_) => emit(AlertUpdated()),
    );
  }

  Future<void> _onResolve(ResolveAlert event, Emitter<SafetyState> emit) async {
    final result = await _repository.resolveAlert(
      alertId: event.alertId,
      adminId: event.adminId,
      notes: event.notes,
    );
    result.fold(
      (f) => emit(SafetyError(f.message)),
      (_) => emit(AlertUpdated()),
    );
  }

  Future<void> _onEscalate(
    EscalateAlert event,
    Emitter<SafetyState> emit,
  ) async {
    final result = await _repository.escalateAlert(event.alertId);
    result.fold(
      (f) => emit(SafetyError(f.message)),
      (_) => emit(AlertUpdated()),
    );
  }

  Future<void> _onLogManualContact(
    LogManualContact event,
    Emitter<SafetyState> emit,
  ) async {
    final result = await _repository.logManualContact(
      alertId: event.alertId,
      adminId: event.adminId,
      contactType: event.contactType,
      notes: event.notes,
    );
    result.fold(
      (f) => emit(SafetyError(f.message)),
      (_) => emit(AlertUpdated()),
    );
  }

  Future<void> _onCheckInScan(
    RunMissedCheckInScan event,
    Emitter<SafetyState> emit,
  ) async {
    emit(SafetyLoading());
    final result = await _repository.detectMissedCheckIns();
    result.fold(
      (f) => emit(SafetyError(f.message)),
      (alerts) => emit(ScanComplete(alerts)),
    );
  }

  Future<void> _onCheckOutScan(
    RunMissedCheckOutScan event,
    Emitter<SafetyState> emit,
  ) async {
    emit(SafetyLoading());
    final result = await _repository.detectMissedCheckOuts();
    result.fold(
      (f) => emit(SafetyError(f.message)),
      (alerts) => emit(ScanComplete(alerts)),
    );
  }

  @override
  Future<void> close() {
    _alertsSubscription?.cancel();
    return super.close();
  }
}
