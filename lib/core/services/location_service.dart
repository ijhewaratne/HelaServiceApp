import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../utils/geohash_helper.dart';

class LocationService {
  final FirebaseFirestore _firestore;
  StreamSubscription<Position>? _positionStream;
  String? _workerId;
  bool _isTracking = false;
  Map<String, dynamic>? _workerMetadata;

  // Battery-optimized settings for Sri Lankan phones
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.medium,
    distanceFilter: 50, // Update every 50 meters
  );

  LocationService(this._firestore);

  /// [workerMetadata] is merged into every worker_locations write so the
  /// dispatch function can read skills/isVerified/homeLocation without an
  /// extra Firestore read.
  Future<void> startTracking(String workerId, {Map<String, dynamic>? workerMetadata}) async {
    if (_isTracking) return;

    _workerId = workerId;
    _workerMetadata = workerMetadata ?? await _loadWorkerMetadata(workerId);
    
    // Check permissions
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException('Location services disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException('Location permissions denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException('Location permissions permanently denied');
    }

    // Update initial position
    final position = await Geolocator.getCurrentPosition();
    await _updateWorkerStatus(workerId, true);
    await _updateLocation(position);

    // Start listening
    _positionStream = Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).listen(
      _updateLocation,
      onError: (e) => debugPrint('Location stream error: $e'),
    );
    
    _isTracking = true;
  }

  Future<void> _updateLocation(Position position) async {
    if (_workerId == null) return;

    // Generate geohash for efficient querying
    final geohash = GeohashHelper.encode(
      position.latitude,
      position.longitude,
    );
    
    await _firestore.collection('worker_locations').doc(_workerId).set({
      'lat': position.latitude,
      'lng': position.longitude,
      'location': GeoPoint(position.latitude, position.longitude),
      'geohash': geohash,
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'online',
      'accuracy': position.accuracy,
      if (_workerMetadata != null) ..._workerMetadata!,
    }, SetOptions(merge: true));
  }

  Future<void> stopTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
    _workerMetadata = null;

    if (_workerId != null) {
      await _updateWorkerStatus(_workerId!, false);
      await _firestore.collection('worker_locations').doc(_workerId).update({
        'status': 'offline',
        'offlineAt': FieldValue.serverTimestamp(),
      });
    }
  }
  
  bool get isTracking => _isTracking;
  
  Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
  
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(locationSettings: _locationSettings);
  }

  Future<Map<String, dynamic>> _loadWorkerMetadata(String workerId) async {
    final workerDoc = await _firestore.collection('workers').doc(workerId).get();
    final data = workerDoc.data();
    if (data == null) return const {};

    final services = (data['services'] as List<dynamic>?)
            ?.map((service) => service as String)
            .toList() ??
        const <String>[];
    final status = data['status'] as String? ?? 'pending';
    final metadata = <String, dynamic>{
      'skills': services,
      'isVerified': status == 'approved',
      'rating': (data['rating'] as num?)?.toDouble() ?? 4.0,
    };

    final homeLat = (data['homeLat'] as num?)?.toDouble();
    final homeLng = (data['homeLng'] as num?)?.toDouble();
    if (homeLat != null && homeLng != null) {
      metadata['homeLocation'] = {
        'latitude': homeLat,
        'longitude': homeLng,
      };
    }

    final lastJobCompletedAt = data['lastJobCompletedAt'];
    if (lastJobCompletedAt is Timestamp) {
      metadata['lastJobCompletedAt'] = lastJobCompletedAt;
    }

    return metadata;
  }

  Future<void> _updateWorkerStatus(String workerId, bool isOnline) async {
    await _firestore.collection('workers').doc(workerId).set({
      'isOnline': isOnline,
      'lastStatusChange': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

class LocationException implements Exception {
  final String message;
  LocationException(this.message);
  
  @override
  String toString() => 'LocationException: $message';
}
