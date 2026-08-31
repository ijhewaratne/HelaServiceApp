import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/core/errors/failures.dart';
import 'package:home_service_app/features/safety/data/repositories/safety_repository_impl.dart';
import 'package:home_service_app/features/safety/domain/entities/safety_alert.dart';

// NOTE ON SCHEMA: SafetyRepositoryImpl reads/writes the `safety_alerts`
// collection using the same field names
// (`status`, `severity`, `type`, `resolvedBy`, etc.) that
// lib/features/admin/presentation/screens/admin_dashboard_screen.dart reads
// and writes directly via `sl<FirebaseFirestore>().collection('safety_alerts')`.
// So this repository and the admin screen agree on one shared schema/collection
// — there is no schema split between them. The client-writable-schema risk
// flagged in review is that the admin screen (and, to a lesser extent, this
// repository) write directly to Firestore with fields like `status` and
// `resolvedBy` that are trusted at face value; nothing here enforces that only
// legitimate admins can set them (that's a Firestore security-rules concern,
// not something these unit tests can exercise against FakeFirebaseFirestore,
// which does not evaluate security rules). These tests only verify current
// repository behavior, not the security posture of the shared schema.

void main() {
  late FakeFirebaseFirestore firestore;
  late SafetyRepositoryImpl repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = SafetyRepositoryImpl(firestore: firestore);
  });

  SafetyAlert buildAlert({
    String id = '',
    String bookingId = 'booking_1',
    String workerId = 'worker_1',
    String customerId = 'customer_1',
    AlertType type = AlertType.sosPanic,
    AlertSeverity severity = AlertSeverity.critical,
    String message = 'Worker triggered SOS',
  }) {
    return SafetyAlert(
      id: id,
      bookingId: bookingId,
      workerId: workerId,
      customerId: customerId,
      type: type,
      severity: severity,
      message: message,
      createdAt: DateTime(2026, 8, 29, 10, 0),
    );
  }

  group('createAlert', () {
    test('stores a new alert document with expected fields', () async {
      final alert = buildAlert();

      final result = await repository.createAlert(alert);

      expect(result.isRight(), isTrue);
      final created = result.fold((_) => throw Exception(), (a) => a);
      expect(created.id, isNotEmpty);

      final stored = await firestore
          .collection('safety_alerts')
          .doc(created.id)
          .get();
      expect(stored.exists, isTrue);
      final data = stored.data()!;
      expect(data['bookingId'], 'booking_1');
      expect(data['workerId'], 'worker_1');
      expect(data['customerId'], 'customer_1');
      expect(data['type'], 'sosPanic');
      expect(data['severity'], 'critical');
      expect(data['status'], 'open');
      expect(data['message'], 'Worker triggered SOS');
    });

    test('uses the provided id instead of generating one when set', () async {
      final alert = buildAlert(id: 'fixed_alert_id');

      final result = await repository.createAlert(alert);

      expect(result.isRight(), isTrue);
      final created = result.fold((_) => throw Exception(), (a) => a);
      expect(created.id, 'fixed_alert_id');

      final stored = await firestore
          .collection('safety_alerts')
          .doc('fixed_alert_id')
          .get();
      expect(stored.exists, isTrue);
    });
  });

  group('acknowledgeAlert', () {
    test('updates status to acknowledged and stamps acknowledgedAt', () async {
      await firestore
          .collection('safety_alerts')
          .doc('alert_1')
          .set(buildAlert(id: 'alert_1').toJson());

      final result = await repository.acknowledgeAlert('alert_1');

      expect(result.isRight(), isTrue);
      final stored = await firestore
          .collection('safety_alerts')
          .doc('alert_1')
          .get();
      expect(stored.data()?['status'], 'acknowledged');
      expect(stored.data()?['acknowledgedAt'], isNotNull);
    });
  });

  group('resolveAlert', () {
    test(
      'updates status, resolvedBy, resolutionNotes and resolvedAt',
      () async {
        await firestore
            .collection('safety_alerts')
            .doc('alert_1')
            .set(buildAlert(id: 'alert_1').toJson());

        final result = await repository.resolveAlert(
          alertId: 'alert_1',
          adminId: 'admin_42',
          notes: 'False alarm, confirmed with worker by phone.',
        );

        expect(result.isRight(), isTrue);
        final stored = await firestore
            .collection('safety_alerts')
            .doc('alert_1')
            .get();
        expect(stored.data()?['status'], 'resolved');
        expect(stored.data()?['resolvedBy'], 'admin_42');
        expect(
          stored.data()?['resolutionNotes'],
          'False alarm, confirmed with worker by phone.',
        );
        expect(stored.data()?['resolvedAt'], isNotNull);
      },
    );
  });

  group('escalateAlert', () {
    test('returns ServerFailure when the alert does not exist', () async {
      final result = await repository.escalateAlert('missing_alert');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Expected failure'),
      );
    });

    test(
      'sets status to escalated and collects emergency contacts from worker and customer',
      () async {
        await firestore
            .collection('safety_alerts')
            .doc('alert_1')
            .set(buildAlert(id: 'alert_1').toJson());
        await firestore.collection('workers').doc('worker_1').set({
          'emergencyContactName': 'Worker EC',
          'emergencyContactPhone': '+94770000001',
        });
        await firestore.collection('customer_profiles').doc('customer_1').set({
          'emergencyContactName': 'Customer EC',
          'emergencyContactPhone': '+94770000002',
        });

        final result = await repository.escalateAlert('alert_1');

        expect(result.isRight(), isTrue);
        final stored = await firestore
            .collection('safety_alerts')
            .doc('alert_1')
            .get();
        final data = stored.data()!;
        expect(data['status'], 'escalated');
        expect(data['escalatedAt'], isNotNull);

        final contacts = List<Map<String, dynamic>>.from(
          data['escalationContacts'] as List,
        );
        expect(contacts.length, 2);
        expect(
          contacts.any(
            (c) =>
                c['role'] == 'workerEmergency' && c['phone'] == '+94770000001',
          ),
          isTrue,
        );
        expect(
          contacts.any(
            (c) =>
                c['role'] == 'customerEmergency' &&
                c['phone'] == '+94770000002',
          ),
          isTrue,
        );

        final attempts = List<Map<String, dynamic>>.from(
          data['escalationAttempts'] as List,
        );
        expect(attempts, isNotEmpty);
        expect(attempts.last['method'], 'push');
      },
    );

    test('skips contacts with no emergency phone on file', () async {
      await firestore
          .collection('safety_alerts')
          .doc('alert_1')
          .set(buildAlert(id: 'alert_1').toJson());
      await firestore.collection('workers').doc('worker_1').set({
        'emergencyContactName': 'Worker EC',
        'emergencyContactPhone': '',
      });

      final result = await repository.escalateAlert('alert_1');

      expect(result.isRight(), isTrue);
      final stored = await firestore
          .collection('safety_alerts')
          .doc('alert_1')
          .get();
      final contacts = List<Map<String, dynamic>>.from(
        stored.data()?['escalationContacts'] as List,
      );
      expect(contacts, isEmpty);
    });
  });

  group('logManualContact', () {
    test('appends a manual contact attempt to escalationAttempts', () async {
      await firestore
          .collection('safety_alerts')
          .doc('alert_1')
          .set(buildAlert(id: 'alert_1').toJson());

      final result = await repository.logManualContact(
        alertId: 'alert_1',
        adminId: 'admin_42',
        contactType: 'phone',
        notes: 'Called worker emergency contact, no answer.',
      );

      expect(result.isRight(), isTrue);
      final stored = await firestore
          .collection('safety_alerts')
          .doc('alert_1')
          .get();
      final attempts = List<Map<String, dynamic>>.from(
        stored.data()?['escalationAttempts'] as List,
      );
      expect(attempts, hasLength(1));
      expect(attempts.first['method'], 'phone');
      expect(attempts.first['calledBy'], 'admin_42');
    });
  });

  group('getOpenAlerts / getAlertsForBooking', () {
    test('getOpenAlerts only returns alerts with status open', () async {
      await firestore
          .collection('safety_alerts')
          .doc('open_1')
          .set(buildAlert(id: 'open_1').toJson());
      await firestore
          .collection('safety_alerts')
          .doc('resolved_1')
          .set(
            buildAlert(
              id: 'resolved_1',
            ).copyWith(status: AlertStatus.resolved).toJson(),
          );

      final result = await repository.getOpenAlerts();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected alerts'), (alerts) {
        expect(alerts, hasLength(1));
        expect(alerts.single.id, 'open_1');
      });
    });

    test('getAlertsForBooking filters by bookingId', () async {
      await firestore
          .collection('safety_alerts')
          .doc('a1')
          .set(buildAlert(id: 'a1', bookingId: 'booking_A').toJson());
      await firestore
          .collection('safety_alerts')
          .doc('a2')
          .set(buildAlert(id: 'a2', bookingId: 'booking_B').toJson());

      final result = await repository.getAlertsForBooking('booking_A');

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected alerts'), (alerts) {
        expect(alerts, hasLength(1));
        expect(alerts.single.bookingId, 'booking_A');
      });
    });
  });

  group('detectMissedCheckIns', () {
    test(
      'creates an alert for a workerArrived booking whose scheduled start is past the grace period',
      () async {
        final now = DateTime.now();
        await firestore.collection('bookings').doc('booking_late').set({
          'status': 'workerArrived',
          'workerId': 'worker_1',
          'customerId': 'customer_1',
          'checkIn': null,
          'scheduledDate': Timestamp.fromDate(
            now.subtract(const Duration(minutes: 20)),
          ),
        });

        final result = await repository.detectMissedCheckIns(
          gracePeriod: const Duration(minutes: 15),
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('expected alerts'), (created) {
          expect(created, hasLength(1));
          expect(created.single.bookingId, 'booking_late');
          expect(created.single.type, AlertType.missedCheckIn);
        });

        final alertsSnap = await firestore
            .collection('safety_alerts')
            .where('bookingId', isEqualTo: 'booking_late')
            .get();
        expect(alertsSnap.docs, hasLength(1));
      },
    );

    test(
      'does not create an alert while still within the grace period (boundary)',
      () async {
        final now = DateTime.now();
        // Scheduled only 30s ago; well within a 1-minute grace period.
        await firestore.collection('bookings').doc('booking_recent').set({
          'status': 'workerArrived',
          'workerId': 'worker_1',
          'customerId': 'customer_1',
          'checkIn': null,
          'scheduledDate': Timestamp.fromDate(
            now.subtract(const Duration(seconds: 30)),
          ),
        });

        final result = await repository.detectMissedCheckIns(
          gracePeriod: const Duration(minutes: 1),
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('expected list'), (created) {
          expect(created, isEmpty);
        });
      },
    );

    test(
      'creates an alert once the scheduled start is past a short grace period (boundary)',
      () async {
        final now = DateTime.now();
        // Scheduled 65s ago against a 1-minute grace period: past the cutoff.
        await firestore.collection('bookings').doc('booking_boundary').set({
          'status': 'workerArrived',
          'workerId': 'worker_1',
          'customerId': 'customer_1',
          'checkIn': null,
          'scheduledDate': Timestamp.fromDate(
            now.subtract(const Duration(seconds: 65)),
          ),
        });

        final result = await repository.detectMissedCheckIns(
          gracePeriod: const Duration(minutes: 1),
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('expected list'), (created) {
          expect(created, hasLength(1));
          expect(created.single.bookingId, 'booking_boundary');
        });
      },
    );

    test('skips bookings that already have a checkIn recorded', () async {
      final now = DateTime.now();
      await firestore.collection('bookings').doc('booking_checked_in').set({
        'status': 'workerArrived',
        'workerId': 'worker_1',
        'customerId': 'customer_1',
        'checkIn': Timestamp.fromDate(
          now.subtract(const Duration(minutes: 10)),
        ),
        'scheduledDate': Timestamp.fromDate(
          now.subtract(const Duration(minutes: 30)),
        ),
      });

      final result = await repository.detectMissedCheckIns();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected list'), (created) {
        expect(created, isEmpty);
      });
    });

    test('skips bookings that are not in workerArrived status', () async {
      final now = DateTime.now();
      await firestore.collection('bookings').doc('booking_in_progress').set({
        'status': 'inProgress',
        'workerId': 'worker_1',
        'customerId': 'customer_1',
        'checkIn': null,
        'scheduledDate': Timestamp.fromDate(
          now.subtract(const Duration(minutes: 30)),
        ),
      });

      final result = await repository.detectMissedCheckIns();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected list'), (created) {
        expect(created, isEmpty);
      });
    });

    test(
      'does not duplicate an alert if one already exists for the booking',
      () async {
        final now = DateTime.now();
        await firestore.collection('bookings').doc('booking_dup').set({
          'status': 'workerArrived',
          'workerId': 'worker_1',
          'customerId': 'customer_1',
          'checkIn': null,
          'scheduledDate': Timestamp.fromDate(
            now.subtract(const Duration(minutes: 30)),
          ),
        });
        await firestore
            .collection('safety_alerts')
            .doc('existing_alert')
            .set(
              buildAlert(
                id: 'existing_alert',
                bookingId: 'booking_dup',
                type: AlertType.missedCheckIn,
              ).toJson(),
            );

        final result = await repository.detectMissedCheckIns();

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('expected list'), (created) {
          expect(created, isEmpty);
        });

        final alertsSnap = await firestore
            .collection('safety_alerts')
            .where('bookingId', isEqualTo: 'booking_dup')
            .get();
        expect(alertsSnap.docs, hasLength(1));
      },
    );
  });

  group('detectMissedCheckOuts', () {
    test(
      'creates an alert using the schedule.endTime when past the grace period',
      () async {
        final now = DateTime.now();
        // End time computed as "5 minutes ago" using today's date + explicit HH:mm.
        final expectedEnd = now.subtract(const Duration(minutes: 40));
        final endTimeStr =
            '${expectedEnd.hour.toString().padLeft(2, '0')}:${expectedEnd.minute.toString().padLeft(2, '0')}';

        await firestore.collection('bookings').doc('booking_co_1').set({
          'status': 'inProgress',
          'workerId': 'worker_1',
          'customerId': 'customer_1',
          'checkOut': null,
          'schedule': {
            'date': Timestamp.fromDate(
              DateTime(expectedEnd.year, expectedEnd.month, expectedEnd.day),
            ),
            'endTime': endTimeStr,
          },
        });

        final result = await repository.detectMissedCheckOuts(
          gracePeriod: const Duration(minutes: 30),
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('expected list'), (created) {
          expect(created, hasLength(1));
          expect(created.single.type, AlertType.missedCheckOut);
          expect(created.single.bookingId, 'booking_co_1');
        });
      },
    );

    test(
      'falls back to scheduledDate + durationHours when schedule map is absent',
      () async {
        final now = DateTime.now();
        // scheduledDate 3 hours ago + 1 hour duration => expected end 2h ago.
        await firestore.collection('bookings').doc('booking_co_2').set({
          'status': 'inProgress',
          'workerId': 'worker_1',
          'customerId': 'customer_1',
          'checkOut': null,
          'scheduledDate': Timestamp.fromDate(
            now.subtract(const Duration(hours: 3)),
          ),
          'durationHours': 1,
        });

        final result = await repository.detectMissedCheckOuts(
          gracePeriod: const Duration(minutes: 30),
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('expected list'), (created) {
          expect(created, hasLength(1));
          expect(created.single.bookingId, 'booking_co_2');
        });
      },
    );

    test(
      'does not flag a booking whose expected end is still within the grace period (boundary)',
      () async {
        final now = DateTime.now();
        // scheduledDate 1 hour ago + 1 hour duration => expected end "now" (not yet passed).
        await firestore.collection('bookings').doc('booking_co_3').set({
          'status': 'inProgress',
          'workerId': 'worker_1',
          'customerId': 'customer_1',
          'checkOut': null,
          'scheduledDate': Timestamp.fromDate(
            now.subtract(const Duration(hours: 1)),
          ),
          'durationHours': 1,
        });

        final result = await repository.detectMissedCheckOuts(
          gracePeriod: const Duration(minutes: 30),
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('expected list'), (created) {
          expect(created, isEmpty);
        });
      },
    );

    test('skips bookings that already have a checkOut recorded', () async {
      final now = DateTime.now();
      await firestore.collection('bookings').doc('booking_co_done').set({
        'status': 'inProgress',
        'workerId': 'worker_1',
        'customerId': 'customer_1',
        'checkOut': Timestamp.fromDate(
          now.subtract(const Duration(minutes: 5)),
        ),
        'scheduledDate': Timestamp.fromDate(
          now.subtract(const Duration(hours: 3)),
        ),
        'durationHours': 1,
      });

      final result = await repository.detectMissedCheckOuts();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected list'), (created) {
        expect(created, isEmpty);
      });
    });
  });
}
