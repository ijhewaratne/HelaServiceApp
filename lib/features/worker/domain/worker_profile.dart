class WorkerProfile {
  final String uid;
  final String name;
  final String phone;
  final String district;
  final List<String> serviceTypes;
  final List<String> languages;
  final String verificationStatus;
  final double rating;
  final int completedJobs;
  final bool isAvailable;
  final double? currentLat;
  final double? currentLng;
  final String availabilityMode;
  final String? badge;

  WorkerProfile({
    required this.uid,
    required this.name,
    required this.phone,
    required this.district,
    required this.serviceTypes,
    required this.languages,
    required this.verificationStatus,
    required this.rating,
    required this.completedJobs,
    required this.isAvailable,
    this.currentLat,
    this.currentLng,
    required this.availabilityMode,
    this.badge,
  });

  factory WorkerProfile.fromJson(Map<String, dynamic> json) {
    return WorkerProfile(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      district: json['district'] ?? '',
      serviceTypes: List<String>.from(json['serviceTypes'] ?? []),
      languages: List<String>.from(json['languages'] ?? []),
      verificationStatus: json['verificationStatus'] ?? 'pending',
      rating: (json['rating'] ?? 0.0).toDouble(),
      completedJobs: json['completedJobs'] ?? 0,
      isAvailable: json['isAvailable'] ?? false,
      currentLat: json['currentLat']?.toDouble(),
      currentLng: json['currentLng']?.toDouble(),
      availabilityMode: json['availabilityMode'] ?? 'part_time',
      badge: json['badge'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'district': district,
      'serviceTypes': serviceTypes,
      'languages': languages,
      'verificationStatus': verificationStatus,
      'rating': rating,
      'completedJobs': completedJobs,
      'isAvailable': isAvailable,
      'currentLat': currentLat,
      'currentLng': currentLng,
      'availabilityMode': availabilityMode,
      'badge': badge,
    };
  }
}
