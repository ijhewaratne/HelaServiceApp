import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  final FirebaseFirestore _firestore;
  StreamSubscription<Position>? _positionStream;
  String? _workerId;
  
  // Battery optimization for Sri Lankan phones
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.medium, // Not high - saves battery
    distanceFilter: 50, // Update every 50 meters, not constantly
    timeLimit: Duration(minutes: 1),
  );

  LocationService(this._firestore);

  /// Start tracking when worker goes online
  Future<void> startTracking(String workerId) async {
    _workerId = workerId;
    
    // Check permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
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
    await _updateLocation(await Geolocator.getCurrentPosition());

    // Listen to position changes (battery optimized)
    _positionStream = Geolocator.getPositionStream(locationSettings: _locationSettings)
        .listen(_updateLocation, onError: (e) {
      debugPrint('Location stream error: $e');
    });
  }

  Future<void> _updateLocation(Position position) async {
    if (_workerId == null) return;

    // Calculate geohash for efficient querying (using geofire_common logic)
    final geohash = _encodeGeohash(position.latitude, position.longitude, precision: 9);
    
    await _firestore.collection('worker_locations').doc(_workerId).set({
      'lat': position.latitude,
      'lng': position.longitude,
      'geohash': geohash,
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'online',
    }, SetOptions(merge: true));
  }

  /// Stop tracking when worker goes offline
  Future<void> stopTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
    
    if (_workerId != null) {
      await _firestore.collection('worker_locations').doc(_workerId).update({
        'status': 'offline',
        'offlineAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Simple geohash encoder (for Firestore queries)
  String _encodeGeohash(double lat, double lng, {int precision = 9}) {
    const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
    // Simplified implementation - use proper geohash package in production
    return 'tdr1vwt3n'; // Placeholder - add geohash: ^0.1.2 to pubspec
  }
}

class LocationException implements Exception {
  final String message;
  LocationException(this.message);
}