import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../worker/domain/entities/worker.dart';
import '../../../worker/domain/repositories/worker_repository.dart';

/// Parameters for finding nearest workers
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

/// Use case for finding the nearest available workers
/// Uses a PickMe-style scoring algorithm
class FindNearestWorker implements UseCase<List<Worker>, FindNearestWorkerParams> {
  final WorkerRepository _workerRepository;

  FindNearestWorker(this._workerRepository);

  /// Primary method for use case pattern
  @override
  Future<Either<Failure, List<Worker>>> call(FindNearestWorkerParams params) async {
    try {
      final workers = await execute(
        customerLat: params.customerLat,
        customerLng: params.customerLng,
        serviceType: params.serviceType,
        zoneId: params.zoneId,
        maxRadiusKm: params.maxRadiusKm,
        topN: params.topN,
      );
      return Right(workers);
    } catch (e) {
      return Left(Failure('Failed to find workers: $e'));
    }
  }

  /// Returns the best available workers for a job, or empty list if none qualify.
  /// 
  /// Parameters:
  /// - [customerLat] / [customerLng]: Customer location coordinates
  /// - [serviceType]: Type of service required
  /// - [zoneId]: Service zone identifier
  /// - [maxRadiusKm]: Maximum search radius in kilometers (default: 5.0)
  /// - [topN]: Number of top workers to return (default: 3)
  Future<List<Worker>> execute({
    required double customerLat,
    required double customerLng,
    required dynamic serviceType,
    required String zoneId,
    double maxRadiusKm = 5.0,
    int topN = 3,
  }) async {
    // 1. Fetch all online workers with matching skill within the zone
    // Note: This is a simplified implementation. The actual implementation
    // would use a geospatial query or a specialized worker repository method.
    
    // For now, return empty list - this needs to be integrated with
    // the actual worker repository and location-based queries
    return [];
  }

  /// Calculate distance between two points in kilometers
  double _calculateDistanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000.0;
  }
}

/// Scored worker for internal ranking
class _ScoredWorker {
  final Worker worker;
  final double score;

  _ScoredWorker(this.worker, this.score);
}
