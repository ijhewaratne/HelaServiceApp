/// Canonical service category enum, shared by booking, worker and promo
/// entities. Previously declared separately (and inconsistently) in
/// booking.dart (10 values) and worker.dart/worker_application.dart
/// (5 values each) — the worker-side subset meant a worker could never be
/// matched for plumbing, electrical, acRepair or gardening bookings.
enum ServiceType {
  cleaning,
  plumbing,
  electrical,
  acRepair,
  gardening,
  babysitting,
  elderlyCare,
  cooking,
  laundry,
  other,
}

extension ServiceTypeX on ServiceType {
  String get displayName {
    switch (this) {
      case ServiceType.cleaning:
        return 'Home Cleaning';
      case ServiceType.plumbing:
        return 'Plumbing';
      case ServiceType.electrical:
        return 'Electrical';
      case ServiceType.acRepair:
        return 'AC Repair';
      case ServiceType.gardening:
        return 'Gardening';
      case ServiceType.babysitting:
        return 'Babysitting';
      case ServiceType.elderlyCare:
        return 'Elderly Care';
      case ServiceType.cooking:
        return 'Cooking Help';
      case ServiceType.laundry:
        return 'Laundry & Ironing';
      case ServiceType.other:
        return 'Other';
    }
  }

  String get description {
    switch (this) {
      case ServiceType.cleaning:
        return 'General house cleaning, sweeping, mopping';
      case ServiceType.plumbing:
        return 'Pipe, tap and drainage repairs and installation';
      case ServiceType.electrical:
        return 'Wiring, fixtures and electrical repairs';
      case ServiceType.acRepair:
        return 'Air conditioner servicing and repair';
      case ServiceType.gardening:
        return 'Garden and outdoor maintenance';
      case ServiceType.babysitting:
        return 'Child care (non-medical), feeding, playing';
      case ServiceType.elderlyCare:
        return 'Companion care, assistance with mobility (no medical tasks)';
      case ServiceType.cooking:
        return 'Meal preparation, kitchen help';
      case ServiceType.laundry:
        return 'Washing and ironing clothes';
      case ServiceType.other:
        return 'Other household service';
    }
  }

  String get icon {
    switch (this) {
      case ServiceType.cleaning:
        return '🧹';
      case ServiceType.plumbing:
        return '🔧';
      case ServiceType.electrical:
        return '💡';
      case ServiceType.acRepair:
        return '❄️';
      case ServiceType.gardening:
        return '🌱';
      case ServiceType.babysitting:
        return '👶';
      case ServiceType.elderlyCare:
        return '❤️';
      case ServiceType.cooking:
        return '🍳';
      case ServiceType.laundry:
        return '👕';
      case ServiceType.other:
        return '🔹';
    }
  }
}
