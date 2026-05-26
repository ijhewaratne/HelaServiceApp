import 'dart:developer' as developer;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../worker/domain/entities/worker_profile.dart';

class DispatchEngine {
  Future<WorkerProfile?> findNearestWorker({
    required LatLng customerLocation,
    required String serviceType,
    required double maxRadiusKm,
  }) async {
    // 1. Query Firestore for online workers with geohash
    // Simulated via a repository fetch in real app. For MVP logic breakdown:
    List<WorkerProfile> onlineWorkers = await _queryDatabaseForOnlineWorkers(customerLocation, maxRadiusKm);

    // 2. Filter by service skill
    var qualifiedWorkers = onlineWorkers.where((w) => w.serviceTypes.contains(serviceType)).toList();

    // 3. Sort by: distance + lastJobCompleted (idle workers first)
    // Sri Lanka optimization: Check worker's "home base" distance too
    // (Don't send a Dehiwala worker to Kotte if they live in Moratuwa)
    qualifiedWorkers.sort((a, b) {
      if (a.currentLat == null || a.currentLng == null || b.currentLat == null || b.currentLng == null) {
        return 0; // Guard against missing locations
      }

      double distA = _calculateMockDistance(customerLocation, a.currentLat!, a.currentLng!);
      double distB = _calculateMockDistance(customerLocation, b.currentLat!, b.currentLng!);
      
      double homeDistA = _calculateMockDistance(customerLocation, a.homeLat ?? a.currentLat!, a.homeLng ?? a.currentLng!);
      double homeDistB = _calculateMockDistance(customerLocation, b.homeLat ?? b.currentLat!, b.homeLng ?? b.currentLng!);

      // Weight function: 40% weight to current distance, 40% to home base distance (to prevent long end-of-day commute)
      // and 20% weight to idle-ness (completed jobs - lower is better for spreading work)
      double scoreA = (distA * 0.4) + (homeDistA * 0.4) + (a.completedJobs * 0.2);
      double scoreB = (distB * 0.4) + (homeDistB * 0.4) + (b.completedJobs * 0.2);

      return scoreA.compareTo(scoreB);
    });

    // 4. Send FCM to top 3 simultaneously (race condition - first accept wins)
    var top3 = qualifiedWorkers.take(3).toList();
    if (top3.isEmpty) return null;

    for (var worker in top3) {
      // Abstracted FCM Broadcast via NotificationService
      developer.log("Broadcasting job to Worker: ${worker.uid}");
    }

    // 5. Auto-cancel others after 30 seconds
    return await _waitForWorkerAcceptance(top3);
  }

  Future<WorkerProfile?> _waitForWorkerAcceptance(List<WorkerProfile> broadcastedWorkers) async {
    // In production, this would listen to a Firestore Document stream for the booking 'status'
    // changing to 'accepted' and reading the updated 'workerId'.
    await Future.delayed(const Duration(seconds: 2)); // Mock 30s delay
    // Assuming the first worker hit accept first for mock
    return broadcastedWorkers.first;
  }

  // Simplified helper for straight-line mock distance (use Geolocator in production)
  double _calculateMockDistance(LatLng a, double latB, double lngB) {
    return ((a.latitude - latB).abs() + (a.longitude - lngB).abs());
  }

  Future<List<WorkerProfile>> _queryDatabaseForOnlineWorkers(LatLng center, double radiusKm) async {
    // Abstracted: Fetch from Firestore using GeoFlutterFire2
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      WorkerProfile(
        uid: 'wrk_001',
        nic: '951234567V',
        name: 'Saman Silva',
        phone: '+94711111111',
        district: 'Colombo',
        serviceTypes: ['cleaning', 'babysitting'],
        languages: ['English', 'Sinhala'],
        verificationStatus: 'approved',
        rating: 4.8,
        completedJobs: 12,
        isAvailable: true,
        availabilityMode: 'full_time',
        currentLat: 6.9110, // Close
        currentLng: 79.8640,
        homeLat: 6.9110, // Home is close
        homeLng: 79.8640,
      ),
      WorkerProfile(
        uid: 'wrk_002',
        nic: '901234567V',
        name: 'Kamal Perera',
        phone: '+94770000000',
        district: 'Colombo',
        serviceTypes: ['cleaning'],
        languages: ['Sinhala'],
        verificationStatus: 'approved',
        rating: 4.5,
        completedJobs: 2, // Less idle
        isAvailable: true,
        availabilityMode: 'part_time',
        currentLat: 6.9000, // Very Close
        currentLng: 79.8500,
        homeLat: 6.7800, // Home is very far (Moratuwa)
        homeLng: 79.8800,
      )
    ];
  }
}
