import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/utils/geohash_helper.dart';

/// Service for tracking worker location in real-time
/// 
/// Phase 3: Essential Features - Real-Time Worker Tracking
/// 
/// This service handles:
/// - Starting/stopping location tracking
/// - Updating worker location in Firestore
/// - Listening to worker location updates (customer-side)
class LocationTrackingService {
  final FirebaseFirestore _firestore;
  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;

  LocationTrackingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Check if currently tracking
  bool get isTracking => _isTracking;

  /// Start tracking worker location
  /// 
  /// Should be called when worker goes online
  Future<void> startTracking(String workerId) async {
    if (_isTracking) return;

    // Check location permission
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied) {
        throw LocationPermissionDeniedException();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionPermanentlyDeniedException();
    }

    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException();
    }

    _isTracking = true;

    // Update worker status to online
    await _updateWorkerStatus(workerId, true);

    // Start listening to location updates
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen(
      (position) => _updateWorkerLocation(workerId, position),
      onError: (error) {
        print('Location tracking error: $error');
        _isTracking = false;
      },
    );
  }

  /// Stop tracking worker location
  /// 
  /// Should be called when worker goes offline
  Future<void> stopTracking(String workerId) async {
    _isTracking = false;
    await _positionStream?.cancel();
    _positionStream = null;

    // Update worker status to offline
    await _updateWorkerStatus(workerId, false);

    // Remove location from Firestore
    await _firestore.collection('worker_locations').doc(workerId).delete();
  }

  /// Update worker location in Firestore
  Future<void> _updateWorkerLocation(String workerId, Position position) async {
    try {
      // Generate geohash for efficient geoqueries
      final geohash = GeohashHelper.encode(
        position.latitude,
        position.longitude,
        precision: 7,
      );

      await _firestore.collection('worker_locations').doc(workerId).set({
        'workerId': workerId,
        'location': GeoPoint(position.latitude, position.longitude),
        'geohash': geohash,
        'accuracy': position.accuracy,
        'heading': position.heading,
        'speed': position.speed,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating worker location: $e');
    }
  }

  /// Update worker online status
  Future<void> _updateWorkerStatus(String workerId, bool isOnline) async {
    try {
      await _firestore.collection('workers').doc(workerId).update({
        'isOnline': isOnline,
        'lastStatusUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating worker status: $e');
    }
  }

  /// Get single location update
  Future<Position?> getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Listen to a worker's location updates (customer-side)
  /// 
  /// Returns a stream of location updates for the specified worker
  Stream<WorkerLocation> watchWorkerLocation(String workerId) {
    return _firestore
        .collection('worker_locations')
        .doc(workerId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return WorkerLocation.empty;
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final geoPoint = data['location'] as GeoPoint?;
      final timestamp = data['timestamp'] as Timestamp?;

      return WorkerLocation(
        workerId: workerId,
        latitude: geoPoint?.latitude ?? 0.0,
        longitude: geoPoint?.longitude ?? 0.0,
        accuracy: data['accuracy']?.toDouble() ?? 0.0,
        heading: data['heading']?.toDouble() ?? 0.0,
        speed: data['speed']?.toDouble() ?? 0.0,
        timestamp: timestamp?.toDate(),
      );
    });
  }

  /// Get nearby online workers
  /// 
  /// Uses geohash for efficient querying
  Future<List<WorkerLocation>> getNearbyWorkers({
    required double latitude,
    required double longitude,
    required double radiusInKm,
    String? serviceType,
  }) async {
    try {
      // Get neighboring geohashes
      final centerGeohash = GeohashHelper.encode(latitude, longitude, precision: 5);
      final neighbors = GeohashHelper.getNeighbors(centerGeohash);

      // Query workers in all neighboring cells
      final allWorkers = <WorkerLocation>[];
      
      for (final geohashPrefix in [...neighbors, centerGeohash]) {
        final query = await _firestore
            .collection('worker_locations')
            .orderBy('geohash')
            .startAt([geohashPrefix])
            .endAt(['$geohashPrefix\uf8ff'])
            .get();

        for (final doc in query.docs) {
          final data = doc.data();
          final geoPoint = data['location'] as GeoPoint?;
          
          if (geoPoint != null) {
            final worker = WorkerLocation(
              workerId: doc.id,
              latitude: geoPoint.latitude,
              longitude: geoPoint.longitude,
              accuracy: data['accuracy']?.toDouble() ?? 0.0,
              timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
            );

            // Calculate actual distance
            final distance = _calculateDistance(
              latitude,
              longitude,
              worker.latitude,
              worker.longitude,
            );

            // Only include workers within radius
            if (distance <= radiusInKm) {
              allWorkers.add(worker.copyWith(distance: distance));
            }
          }
        }
      }

      // Sort by distance
      allWorkers.sort((a, b) => a.distance.compareTo(b.distance));
      return allWorkers;
    } catch (e) {
      print('Error getting nearby workers: $e');
      return [];
    }
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = 
        (dLat / 2).sin() * (dLat / 2).sin() +
        _toRadians(lat1).cos() * 
        _toRadians(lat2).cos() * 
        (dLon / 2).sin() * (dLon / 2).sin();
    
    final c = 2 * (a.sqrt()).atan2((1 - a).sqrt(), a.sqrt());
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * 3.14159265359 / 180;

  /// Dispose resources
  Future<void> dispose() async {
    await _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
  }
}

/// Worker location data model
class WorkerLocation {
  final String workerId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double heading;
  final double speed;
  final DateTime? timestamp;
  final double distance; // Distance from customer (for nearby queries)

  const WorkerLocation({
    required this.workerId,
    required this.latitude,
    required this.longitude,
    this.accuracy = 0.0,
    this.heading = 0.0,
    this.speed = 0.0,
    this.timestamp,
    this.distance = 0.0,
  });

  static const empty = WorkerLocation(
    workerId: '',
    latitude: 0.0,
    longitude: 0.0,
  );

  bool get isEmpty => workerId.isEmpty;

  WorkerLocation copyWith({
    String? workerId,
    double? latitude,
    double? longitude,
    double? accuracy,
    double? heading,
    double? speed,
    DateTime? timestamp,
    double? distance,
  }) {
    return WorkerLocation(
      workerId: workerId ?? this.workerId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      timestamp: timestamp ?? this.timestamp,
      distance: distance ?? this.distance,
    );
  }
}

/// Custom exceptions
class LocationPermissionDeniedException implements Exception {
  @override
  String toString() => 'Location permission denied';
}

class LocationPermissionPermanentlyDeniedException implements Exception {
  @override
  String toString() => 'Location permission permanently denied';
}

class LocationServiceDisabledException implements Exception {
  @override
  String toString() => 'Location services are disabled';
}

/// Extension for double math operations
extension _DoubleMath on double {
  double sin() {
    return this.sin();
  }
  
  double cos() {
    return this.cos();
  }
  
  double sqrt() {
    return this.sqrt();
  }
  
  double atan2(double y, double x) {
    return this.atan2(y, x);
  }
}
