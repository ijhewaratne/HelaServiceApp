import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/features/job/domain/entities/job.dart';
import 'package:home_service_app/features/worker/domain/entities/worker.dart';

void main() {
  Job buildJob({JobStatus status = JobStatus.searching}) {
    return Job(
      id: 'job_1',
      customerId: 'customer_1',
      serviceType: ServiceType.cleaning,
      locationLat: 6.9271,
      locationLng: 79.8612,
      zoneId: 'colombo',
      status: status,
      createdAt: DateTime(2026, 1, 1, 9, 0),
      estimatedEarnings: 1500.0,
      houseNumber: '12/A',
      landmark: 'Near Arpico Supercentre',
    );
  }

  group('toMap / fromMap round trip', () {
    test('preserves all fields through a Firestore-shaped map', () {
      final job = buildJob(status: JobStatus.accepted).copyWith(
        assignedWorkerId: 'worker_9',
        acceptedAt: DateTime(2026, 1, 1, 9, 5),
      );

      final map = job.toMap();
      final rehydrated = Job.fromMap(map);

      expect(rehydrated.id, job.id);
      expect(rehydrated.customerId, job.customerId);
      expect(rehydrated.serviceType, ServiceType.cleaning);
      expect(rehydrated.status, JobStatus.accepted);
      expect(rehydrated.assignedWorkerId, 'worker_9');
      expect(rehydrated.acceptedAt, DateTime(2026, 1, 1, 9, 5));
      expect(rehydrated.houseNumber, '12/A');
      expect(rehydrated.landmark, 'Near Arpico Supercentre');
      expect(rehydrated.estimatedEarnings, 1500.0);
    });

    test('falls back to searching status for an unrecognized status value', () {
      final map = buildJob().toMap();
      map['status'] = 'some_future_status_this_app_version_does_not_know';

      final rehydrated = Job.fromMap(map);

      expect(rehydrated.status, JobStatus.searching);
    });

    test('nullable timestamps round-trip as null when absent', () {
      final map = buildJob().toMap();

      expect(map['acceptedAt'], isNull);
      expect(map['startedAt'], isNull);
      expect(map['completedAt'], isNull);

      final rehydrated = Job.fromMap(map);
      expect(rehydrated.acceptedAt, isNull);
      expect(rehydrated.startedAt, isNull);
      expect(rehydrated.completedAt, isNull);
    });

    test('encodes createdAt as a Firestore Timestamp', () {
      final map = buildJob().toMap();
      expect(map['createdAt'], isA<Timestamp>());
    });
  });

  group('copyWith', () {
    test('only overrides the fields that are passed', () {
      final job = buildJob();
      final updated = job.copyWith(status: JobStatus.assigned);

      expect(updated.status, JobStatus.assigned);
      expect(updated.id, job.id);
      expect(updated.customerId, job.customerId);
      expect(updated.houseNumber, job.houseNumber);
    });
  });

  group('validJobTransitions', () {
    test(
      'searching can move to assigned or cancelled, not directly to completed',
      () {
        final transitions = validJobTransitions[JobStatus.searching]!;
        expect(transitions, contains(JobStatus.assigned));
        expect(transitions, contains(JobStatus.cancelled));
        expect(transitions, isNot(contains(JobStatus.completed)));
      },
    );

    test(
      'terminal states (completed, cancelled) allow no further transitions',
      () {
        expect(validJobTransitions[JobStatus.completed], isEmpty);
        expect(validJobTransitions[JobStatus.cancelled], isEmpty);
      },
    );

    test('every JobStatus has an entry in the transition table', () {
      for (final status in JobStatus.values) {
        expect(
          validJobTransitions.containsKey(status),
          isTrue,
          reason: '$status is missing from validJobTransitions',
        );
      }
    });

    test('the happy-path lifecycle is fully connected end to end', () {
      const path = [
        JobStatus.searching,
        JobStatus.assigned,
        JobStatus.accepted,
        JobStatus.enRoute,
        JobStatus.arrived,
        JobStatus.inProgress,
        JobStatus.completed,
      ];
      for (var i = 0; i < path.length - 1; i++) {
        expect(
          validJobTransitions[path[i]],
          contains(path[i + 1]),
          reason: '${path[i]} should be able to move to ${path[i + 1]}',
        );
      }
    });
  });
}
