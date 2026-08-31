import 'package:google_maps_flutter/google_maps_flutter.dart';

class Zone {
  final String id;
  final String name;
  final LatLng center;
  final double radiusKm;
  final List<String> allowedServices;

  const Zone({
    required this.id,
    required this.name,
    required this.center,
    required this.radiusKm,
    required this.allowedServices,
  });
}

class ColomboZones {
  static final Zone zoneA = Zone(
    id: 'colombo_03_04',
    name: "Kollupitiya-Bambalapitiya",
    center: const LatLng(6.8940, 79.8580),
    radiusKm: 2.5,
    allowedServices: ['cleaning', 'babysitting'],
  );

  static final Zone zoneB = Zone(
    id: 'colombo_07',
    name: "Cinnamon Gardens",
    center: const LatLng(6.9110, 79.8640),
    radiusKm: 2.0,
    allowedServices: ['cleaning', 'babysitting', 'elder_care'],
  );

  static final Zone zoneC = Zone(
    id: 'rajagiriya',
    name: "Rajagiriya",
    center: const LatLng(6.9090, 79.8970),
    radiusKm: 3.0,
    allowedServices: ['cleaning'],
  );

  static final List<Zone> allActiveZones = [zoneA, zoneB, zoneC];
}
