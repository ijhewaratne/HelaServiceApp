import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/core/errors/failures.dart';
import 'package:home_service_app/features/incident/data/repositories/incident_repository_impl.dart';
import 'package:home_service_app/features/incident/domain/entities/incident.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late IncidentRepositoryImpl repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = IncidentRepositoryImpl(firestore);
  });

  group('IncidentRepositoryImpl', () {
    group('reportIncident', () {
      test('creates a Firestore document with expected fields', () async {
        final incident = Incident(
          id: '',
          reporterId: 'customer_1',
          reporterType: 'customer',
          jobId: 'job_1',
          type: IncidentType.safetyConcern,
          description: 'Worker was unsafe on site',
          reportedAt: DateTime(2026, 8),
        );

        final result = await repository.reportIncident(incident);

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected success'), (created) {
          expect(created.id, isNotEmpty);
          expect(created.reporterId, 'customer_1');
          expect(created.status, IncidentStatus.pending);
        });

        final snapshot = await firestore.collection('incidents').get();
        expect(snapshot.docs.length, 1);

        final stored = snapshot.docs.first;
        expect(stored.data()['reporterId'], 'customer_1');
        expect(stored.data()['reporterType'], 'customer');
        expect(stored.data()['jobId'], 'job_1');
        expect(stored.data()['type'], 'safetyConcern');
        expect(stored.data()['description'], 'Worker was unsafe on site');
        expect(stored.data()['status'], 'pending');
        expect(stored.data()['resolvedBy'], isNull);
        expect(stored.data()['resolvedAt'], isNull);
        expect(stored.data()['resolution'], isNull);
        expect(stored.data()['reportedAt'], isA<Timestamp>());
      });
    });

    group('getIncidentById', () {
      test('returns the incident when the document exists', () async {
        await firestore.collection('incidents').doc('incident_1').set({
          'reporterId': 'worker_1',
          'reporterType': 'worker',
          'jobId': 'job_9',
          'type': 'harassment',
          'description': 'Customer was abusive',
          'reportedAt': Timestamp.fromDate(DateTime(2026, 7, 15)),
          'status': 'investigating',
        });

        final result = await repository.getIncidentById('incident_1');

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected incident'), (incident) {
          expect(incident.id, 'incident_1');
          expect(incident.reporterId, 'worker_1');
          expect(incident.type, IncidentType.harassment);
          expect(incident.status, IncidentStatus.investigating);
        });
      });

      test('returns a failure when the document does not exist', () async {
        final result = await repository.getIncidentById('missing_incident');

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<Failure>());
          expect(failure.message, 'Incident not found');
        }, (_) => fail('Expected failure'));
      });
    });

    group('updateIncidentStatus', () {
      test(
        'transitions pending -> investigating without setting resolvedAt',
        () async {
          await firestore.collection('incidents').doc('incident_1').set({
            'reporterId': 'customer_1',
            'reporterType': 'customer',
            'type': 'serviceIssue',
            'description': 'Service was incomplete',
            'reportedAt': Timestamp.fromDate(DateTime(2026, 7)),
            'status': 'pending',
          });

          final result = await repository.updateIncidentStatus(
            incidentId: 'incident_1',
            status: IncidentStatus.investigating,
          );

          expect(result.isRight(), isTrue);
          result.fold((_) => fail('Expected success'), (incident) {
            expect(incident.status, IncidentStatus.investigating);
            expect(incident.resolvedAt, isNull);
            expect(incident.resolvedBy, isNull);
          });

          final stored = await firestore
              .collection('incidents')
              .doc('incident_1')
              .get();
          expect(stored.data()?['status'], 'investigating');
          expect(stored.data()?['resolvedAt'], isNull);
        },
      );

      test(
        'transitions investigating -> resolved and sets resolvedAt/resolvedBy/resolution',
        () async {
          await firestore.collection('incidents').doc('incident_1').set({
            'reporterId': 'customer_1',
            'reporterType': 'customer',
            'type': 'serviceIssue',
            'description': 'Service was incomplete',
            'reportedAt': Timestamp.fromDate(DateTime(2026, 7)),
            'status': 'investigating',
          });

          final result = await repository.updateIncidentStatus(
            incidentId: 'incident_1',
            status: IncidentStatus.resolved,
            resolution: 'Refund issued to customer',
            resolvedBy: 'admin_1',
          );

          expect(result.isRight(), isTrue);
          result.fold((_) => fail('Expected success'), (incident) {
            expect(incident.status, IncidentStatus.resolved);
            expect(incident.resolution, 'Refund issued to customer');
            expect(incident.resolvedBy, 'admin_1');
            expect(incident.resolvedAt, isNotNull);
          });

          final stored = await firestore
              .collection('incidents')
              .doc('incident_1')
              .get();
          expect(stored.data()?['status'], 'resolved');
          expect(stored.data()?['resolution'], 'Refund issued to customer');
          expect(stored.data()?['resolvedBy'], 'admin_1');
          expect(stored.data()?['resolvedAt'], isA<Timestamp>());
        },
      );

      test('does not set resolvedAt when resolvedBy is omitted', () async {
        await firestore.collection('incidents').doc('incident_1').set({
          'reporterId': 'customer_1',
          'reporterType': 'customer',
          'type': 'serviceIssue',
          'description': 'Service was incomplete',
          'reportedAt': Timestamp.fromDate(DateTime(2026, 7)),
          'status': 'investigating',
        });

        final result = await repository.updateIncidentStatus(
          incidentId: 'incident_1',
          status: IncidentStatus.resolved,
          resolution: 'Resolved without an assignee',
        );

        expect(result.isRight(), isTrue);

        final stored = await firestore
            .collection('incidents')
            .doc('incident_1')
            .get();
        expect(stored.data()?['status'], 'resolved');
        expect(stored.data()?['resolution'], 'Resolved without an assignee');
        expect(stored.data()?['resolvedBy'], isNull);
        expect(stored.data()?['resolvedAt'], isNull);
      });
    });

    group('getAllIncidents', () {
      setUp(() async {
        await firestore.collection('incidents').doc('incident_pending').set({
          'reporterId': 'customer_1',
          'reporterType': 'customer',
          'type': 'serviceIssue',
          'description': 'Pending incident',
          'reportedAt': Timestamp.fromDate(DateTime(2026, 6)),
          'status': 'pending',
        });
        await firestore
            .collection('incidents')
            .doc('incident_investigating')
            .set({
              'reporterId': 'customer_2',
              'reporterType': 'customer',
              'type': 'harassment',
              'description': 'Investigating incident',
              'reportedAt': Timestamp.fromDate(DateTime(2026, 6, 2)),
              'status': 'investigating',
            });
        await firestore.collection('incidents').doc('incident_resolved').set({
          'reporterId': 'worker_1',
          'reporterType': 'worker',
          'type': 'paymentDispute',
          'description': 'Resolved incident',
          'reportedAt': Timestamp.fromDate(DateTime(2026, 6, 3)),
          'status': 'resolved',
        });
      });

      test('returns all incidents when no status filter is provided', () async {
        final result = await repository.getAllIncidents();

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected incidents'),
          (incidents) => expect(incidents.length, 3),
        );
      });

      test('filters incidents by status', () async {
        final result = await repository.getAllIncidents(
          status: IncidentStatus.pending,
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected incidents'), (incidents) {
          expect(incidents.length, 1);
          expect(incidents.single.id, 'incident_pending');
          expect(incidents.single.status, IncidentStatus.pending);
        });
      });

      test(
        'returns an empty list when no incidents match the status filter',
        () async {
          final result = await repository.getAllIncidents(
            status: IncidentStatus.escalated,
          );

          expect(result.isRight(), isTrue);
          result.fold(
            (_) => fail('Expected empty list'),
            (incidents) => expect(incidents, isEmpty),
          );
        },
      );
    });

    group('getUserIncidents', () {
      test(
        'returns only incidents reported by the given user, newest first',
        () async {
          await firestore.collection('incidents').doc('incident_old').set({
            'reporterId': 'customer_1',
            'reporterType': 'customer',
            'type': 'serviceIssue',
            'description': 'Older incident',
            'reportedAt': Timestamp.fromDate(DateTime(2026, 5)),
            'status': 'pending',
          });
          await firestore.collection('incidents').doc('incident_new').set({
            'reporterId': 'customer_1',
            'reporterType': 'customer',
            'type': 'harassment',
            'description': 'Newer incident',
            'reportedAt': Timestamp.fromDate(DateTime(2026, 5, 10)),
            'status': 'pending',
          });
          await firestore
              .collection('incidents')
              .doc('incident_other_user')
              .set({
                'reporterId': 'customer_2',
                'reporterType': 'customer',
                'type': 'other',
                'description': 'Someone else entirely',
                'reportedAt': Timestamp.fromDate(DateTime(2026, 5, 5)),
                'status': 'pending',
              });

          final result = await repository.getUserIncidents('customer_1');

          expect(result.isRight(), isTrue);
          result.fold((_) => fail('Expected incidents'), (incidents) {
            expect(incidents.length, 2);
            expect(
              incidents.every((i) => i.reporterId == 'customer_1'),
              isTrue,
            );
            expect(incidents.first.id, 'incident_new');
            expect(incidents.last.id, 'incident_old');
          });
        },
      );
    });
  });
}
