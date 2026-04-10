import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  final FirebaseFirestore _firestore;
  StreamSubscription<Position>? _positionStream;
  String? _workerId;
  bool _isTracking = false;
  
  // Battery-optimized settings for Sri Lankan phones
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.medium,
    distanceFilter: 50, // Update every 50 meters
  );

  LocationService(this._firestore);

  Future<void> startTracking(String workerId) async {
    if (_isTracking) return;
    
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
    final position = await Geolocator.getCurrentPosition();
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
    final geohash = _encodeGeohash(
      latitude: position.latitude,
      longitude: position.longitude,
      precision: 9,
    );
    
    await _firestore.collection('worker_locations').doc(_workerId).set({
      'lat': position.latitude,
      'lng': position.longitude,
      'geohash': geohash,
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'online',
      'accuracy': position.accuracy,
    }, SetOptions(merge: true));
  }

  Future<void> stopTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
    
    if (_workerId != null) {
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

  /// Geohash encoder for efficient spatial queries
  String _encodeGeohash({
    required double latitude,
    required double longitude,
    int precision = 9,
  }) {
    const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
    
    double latMin = -90.0, latMax = 90.0;
    double lonMin = -180.0, lonMax = 180.0;
    
    final buffer = StringBuffer();
    int bits = 0;
    int ch = 0;
    bool evenBit = true;
    
    while (buffer.length < precision) {
      if (evenBit) {
        // Longitude
        final lonMid = (lonMin + lonMax) / 2;
        if (longitude > lonMid) {
          ch = (ch << 1) | 1;
          lonMin = lonMid;
        } else {
          ch = ch << 1;
          lonMax = lonMid;
        }
      } else {
        // Latitude
        final latMid = (latMin + latMax) / 2;
        if (latitude > latMid) {
          ch = (ch << 1) | 1;
          latMin = latMid;
        } else {
          ch = ch << 1;
          latMax = latMid;
        }
      }
      
      evenBit = !evenBit;
      bits++;
      
      if (bits == 5) {
        buffer.write(base32[ch]);
        bits = 0;
        ch = 0;
      }
    }
    
    return buffer.toString();
  }
}

class LocationException implements Exception {
  final String message;
  LocationException(this.message);
  
  @override
  String toString() => 'LocationException: $message';
}
