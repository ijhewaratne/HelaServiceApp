import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/features/admin/data/admin_repository.dart';
import 'package:home_service_app/features/incident/domain/entities/incident.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late AdminRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = AdminRepository(firestore: firestore);
  });

  group('rejectBlueTierUpgrade', () {
    test('marks the worker verificationStatus as rejected, not approved',
        () async {
      await firestore.collection('worker_verifications').doc('worker_1').set({
        'status': 'pending_review',
        'requestedTier': 'blue',
      });
      await firestore.collection('workers').doc('worker_1').set({
        'verificationStatus': 'pending_review',
      });

      final result = await repository.rejectBlueTierUpgrade(
        'worker_1',
        'Reference gave negative feedback',
      );

      expect(result.isRight(), isTrue);

      final verificationDoc = await firestore
          .collection('worker_verifications')
          .doc('worker_1')
          .get();
      expect(verificationDoc.data()?['status'], 'rejected');
      expect(verificationDoc.data()?['rejectionReason'],
          'Reference gave negative feedback');

      final workerDoc =
          await firestore.collection('workers').doc('worker_1').get();
      expect(workerDoc.data()?['verificationStatus'], 'rejected');
    });
  });

  group('approveBlueTierUpgrade', () {
    test('sets verification approved and worker tier to blue', () async {
      await firestore.collection('worker_verifications').doc('worker_2').set({
        'status': 'pending_review',
      });
      await firestore.collection('workers').doc('worker_2').set({
        'verificationTier': 'green',
      });

      final result = await repository.approveBlueTierUpgrade('worker_2');

      expect(result.isRight(), isTrue);

      final verificationDoc = await firestore
          .collection('worker_verifications')
          .doc('worker_2')
          .get();
      expect(verificationDoc.data()?['status'], 'approved');
      expect(verificationDoc.data()?['currentTier'], 'blue');

      final workerDoc =
          await firestore.collection('workers').doc('worker_2').get();
      expect(workerDoc.data()?['verificationTier'], 'blue');
    });
  });

  group('getPendingWorkers', () {
    test('returns only workers pending review or with submitted documents',
        () async {
      await firestore.collection('workers').doc('pending').set({
        'verificationStatus': 'pending_review',
        'fullName': 'Pending Worker',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });
      await firestore.collection('workers').doc('submitted').set({
        'verificationStatus': 'documents_submitted',
        'fullName': 'Submitted Worker',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 2)),
      });
      await firestore.collection('workers').doc('approved').set({
        'verificationStatus': 'approved',
        'fullName': 'Approved Worker',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 3)),
      });

      final result = await repository.getPendingWorkers();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected a list of pending workers'),
        (workers) {
          expect(workers.length, 2);
          expect(
            workers.map((w) => w.uid),
            containsAll(['pending', 'submitted']),
          );
          expect(workers.any((w) => w.uid == 'approved'), isFalse);
        },
      );
    });
  });

  group('getOpenIncidents', () {
    test('maps Firestore documents to Incident entities and excludes resolved',
        () async {
      await firestore.collection('incidents').doc('open_1').set({
        'reporterId': 'customer_1',
        'reporterType': 'customer',
        'type': 'sosPanic',
        'description': 'Emergency',
        'status': 'pending',
        'reportedAt': Timestamp.fromDate(DateTime(2026, 3, 1)),
      });
      await firestore.collection('incidents').doc('resolved_1').set({
        'reporterId': 'customer_2',
        'reporterType': 'customer',
        'type': 'customerReport',
        'description': 'Already handled',
        'status': 'resolved',
        'reportedAt': Timestamp.fromDate(DateTime(2026, 3, 2)),
      });

      final result = await repository.getOpenIncidents();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected a list of open incidents'),
        (incidents) {
          expect(incidents.length, 1);
          expect(incidents.first.id, 'open_1');
          expect(incidents.first.status, IncidentStatus.pending);
        },
      );
    });
  });

  group('updateIncidentStatus', () {
    test('setting status to resolved records resolvedAt and resolution',
        () async {
      await firestore.collection('incidents').doc('incident_1').set({
        'reporterId': 'customer_1',
        'reporterType': 'customer',
        'type': 'other',
        'description': 'Something happened',
        'status': 'investigating',
        'reportedAt': Timestamp.fromDate(DateTime(2026, 3, 1)),
      });

      final result = await repository.updateIncidentStatus(
        incidentId: 'incident_1',
        status: IncidentStatus.resolved,
        resolution: 'Resolved after review',
        resolvedBy: 'admin_1',
      );

      expect(result.isRight(), isTrue);

      final doc =
          await firestore.collection('incidents').doc('incident_1').get();
      expect(doc.data()?['status'], 'resolved');
      expect(doc.data()?['resolution'], 'Resolved after review');
      expect(doc.data()?['resolvedBy'], 'admin_1');
      expect(doc.data()?['resolvedAt'], isNotNull);
    });
  });

  group('assignWorkerToBooking', () {
    test('updates the booking and mirrors assignment onto job_requests',
        () async {
      await firestore.collection('bookings').doc('booking_1').set({
        'status': 'pending',
        'customerId': 'customer_1',
      });

      final result =
          await repository.assignWorkerToBooking('booking_1', 'worker_5');

      expect(result.isRight(), isTrue);

      final bookingDoc =
          await firestore.collection('bookings').doc('booking_1').get();
      expect(bookingDoc.data()?['workerId'], 'worker_5');
      expect(bookingDoc.data()?['status'], 'workerAssigned');

      final jobRequestDoc =
          await firestore.collection('job_requests').doc('booking_1').get();
      expect(jobRequestDoc.data()?['assignedWorkerId'], 'worker_5');
      expect(jobRequestDoc.data()?['status'], 'accepted');
    });
  });
}
