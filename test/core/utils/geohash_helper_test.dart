import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/core/utils/geohash_helper.dart';

void main() {
  group('GeohashHelper', () {
    group('encode', () {
      test('encodes Colombo coordinates correctly', () {
        // Colombo coordinates
        final hash = GeohashHelper.encode(6.9271, 79.8612, precision: 9);
        expect(hash, isNotEmpty);
        expect(hash.length, equals(9));
        expect(RegExp(r'^[0-9bcdefghjkmnpqrstuvwxyz]+$').hasMatch(hash), isTrue);
      });

      test('encodes with default precision of 9', () {
        final hash = GeohashHelper.encode(6.9271, 79.8612);
        expect(hash.length, equals(9));
      });

      test('encodes with custom precision', () {
        final hash = GeohashHelper.encode(6.9271, 79.8612, precision: 5);
        expect(hash.length, equals(5));
      });

      test('produces consistent hashes for same coordinates', () {
        final hash1 = GeohashHelper.encode(6.9271, 79.8612, precision: 9);
        final hash2 = GeohashHelper.encode(6.9271, 79.8612, precision: 9);
        expect(hash1, equals(hash2));
      });

      test('produces different hashes for different coordinates', () {
        final hash1 = GeohashHelper.encode(6.9271, 79.8612, precision: 9);
        final hash2 = GeohashHelper.encode(6.9147, 79.9723, precision: 9);
        expect(hash1, isNot(equals(hash2)));
      });

      test('handles negative coordinates', () {
        final hash = GeohashHelper.encode(-33.8688, 151.2093, precision: 9);
        expect(hash, isNotEmpty);
        expect(hash.length, equals(9));
      });

      test('handles coordinates at equator and prime meridian', () {
        final hash = GeohashHelper.encode(0.0, 0.0, precision: 9);
        expect(hash, isNotEmpty);
        expect(hash.length, equals(9));
      });

      test('handles maximum precision of 12', () {
        final hash = GeohashHelper.encode(6.9271, 79.8612, precision: 12);
        expect(hash.length, equals(12));
      });
    });

    group('decode', () {
      test('decodes geohash to approximate center coordinates', () {
        const lat = 6.9271;
        const lon = 79.8612;
        final hash = GeohashHelper.encode(lat, lon, precision: 9);
        final decoded = GeohashHelper.decode(hash);
        
        expect(decoded, isNotNull);
        expect(decoded.containsKey('latitude'), isTrue);
        expect(decoded.containsKey('longitude'), isTrue);
        expect(decoded.containsKey('latitudeError'), isTrue);
        expect(decoded.containsKey('longitudeError'), isTrue);
        
        // Decoded center should be close to original
        expect((decoded['latitude']! - lat).abs(), lessThan(0.001));
        expect((decoded['longitude']! - lon).abs(), lessThan(0.001));
      });

      test('decode is inverse of encode approximately', () {
        const lat = 6.9271;
        const lon = 79.8612;
        final hash = GeohashHelper.encode(lat, lon, precision: 9);
        final decoded = GeohashHelper.decode(hash);
        
        // Center of decoded bbox should be close to original
        final centerLat = decoded['latitude']!;
        final centerLon = decoded['longitude']!;
        
        expect((centerLat - lat).abs(), lessThan(0.001));
        expect((centerLon - lon).abs(), lessThan(0.001));
      });

      test('returns error bounds', () {
        final hash = GeohashHelper.encode(6.9271, 79.8612, precision: 9);
        final decoded = GeohashHelper.decode(hash);
        
        expect(decoded['latitudeError'], greaterThan(0));
        expect(decoded['longitudeError'], greaterThan(0));
      });
    });

    group('getNeighbors', () {
      test('returns 8 neighboring geohashes', () {
        final hash = GeohashHelper.encode(6.9271, 79.8612, precision: 9);
        final neighbors = GeohashHelper.getNeighbors(hash);
        
        expect(neighbors.length, equals(8));
        expect(neighbors.contains(hash), isFalse);
        
        // All neighbors should be valid geohashes
        for (final neighbor in neighbors) {
          expect(neighbor.length, equals(hash.length));
          expect(RegExp(r'^[0-9bcdefghjkmnpqrstuvwxyz]+$').hasMatch(neighbor), isTrue);
        }
      });

      test('neighbors are unique', () {
        final hash = GeohashHelper.encode(6.9271, 79.8612, precision: 9);
        final neighbors = GeohashHelper.getNeighbors(hash);
        
        final uniqueNeighbors = neighbors.toSet();
        expect(uniqueNeighbors.length, equals(neighbors.length));
      });

      test('neighbors are close to original', () {
        final hash = GeohashHelper.encode(6.9271, 79.8612, precision: 9);
        final original = GeohashHelper.decode(hash);
        final neighbors = GeohashHelper.getNeighbors(hash);
        
        // All neighbors should be relatively close
        for (final neighbor in neighbors) {
          final decoded = GeohashHelper.decode(neighbor);
          final latDiff = (decoded['latitude']! - original['latitude']!).abs();
          final lonDiff = (decoded['longitude']! - original['longitude']!).abs();
          
          // Neighbors should be within ~10km for precision 9
          expect(latDiff, lessThan(0.1));
          expect(lonDiff, lessThan(0.1));
        }
      });
    });

    group('precisionForRadius', () {
      test('returns higher precision for smaller radius', () {
        expect(GeohashHelper.precisionForRadius(0.001), equals(9));
        expect(GeohashHelper.precisionForRadius(0.005), equals(9));
      });

      test('returns appropriate precision for medium radius', () {
        expect(GeohashHelper.precisionForRadius(0.5), equals(6));
        expect(GeohashHelper.precisionForRadius(2.5), equals(5));
      });

      test('returns lower precision for larger radius', () {
        expect(GeohashHelper.precisionForRadius(50), equals(3));
        expect(GeohashHelper.precisionForRadius(200), equals(2));
      });

      test('precision decreases as radius increases', () {
        final p1 = GeohashHelper.precisionForRadius(0.01);
        final p2 = GeohashHelper.precisionForRadius(1);
        final p3 = GeohashHelper.precisionForRadius(100);
        
        expect(p1, greaterThan(p2));
        expect(p2, greaterThan(p3));
      });
    });
  });
}
