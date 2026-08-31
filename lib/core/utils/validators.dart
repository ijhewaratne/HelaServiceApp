import 'package:geolocator/geolocator.dart';
import '../constants/app_constants.dart';

/// Sri Lanka-specific input validation utilities.
/// Used throughout onboarding and booking flows for legal compliance.
class SLValidators {
  // ---------------------------------------------------------------------------
  // NIC Validation
  // ---------------------------------------------------------------------------

  /// Validates both old (9 digits + V/X) and new (12 digit) Sri Lankan NIC formats.
  static bool isValidNIC(String nic) {
    final oldFormat = RegExp(r'^[0-9]{9}[VXvx]$');
    final newFormat = RegExp(r'^[0-9]{12}$');
    return oldFormat.hasMatch(nic) || newFormat.hasMatch(nic);
  }

  /// Extracts Date of Birth from old-format NIC (first 7 digits encode DOB).
  static DateTime? extractDobFromNIC(String nic) {
    try {
      final int year = int.parse(nic.substring(0, 2));
      int dayOfYear = int.parse(nic.substring(2, 5));
      final bool isFemale = dayOfYear > 500;
      if (isFemale) dayOfYear -= 500;

      final int fullYear = year < 30 ? 2000 + year : 1900 + year;
      final DateTime baseDate = DateTime(fullYear, 1, 0);
      return baseDate.add(Duration(days: dayOfYear));
    } catch (_) {
      return null;
    }
  }

  /// Returns true if worker is at least 18 years old based on NIC.
  static bool isAgeVerified(String nic) {
    final dob = extractDobFromNIC(nic);
    if (dob == null) return false;
    final age = DateTime.now().difference(dob).inDays ~/ 365;
    return age >= 18;
  }

  // ---------------------------------------------------------------------------
  // Geofence Validation
  // ---------------------------------------------------------------------------

  /// Returns true if the given [lat]/[lng] falls within any active service zone.
  /// Uses the Haversine formula via geolocator's `distanceBetween`.
  static bool isWithinServiceZone(double lat, double lng) {
    for (final zone in AppConstants.serviceZones) {
      final center = zone['center'] as Map<String, dynamic>;
      final double zoneRadiusMeters = (zone['radiusKm'] as num) * 1000;

      final double distanceMeters = Geolocator.distanceBetween(
        (center['lat'] as num).toDouble(),
        (center['lng'] as num).toDouble(),
        lat,
        lng,
      );

      if (distanceMeters <= zoneRadiusMeters) return true;
    }
    return false;
  }

  /// Returns the name of the matching zone, or null if out of range.
  static String? getZoneName(double lat, double lng) {
    for (final zone in AppConstants.serviceZones) {
      final center = zone['center'] as Map<String, dynamic>;
      final double zoneRadiusMeters = (zone['radiusKm'] as num) * 1000;

      final double distanceMeters = Geolocator.distanceBetween(
        (center['lat'] as num).toDouble(),
        (center['lng'] as num).toDouble(),
        lat,
        lng,
      );

      if (distanceMeters <= zoneRadiusMeters) return zone['name'] as String;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Phone Validation
  // ---------------------------------------------------------------------------

  /// Validates Sri Lankan mobile numbers (07x format).
  static bool isValidSriLankanPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'[\s\-+]'), '');
    // Local: 07XXXXXXXX or international: 947XXXXXXXX
    final local = RegExp(r'^07[0-9]{8}$');
    final intl = RegExp(r'^947[0-9]{8}$');
    return local.hasMatch(clean) || intl.hasMatch(clean);
  }
}
