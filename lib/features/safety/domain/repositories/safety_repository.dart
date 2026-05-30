import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/safety_alert.dart';

abstract class SafetyRepository {
  /// Create a new safety alert
  Future<Either<Failure, SafetyAlert>> createAlert(SafetyAlert alert);

  /// Fetch all open alerts (admin view)
  Future<Either<Failure, List<SafetyAlert>>> getOpenAlerts();

  /// Fetch all alerts for a specific booking
  Future<Either<Failure, List<SafetyAlert>>> getAlertsForBooking(
      String bookingId);

  /// Acknowledge an alert (admin)
  Future<Either<Failure, void>> acknowledgeAlert(String alertId);

  /// Resolve an alert with notes (admin)
  Future<Either<Failure, void>> resolveAlert({
    required String alertId,
    required String adminId,
    required String notes,
  });

  /// Escalate an alert
  Future<Either<Failure, void>> escalateAlert(String alertId);

  /// Live stream of open alerts for admin dashboard
  Stream<List<SafetyAlert>> watchOpenAlerts();

  /// Scan for bookings with missed check-ins and create alerts for them.
  /// Called periodically (e.g. from a Cloud Function or a background isolate).
  Future<Either<Failure, List<SafetyAlert>>> detectMissedCheckIns({
    Duration gracePeriod = const Duration(minutes: 15),
  });

  /// Scan for bookings with missed check-outs and create alerts.
  Future<Either<Failure, List<SafetyAlert>>> detectMissedCheckOuts({
    Duration gracePeriod = const Duration(minutes: 30),
  });
}
