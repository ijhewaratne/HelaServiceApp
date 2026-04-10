/// Geohash encoding helper for location-based queries
class GeohashHelper {
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
  
  /// Encode latitude and longitude to geohash string
  static String encode(double latitude, double longitude, {int precision = 9}) {
    final latRange = [-90.0, 90.0];
    final lonRange = [-180.0, 180.0];
    
    final buffer = StringBuffer();
    int bits = 0;
    int bitsTotal = 0;
    int hashValue = 0;
    bool evenBit = true;
    
    while (buffer.length < precision) {
      if (evenBit) {
        final mid = (lonRange[0] + lonRange[1]) / 2;
        if (longitude > mid) {
          hashValue = (hashValue << 1) | 1;
          lonRange[0] = mid;
        } else {
          hashValue = hashValue << 1;
          lonRange[1] = mid;
        }
      } else {
        final mid = (latRange[0] + latRange[1]) / 2;
        if (latitude > mid) {
          hashValue = (hashValue << 1) | 1;
          latRange[0] = mid;
        } else {
          hashValue = hashValue << 1;
          latRange[1] = mid;
        }
      }
      
      evenBit = !evenBit;
      bitsTotal++;
      
      if (bitsTotal % 5 == 0) {
        buffer.write(_base32[hashValue]);
        bits = 0;
        hashValue = 0;
      }
    }
    
    return buffer.toString();
  }
  
  /// Decode geohash to approximate bounding box
  static Map<String, double> decode(String geohash) {
    final latRange = [-90.0, 90.0];
    final lonRange = [-180.0, 180.0];
    bool evenBit = true;
    
    for (int i = 0; i < geohash.length; i++) {
      final cd = _base32.indexOf(geohash[i]);
      
      for (int j = 4; j >= 0; j--) {
        final bit = (cd >> j) & 1;
        
        if (evenBit) {
          final mid = (lonRange[0] + lonRange[1]) / 2;
          if (bit == 1) {
            lonRange[0] = mid;
          } else {
            lonRange[1] = mid;
          }
        } else {
          final mid = (latRange[0] + latRange[1]) / 2;
          if (bit == 1) {
            latRange[0] = mid;
          } else {
            latRange[1] = mid;
          }
        }
        
        evenBit = !evenBit;
      }
    }
    
    return {
      'latitude': (latRange[0] + latRange[1]) / 2,
      'longitude': (lonRange[0] + lonRange[1]) / 2,
      'latitudeError': latRange[1] - (latRange[0] + latRange[1]) / 2,
      'longitudeError': lonRange[1] - (lonRange[0] + lonRange[1]) / 2,
    };
  }
  
  /// Get neighboring geohashes (8 surrounding cells)
  static List<String> getNeighbors(String geohash) {
    final neighbors = <String>[];
    final directions = [
      [1, 0],   // North
      [1, 1],   // Northeast
      [0, 1],   // East
      [-1, 1],  // Southeast
      [-1, 0],  // South
      [-1, -1], // Southwest
      [0, -1],  // West
      [1, -1],  // Northwest
    ];
    
    final center = decode(geohash);
    final lat = center['latitude']!;
    final lon = center['longitude']!;
    final latError = center['latitudeError']!;
    final lonError = center['longitudeError']!;
    
    for (final dir in directions) {
      final newLat = lat + dir[0] * latError * 2;
      final newLon = lon + dir[1] * lonError * 2;
      neighbors.add(encode(newLat, newLon, precision: geohash.length));
    }
    
    return neighbors;
  }
  
  /// Calculate geohash precision for a given radius in kilometers
  static int precisionForRadius(double radiusKm) {
    if (radiusKm <= 0.005) return 9;
    if (radiusKm <= 0.02) return 8;
    if (radiusKm <= 0.1) return 7;
    if (radiusKm <= 0.5) return 6;
    if (radiusKm <= 2.5) return 5;
    if (radiusKm <= 20) return 4;
    if (radiusKm <= 100) return 3;
    return 2;
  }
}
