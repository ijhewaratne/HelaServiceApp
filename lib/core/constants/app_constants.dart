class AppConstants {
  // Legal & Compliance
  static const String appName = 'HelaService';
  static const String companySolePropName =
      'Your Name'; // Update until PLC formed

  // Bump these when the corresponding document materially changes — each
  // bump requires re-acceptance from every user (see ConsentRepository).
  static const String termsVersion = '1.0';
  static const String privacyVersion = '1.0';

  // Geofencing - Colombo Launch Zones
  static const List<Map<String, dynamic>> serviceZones = [
    {
      'id': 'col_03_04',
      'name': 'Kollupitiya-Bambalapitiya',
      'center': {'lat': 6.8940, 'lng': 79.8580},
      'radiusKm': 2.5,
      'allowedServices': ['cleaning', 'babysitting', 'elderly_care'],
    },
    {
      'id': 'col_07',
      'name': 'Cinnamon Gardens',
      'center': {'lat': 6.9119, 'lng': 79.8716},
      'radiusKm': 3.0,
      'allowedServices': ['cleaning', 'babysitting', 'elderly_care', 'cooking'],
    },
    {
      'id': 'rajagiriya',
      'name': 'Rajagiriya-Nawala',
      'center': {'lat': 6.9108, 'lng': 79.8927},
      'radiusKm': 2.0,
      'allowedServices': ['cleaning', 'cooking'],
    },
  ];

  // PDPA Compliance
  static const int dataRetentionDays = 30;
  static const bool allowMedicalDataStorage = false; // v1 safety gate

  // WhatsApp Operator Hotline (for emergency incident reporting)
  static const String operatorWhatsApp =
      '+94770000000'; // Replace before launch

  // Emergency Phone Hotline (for direct calls)
  static const String emergencyPhone = '0112345678'; // Replace before launch

  // Booking State Machine Stages
  static const List<String> bookingStatuses = [
    'draft',
    'requested',
    'assigned',
    'worker_on_the_way',
    'checked_in',
    'completed',
    'cancelled',
  ];
}
