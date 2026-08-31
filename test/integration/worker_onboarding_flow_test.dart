import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/features/worker/data/repositories/worker_repository_impl.dart';
import 'package:home_service_app/features/worker/domain/entities/worker_application.dart';
import 'package:mockito/mockito.dart';

class _MockFirebaseStorage extends Mock implements FirebaseStorage {}

void main() {
  late FakeFirebaseFirestore firestore;
  late WorkerRepositoryImpl repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = WorkerRepositoryImpl(firestore, _MockFirebaseStorage());
  });

  group('Worker onboarding repository integration', () {
    test(
      'submitApplication persists application and returns generated id',
      () async {
        final application = WorkerApplication(
          nic: '853202937V',
          fullName: 'Test Worker',
          mobileNumber: '0771234567',
          address: 'Colombo 05',
          emergencyContactName: 'Emergency Contact',
          emergencyContactPhone: '0779876543',
          selectedServices: const [ServiceType.cleaning],
          appliedAt: DateTime(2026, 5, 31),
        );

        final result = await repository.submitApplication(application);

        expect(result.isRight(), isTrue);

        final created = result.getOrElse(
          () => throw StateError('Expected Right'),
        );
        expect(created.id, isNotNull);

        final doc = await firestore
            .collection('worker_applications')
            .doc(created.id)
            .get();
        expect(doc.exists, isTrue);
        expect(doc.data()?['nic'], '853202937V');
        expect(doc.data()?['fullName'], 'Test Worker');
        expect(doc.data()?['selectedServices'], ['cleaning']);
      },
    );

    test('checkNICExists reflects persisted workers', () async {
      await firestore.collection('workers').doc('worker-1').set({
        'nic': '853202937V',
        'fullName': 'Existing Worker',
        'mobileNumber': '0771234567',
        'address': 'Colombo 03',
        'emergencyContactName': 'Emergency Contact',
        'emergencyContactPhone': '0779876543',
        'services': ['cleaning'],
        'status': 'pendingApproval',
        'createdAt': DateTime(2026, 5, 31).toIso8601String(),
        'rating': 0.0,
        'totalJobs': 0,
        'hasAcceptedContract': false,
      });

      final existing = await repository.checkNICExists('853202937V');
      final missing = await repository.checkNICExists('199832029372');

      expect(existing.getOrElse(() => false), isTrue);
      expect(missing.getOrElse(() => true), isFalse);
    });

    test(
      'updateLocation writes to workers and worker_locations collections',
      () async {
        await firestore.collection('workers').doc('worker-1').set({
          'fullName': 'Location Worker',
          'isOnline': true,
        });

        final result = await repository.updateLocation(
          workerId: 'worker-1',
          lat: 6.9271,
          lng: 79.8612,
        );

        expect(result.isRight(), isTrue);

        final workerDoc = await firestore
            .collection('workers')
            .doc('worker-1')
            .get();
        final locationDoc = await firestore
            .collection('worker_locations')
            .doc('worker-1')
            .get();

        expect(workerDoc.data()?['currentLat'], 6.9271);
        expect(workerDoc.data()?['currentLng'], 79.8612);
        expect(locationDoc.data()?['lat'], 6.9271);
        expect(locationDoc.data()?['lng'], 79.8612);
      },
    );
  });
}
