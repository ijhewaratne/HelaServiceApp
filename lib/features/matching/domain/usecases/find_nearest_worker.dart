import 'package:geolocator/geolocator.dart';
import 'package:home_service_app/features/worker/domain/entities/worker.dart';
import 'package:home_service_app/features/matching/data/worker_repository_interface.dart';

/// The core PickMe-style matching algorithm adapted for Sri Lankan home services.
/// Scores available workers using distance, idle time, and home-base proximity.
class FindNearestWorker {
  final WorkerRepositoryInterface repository;

  FindNearestWorker(this.repository);

  /// Returns the best available [Worker] for a job, or null if none qualify.
  Future<List<Worker>> execute({
    required double customerLat,
    required double customerLng,
    required ServiceType serviceType,
    required String zoneId,
    double maxRadiusKm = 5.0,
    int topN = 3, // PickMe-style: broadcast to top 3 simultaneously
  }) async {
    // 1. Fetch all online workers with matching skill within the zone
    final List<Worker> candidates = await repository.getOnlineWorkersBySkillAndZone(
      serviceType: serviceType,
      zoneId: zoneId,
    );

    if (candidates.isEmpty) return [];

    // 2. Filter by max radius (workers outside maxRadiusKm are ignored)
    final List<Worker> inRadius = candidates.where((w) {
      if (w.currentLat == null || w.currentLng == null) return false;
      final distM = Geolocator.distanceBetween(
        customerLat, customerLng,
        w.currentLat!, w.currentLng!,
      );
      return distM <= maxRadiusKm * 1000;
    }).toList();

    if (inRadius.isEmpty) return [];

    // 3. Score each candidate. Higher score = preferred dispatch target.
    final scored = inRadius.map((worker) => _ScoredWorker(
      worker,
      _score(worker, customerLat, customerLng),
    )).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));

    // 4. Return the top N workers for simultaneous broadcast
    return scored.take(topN).map((s) => s.worker).toList();
  }

  double _score(Worker worker, double customerLat, double customerLng) {
    // --- Component 1: Distance to customer (0.50 weight) ---
    // Closer workers score higher. +0.1 prevents division-by-zero.
    final double distToCustomerKm = Geolocator.distanceBetween(
      customerLat, customerLng,
      worker.currentLat!, worker.currentLng!,
    ) / 1000.0;
    final double distScore = 1.0 / (distToCustomerKm + 0.1);

    // --- Component 2: Idle time since last job (0.30 weight) ---
    // Workers who have been waiting longest get priority (fair rotation).
    final double idleHours = worker.lastJobCompletedAt != null
        ? DateTime.now().difference(worker.lastJobCompletedAt!).inMinutes / 60.0
        : 16.0; // Max idle: award high idle score if never worked today
    final double idleScore = idleHours.clamp(0.0, 8.0); // Cap at 8 hours

    // --- Component 3: Home-base proximity (0.20 weight) ---
    // Sri Lanka-specific: avoid sending workers far from home base to reduce
    // post-job stranding (e.g., Moratuwa worker sent to Kotte).
    final double distFromHomeKm = Geolocator.distanceBetween(
      worker.homeLocation.latitude, worker.homeLocation.longitude,
      customerLat, customerLng,
    ) / 1000.0;
    final double homeScore = 1.0 / (distFromHomeKm + 0.1);

    return (distScore * 0.50) + (idleScore * 0.30) + (homeScore * 0.20);
  }
}

class _ScoredWorker {
  final Worker worker;
  final double score;
  _ScoredWorker(this.worker, this.score);
}
