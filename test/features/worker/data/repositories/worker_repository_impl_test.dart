import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/core/errors/failures.dart';
import 'package:home_service_app/features/worker/data/repositories/worker_repository_impl.dart';
import 'package:home_service_app/features/worker/domain/entities/worker.dart';
import 'package:mockito/mockito.dart';

class _MockFirebaseStorage extends Mock implements FirebaseStorage {}

void main() {
  late FakeFirebaseFirestore firestore;
  late WorkerRepositoryImpl repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = WorkerRepositoryImpl(firestore, _MockFirebaseStorage());
  });

  group('WorkerRepositoryImpl', () {
    test('createWorker stores worker document', () async {
      final worker = Worker(
        id: 'worker_123',
        nic: '123456789V',
        fullName: 'Test Worker',
        mobileNumber: '+94771234567',
        address: 'Colombo',
        emergencyContactName: 'Emergency',
        emergencyContactPhone: '+94771234568',
        services: const [ServiceType.cleaning],
        createdAt: DateTime(2026, 5, 31),
      );

      final result = await repository.createWorker(worker);

      expect(result.isRight(), isTrue);

      final stored = await firestore
          .collection('workers')
          .doc('worker_123')
          .get();
      expect(stored.exists, isTrue);
      expect(stored.data()?['nic'], '123456789V');
      expect(stored.data()?['services'], ['cleaning']);
    });

    test(
      'getWorker returns NotFoundFailure when document is missing',
      () async {
        final result = await repository.getWorker('missing-worker');

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<NotFoundFailure>()),
          (_) => fail('Expected failure'),
        );
      },
    );

    test('getWorker hydrates stored worker document', () async {
      await firestore.collection('workers').doc('worker_123').set({
        'id': 'worker_123',
        'nic': '123456789V',
        'fullName': 'Test Worker',
        'mobileNumber': '+94771234567',
        'address': 'Colombo',
        'emergencyContactName': 'Emergency',
        'emergencyContactPhone': '+94771234568',
        'services': ['cleaning'],
        'status': 'approved',
        'createdAt': Timestamp.fromDate(DateTime(2026, 5, 31)),
        'rating': 4.5,
        'totalJobs': 10,
        'hasAcceptedContract': true,
      });

      final result = await repository.getWorker('worker_123');

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected worker'), (worker) {
        expect(worker.id, 'worker_123');
        expect(worker.status, WorkerStatus.approved);
        expect(worker.services, const [ServiceType.cleaning]);
      });
    });

    test('checkNICExists detects existing worker NIC', () async {
      await firestore.collection('workers').doc('worker_123').set({
        'nic': '123456789V',
      });

      final existing = await repository.checkNICExists('123456789V');
      final missing = await repository.checkNICExists('987654321V');

      expect(existing.getOrElse(() => false), isTrue);
      expect(missing.getOrElse(() => true), isFalse);
    });

    test(
      'updateOnlineStatus syncs worker and worker_locations documents',
      () async {
        await firestore.collection('workers').doc('worker_123').set({
          'fullName': 'Test Worker',
        });

        final result = await repository.updateOnlineStatus(
          workerId: 'worker_123',
          isOnline: true,
          lat: 6.9271,
          lng: 79.8612,
        );

        expect(result.isRight(), isTrue);

        final workerDoc = await firestore
            .collection('workers')
            .doc('worker_123')
            .get();
        final locationDoc = await firestore
            .collection('worker_locations')
            .doc('worker_123')
            .get();

        expect(workerDoc.data()?['isOnline'], isTrue);
        expect(workerDoc.data()?['currentLat'], 6.9271);
        expect(workerDoc.data()?['currentLng'], 79.8612);
        expect(locationDoc.data()?['status'], 'online');
        expect(locationDoc.data()?['lat'], 6.9271);
        expect(locationDoc.data()?['lng'], 79.8612);
      },
    );
  });
}
