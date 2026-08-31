import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:home_service_app/core/utils/geohash_helper.dart';
import 'package:home_service_app/features/matching/domain/usecases/find_nearest_worker.dart';
import 'package:home_service_app/features/worker/data/repositories/worker_repository_impl.dart';
import 'package:home_service_app/features/worker/domain/entities/worker.dart';

class _MockFirebaseStorage extends Mock implements FirebaseStorage {}

void main() {
  late FakeFirebaseFirestore firestore;
  late WorkerRepositoryImpl workerRepository;
  late FindNearestWorker findNearestWorker;

  // Customer requesting service in central Colombo.
  const customerLat = 6.9271;
  const customerLng = 79.8612;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    workerRepository = WorkerRepositoryImpl(firestore, _MockFirebaseStorage());
    findNearestWorker = FindNearestWorker(
      workerRepository,
      firestore: firestore,
    );
  });

  Future<void> seedWorker({
    required String id,
    required WorkerStatus status,
    required List<ServiceType> services,
    required double lat,
    required double lng,
    double? homeLat,
    double? homeLng,
  }) async {
    final worker = Worker(
      id: id,
      nic: '${id}NIC',
      fullName: 'Worker $id',
      mobileNumber: '+94770000000',
      address: 'Colombo',
      emergencyContactName: 'Contact',
      emergencyContactPhone: '+94770000001',
      services: services,
      status: status,
      createdAt: DateTime(2026, 1, 1),
      homeLat: homeLat,
      homeLng: homeLng,
    );
    final created = await workerRepository.createWorker(worker);
    expect(created.isRight(), isTrue, reason: 'failed to seed worker $id');

    final geohash = GeohashHelper.encode(lat, lng, precision: 5);
    await firestore.collection('worker_locations').doc(id).set({
      'geohash': geohash,
      'lat': lat,
      'lng': lng,
    });
  }

  test(
    'returns an approved, in-range worker offering the requested service',
    () async {
      await seedWorker(
        id: 'w1',
        status: WorkerStatus.approved,
        services: const [ServiceType.cleaning],
        lat: customerLat + 0.001,
        lng: customerLng + 0.001,
      );

      final result = await findNearestWorker(
        FindNearestWorkerParams(
          customerLat: customerLat,
          customerLng: customerLng,
          serviceType: ServiceType.cleaning,
          zoneId: 'colombo',
        ),
      );

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected a list of workers'), (workers) {
        expect(workers.length, 1);
        expect(workers.first.id, 'w1');
      });
    },
  );

  test('matches a worker for plumbing (regression: ServiceType used to be a '
      "separate 5-value enum on Worker that didn't include plumbing/"
      'electrical/acRepair/gardening/other at all)', () async {
    await seedWorker(
      id: 'w_plumber',
      status: WorkerStatus.approved,
      services: const [ServiceType.plumbing],
      lat: customerLat + 0.001,
      lng: customerLng + 0.001,
    );

    final result = await findNearestWorker(
      FindNearestWorkerParams(
        customerLat: customerLat,
        customerLng: customerLng,
        serviceType: ServiceType.plumbing,
        zoneId: 'colombo',
      ),
    );

    expect(result.isRight(), isTrue);
    result.fold((_) => fail('Expected a list of workers'), (workers) {
      expect(workers.length, 1);
      expect(workers.first.id, 'w_plumber');
    });
  });

  test('excludes workers who are not approved', () async {
    await seedWorker(
      id: 'w_pending',
      status: WorkerStatus.pending,
      services: const [ServiceType.cleaning],
      lat: customerLat,
      lng: customerLng,
    );

    final result = await findNearestWorker(
      FindNearestWorkerParams(
        customerLat: customerLat,
        customerLng: customerLng,
        serviceType: ServiceType.cleaning,
        zoneId: 'colombo',
      ),
    );

    result.fold(
      (_) => fail('Expected a list of workers'),
      (workers) => expect(workers, isEmpty),
    );
  });

  test('excludes workers who do not offer the requested service', () async {
    await seedWorker(
      id: 'w_wrong_service',
      status: WorkerStatus.approved,
      services: const [ServiceType.babysitting],
      lat: customerLat,
      lng: customerLng,
    );

    final result = await findNearestWorker(
      FindNearestWorkerParams(
        customerLat: customerLat,
        customerLng: customerLng,
        serviceType: ServiceType.cleaning,
        zoneId: 'colombo',
      ),
    );

    result.fold(
      (_) => fail('Expected a list of workers'),
      (workers) => expect(workers, isEmpty),
    );
  });

  test('excludes workers outside maxRadiusKm', () async {
    // ~1.1 degrees of latitude is roughly 120km away — well outside a 5km radius.
    await seedWorker(
      id: 'w_far',
      status: WorkerStatus.approved,
      services: const [ServiceType.cleaning],
      lat: customerLat + 1.1,
      lng: customerLng,
    );

    final result = await findNearestWorker(
      FindNearestWorkerParams(
        customerLat: customerLat,
        customerLng: customerLng,
        serviceType: ServiceType.cleaning,
        zoneId: 'colombo',
        maxRadiusKm: 5.0,
      ),
    );

    result.fold(
      (_) => fail('Expected a list of workers'),
      (workers) => expect(workers, isEmpty),
    );
  });

  test(
    'ranks a closer worker above a farther one for the same service',
    () async {
      await seedWorker(
        id: 'w_close',
        status: WorkerStatus.approved,
        services: const [ServiceType.cleaning],
        lat: customerLat + 0.001,
        lng: customerLng + 0.001,
        homeLat: customerLat,
        homeLng: customerLng,
      );
      await seedWorker(
        id: 'w_further',
        status: WorkerStatus.approved,
        services: const [ServiceType.cleaning],
        lat: customerLat + 0.03,
        lng: customerLng + 0.03,
        homeLat: customerLat,
        homeLng: customerLng,
      );

      final result = await findNearestWorker(
        FindNearestWorkerParams(
          customerLat: customerLat,
          customerLng: customerLng,
          serviceType: ServiceType.cleaning,
          zoneId: 'colombo',
          topN: 2,
        ),
      );

      result.fold((_) => fail('Expected a list of workers'), (workers) {
        expect(workers.length, 2);
        expect(workers.first.id, 'w_close');
      });
    },
  );
}
