import 'dart:math' as math;
import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/geohash_helper.dart';
import '../../../worker/domain/entities/worker.dart';
import '../../../worker/domain/repositories/worker_repository.dart';

/// Parameters for finding nearest available workers.
///
/// Use this for Layer 2 real-time dispatch (mobility/accompaniment).
/// For Layer 1 scheduled household services use FindAvailableWorkers
/// from the scheduling feature instead.
class FindNearestWorkerParams {
  final double customerLat;
  final double customerLng;
  final dynamic serviceType;
  final String zoneId;
  final double maxRadiusKm;
  final int topN;

  FindNearestWorkerParams({
    required this.customerLat,
    required this.customerLng,
    required this.serviceType,
    required this.zoneId,
    this.maxRadiusKm = 5.0,
    this.topN = 3,
  });
}

/// Real-time proximity-based dispatch — PickMe-style scoring.
///
/// Scoring weights (for Layer 2 mobility use case):
///   40% current distance to customer
///   40% home-base distance (avoid sending worker too far from home)
///   20% idle time (recently completed = higher priority)
class FindNearestWorker implements UseCase<List<Worker>, FindNearestWorkerParams> {
  final WorkerRepository _workerRepository;
  final FirebaseFirestore _db;

  FindNearestWorker(this._workerRepository,
      {FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Either<Failure, List<Worker>>> call(
      FindNearestWorkerParams params) async {
    try {
      // Build geohash neighbours for the customer location
      final centerHash = GeohashHelper.encode(
          params.customerLat, params.customerLng,
          precision: 5);
      final neighbours = GeohashHelper.getNeighbors(centerHash);

      final candidates = <_ScoredWorker>[];

      for (final prefix in [...neighbours, centerHash]) {
        final snap = await _db
            .collection('worker_locations')
            .orderBy('geohash')
            .startAt([prefix])
            .endAt(['$prefix'])
            .get();

        for (final doc in snap.docs) {
          final data = doc.data();
          final gp = data['location'] as GeoPoint?;
          if (gp == null) continue;

          final dist = _haversineKm(
              params.customerLat, params.customerLng,
              gp.latitude, gp.longitude);
          if (dist > params.maxRadiusKm) continue;

          // Load full Worker entity for skill / status checks
          final workerResult = await _workerRepository.getWorker(doc.id);
          final worker = workerResult.fold((_) => null, (w) => w);
          if (worker == null) continue;
          if (worker.status != WorkerStatus.approved) continue;

          final serviceMatch = worker.services.any((s) =>
              s.name.toLowerCase() ==
              params.serviceType.toString().toLowerCase());
          if (!serviceMatch) continue;

          candidates.add(_ScoredWorker(
            worker: worker,
            currentDistKm: dist,
            homeLat: worker.homeLat,
            homeLng: worker.homeLng,
            lastJobCompletedAt: worker.lastJobCompletedAt,
          ));
        }
      }

      // Score and rank
      final scored = candidates.map((c) {
        final distScore = 1.0 / (c.currentDistKm + 0.1);
        final homeDistKm = (c.homeLat != null && c.homeLng != null)
            ? _haversineKm(params.customerLat, params.customerLng,
                c.homeLat!, c.homeLng!)
            : 10.0;
        final homeScore = 1.0 / (homeDistKm + 0.1);
        final idleMins = c.lastJobCompletedAt != null
            ? DateTime.now()
                .difference(c.lastJobCompletedAt!)
                .inMinutes
                .toDouble()
            : 120.0;
        final idleScore = math.min(idleMins / 60.0, 2.0);
        return _ScoredWorker(
          worker: c.worker,
          currentDistKm: c.currentDistKm,
          homeLat: c.homeLat,
          homeLng: c.homeLng,
          lastJobCompletedAt: c.lastJobCompletedAt,
          score: distScore * 0.4 + homeScore * 0.4 + idleScore * 0.2,
        );
      }).toList()
        ..sort((a, b) => b.score.compareTo(a.score));

      return Right(scored.take(params.topN).map((s) => s.worker).toList());
    } catch (e) {
      return Left(GenericFailure('Failed to find workers: $e'));
    }
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}

class _ScoredWorker {
  final Worker worker;
  final double currentDistKm;
  final double? homeLat;
  final double? homeLng;
  final DateTime? lastJobCompletedAt;
  final double score;

  _ScoredWorker({
    required this.worker,
    required this.currentDistKm,
    this.homeLat,
    this.homeLng,
    this.lastJobCompletedAt,
    this.score = 0.0,
  });
}
