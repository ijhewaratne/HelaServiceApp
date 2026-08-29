import 'package:equatable/equatable.dart';

import '../../../worker/domain/entities/worker_profile.dart';
import '../../../customer/domain/booking.dart';
import '../../../incident/domain/entities/incident.dart';
import '../../data/admin_repository.dart';

class AdminState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<WorkerProfile> pendingWorkers;
  final List<Booking> activeBookings;
  final List<Incident> openIncidents;
  final List<BlueTierVerification> blueTierPending;

  const AdminState({
    this.isLoading = false,
    this.errorMessage,
    this.pendingWorkers = const [],
    this.activeBookings = const [],
    this.openIncidents = const [],
    this.blueTierPending = const [],
  });

  factory AdminState.initial() => const AdminState();

  AdminState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<WorkerProfile>? pendingWorkers,
    List<Booking>? activeBookings,
    List<Incident>? openIncidents,
    List<BlueTierVerification>? blueTierPending,
  }) {
    return AdminState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      pendingWorkers: pendingWorkers ?? this.pendingWorkers,
      activeBookings: activeBookings ?? this.activeBookings,
      openIncidents: openIncidents ?? this.openIncidents,
      blueTierPending: blueTierPending ?? this.blueTierPending,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        pendingWorkers,
        activeBookings,
        openIncidents,
        blueTierPending,
      ];
}
