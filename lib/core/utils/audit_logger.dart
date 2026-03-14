import 'package:uuid/uuid.dart';

/// Centralized logging utility to create immutable audit trails
/// for PDPA and Labor Dispute protection.
class AuditLogger {
  // Use a singleton pattern for the logger
  static final AuditLogger _instance = AuditLogger._internal();
  factory AuditLogger() => _instance;
  AuditLogger._internal();

  // In production, swap with actual Firebase instance
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> logEvent({
    required String workerId,
    required String bookingId,
    required AuditEventType type,
    required Map<String, dynamic> payload,
  }) async {
    final String logId = const Uuid().v4();
    
    // Simulate saving to an immutable `/audit_logs` collection
    // final Map<String, dynamic> auditData = { ... };
    // await _firestore.collection('audit_logs').doc(logId).set(auditData);
    
    // ignore: avoid_print
    print('AUDIT LOG [$logId]: ${type.name} recorded for Worker $workerId');
  }

  /// Specialized method to log GPS check-ins
  Future<void> logGpsCheckIn({
    required String workerId,
    required String bookingId,
    required double latitude,
    required double longitude,
  }) async {
    await logEvent(
      workerId: workerId,
      bookingId: bookingId,
      type: AuditEventType.gpsCheckIn,
      payload: {
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  }

  /// Specialized method to log payout transfers
  Future<void> logPayout({
    required String workerId,
    required String bookingId,
    required double amount,
    required String transactionRef,
  }) async {
    await logEvent(
      workerId: workerId,
      bookingId: bookingId,
      type: AuditEventType.payoutTransfer,
      payload: {
        'amount': amount,
        'transactionRef': transactionRef,
        'currency': 'LKR'
      },
    );
  }
}

enum AuditEventType {
  contractAccepted,
  gpsCheckIn,
  jobAssigned,
  jobCompleted,
  payoutTransfer,
  incidentReported,
}
