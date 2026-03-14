import 'package:home_service_app/features/worker/domain/entities/worker.dart';

/// Abstract repository interface for worker data operations.
/// Swap the mock implementation below for a real FirebaseFirestore implementation
/// once `flutterfire configure` has been run.
abstract class WorkerRepositoryInterface {
  Future<List<Worker>> getOnlineWorkersBySkillAndZone({
    required ServiceType serviceType,
    required String zoneId,
  });

  Future<void> updateOnlineStatus(String workerId, bool isOnline);
  Future<void> updateWorkerLocation(String workerId, double lat, double lng);
  Future<Worker?> getWorkerById(String workerId);
}

/// -- MOCK IMPLEMENTATION (replace with Firestore implementation) --
class MockWorkerRepository implements WorkerRepositoryInterface {
  @override
  Future<List<Worker>> getOnlineWorkersBySkillAndZone({
    required ServiceType serviceType,
    required String zoneId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Returns empty list in mock. Wire up Firestore query:
    // return await _firestore
    //   .collection('workers')
    //   .where('isOnline', isEqualTo: true)
    //   .where('allowedZones', arrayContains: zoneId)
    //   .where('skills', arrayContains: serviceType.name)
    //   .get()
    //   .then((snap) => snap.docs.map((d) => Worker.fromMap(d.data())).toList());
    return [];
  }

  @override
  Future<void> updateOnlineStatus(String workerId, bool isOnline) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // await _firestore.collection('workers').doc(workerId).update({'isOnline': isOnline});
  }

  @override
  Future<void> updateWorkerLocation(String workerId, double lat, double lng) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // await _firestore.collection('workers').doc(workerId).update({
    //   'currentLat': lat, 'currentLng': lng,
    // });
  }

  @override
  Future<Worker?> getWorkerById(String workerId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return null;
  }
}
