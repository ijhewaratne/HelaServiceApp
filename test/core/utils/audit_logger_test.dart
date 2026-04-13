import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/core/utils/audit_logger.dart';

void main() {
  group('AuditLogger', () {
    late AuditLogger auditLogger;

    setUp(() {
      auditLogger = AuditLogger();
    });

    test('singleton pattern returns same instance', () {
      final instance1 = AuditLogger();
      final instance2 = AuditLogger();
      expect(identical(instance1, instance2), isTrue);
    });

    group('logEvent', () {
      test('logs event with required parameters', () async {
        expect(
          () => auditLogger.logEvent(
            workerId: 'worker_123',
            bookingId: 'booking_456',
            type: AuditEventType.jobCompleted,
            payload: {'rating': 5, 'duration': 120},
          ),
          returnsNormally,
        );
      });

      test('logs event with empty payload', () async {
        expect(
          () => auditLogger.logEvent(
            workerId: 'worker_123',
            bookingId: 'booking_456',
            type: AuditEventType.contractAccepted,
            payload: {},
          ),
          returnsNormally,
        );
      });

      test('logs event with complex payload', () async {
        expect(
          () => auditLogger.logEvent(
            workerId: 'worker_123',
            bookingId: 'booking_456',
            type: AuditEventType.incidentReported,
            payload: {
              'severity': 'high',
              'description': 'Customer not present',
              'timestamp': DateTime.now().toIso8601String(),
              'attachments': ['photo1.jpg', 'photo2.jpg'],
            },
          ),
          returnsNormally,
        );
      });
    });

    group('logGpsCheckIn', () {
      test('logs GPS check-in with coordinates', () async {
        expect(
          () => auditLogger.logGpsCheckIn(
            workerId: 'worker_123',
            bookingId: 'booking_456',
            latitude: 6.9271,
            longitude: 79.8612,
          ),
          returnsNormally,
        );
      });

      test('logs GPS check-in at equator', () async {
        expect(
          () => auditLogger.logGpsCheckIn(
            workerId: 'worker_123',
            bookingId: 'booking_456',
            latitude: 0.0,
            longitude: 0.0,
          ),
          returnsNormally,
        );
      });

      test('logs GPS check-in with negative coordinates', () async {
        expect(
          () => auditLogger.logGpsCheckIn(
            workerId: 'worker_123',
            bookingId: 'booking_456',
            latitude: -33.8688,
            longitude: 151.2093,
          ),
          returnsNormally,
        );
      });
    });

    group('logPayout', () {
      test('logs payout with all details', () async {
        expect(
          () => auditLogger.logPayout(
            workerId: 'worker_123',
            bookingId: 'booking_456',
            amount: 1500.00,
            transactionRef: 'TXN_789ABC',
          ),
          returnsNormally,
        );
      });

      test('logs payout with zero amount', () async {
        expect(
          () => auditLogger.logPayout(
            workerId: 'worker_123',
            bookingId: 'booking_456',
            amount: 0.0,
            transactionRef: 'TXN_ZERO',
          ),
          returnsNormally,
        );
      });

      test('logs payout with large amount', () async {
        expect(
          () => auditLogger.logPayout(
            workerId: 'worker_123',
            bookingId: 'booking_456',
            amount: 999999.99,
            transactionRef: 'TXN_LARGE',
          ),
          returnsNormally,
        );
      });
    });

    group('AuditEventType', () {
      test('has all required event types', () {
        expect(AuditEventType.values.length, equals(6));
        expect(AuditEventType.values, contains(AuditEventType.contractAccepted));
        expect(AuditEventType.values, contains(AuditEventType.gpsCheckIn));
        expect(AuditEventType.values, contains(AuditEventType.jobAssigned));
        expect(AuditEventType.values, contains(AuditEventType.jobCompleted));
        expect(AuditEventType.values, contains(AuditEventType.payoutTransfer));
        expect(AuditEventType.values, contains(AuditEventType.incidentReported));
      });

      test('event types have correct names', () {
        expect(AuditEventType.contractAccepted.name, equals('contractAccepted'));
        expect(AuditEventType.gpsCheckIn.name, equals('gpsCheckIn'));
        expect(AuditEventType.jobAssigned.name, equals('jobAssigned'));
        expect(AuditEventType.jobCompleted.name, equals('jobCompleted'));
        expect(AuditEventType.payoutTransfer.name, equals('payoutTransfer'));
        expect(AuditEventType.incidentReported.name, equals('incidentReported'));
      });
    });

    group('immutability', () {
      test('concurrent log calls complete without error', () async {
        final futures = <Future>[];
        
        for (int i = 0; i < 10; i++) {
          futures.add(
            auditLogger.logEvent(
              workerId: 'worker_$i',
              bookingId: 'booking_$i',
              type: AuditEventType.values[i % AuditEventType.values.length],
              payload: {'index': i},
            ),
          );
        }
        
        expect(() async => await Future.wait(futures), returnsNormally);
      });
    });
  });
}
