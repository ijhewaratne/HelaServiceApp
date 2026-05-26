class Booking {
  final String bookingId;
  final String customerId;
  final String? workerId;
  final String serviceType;
  final String packageType;
  final String bookingDate;
  final String startTime;
  final int durationHours;
  final String addressText;
  final double addressLat;
  final double addressLng;
  final String specialNotes;
  final String status;
  final double price;
  final String paymentStatus;
  final DateTime createdAt;

  Booking({
    required this.bookingId,
    required this.customerId,
    this.workerId,
    required this.serviceType,
    required this.packageType,
    required this.bookingDate,
    required this.startTime,
    required this.durationHours,
    required this.addressText,
    required this.addressLat,
    required this.addressLng,
    required this.specialNotes,
    required this.status,
    required this.price,
    required this.paymentStatus,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>?;
    return Booking(
      bookingId: json['bookingId'] as String? ?? '',
      customerId: json['customerId'] as String? ?? '',
      workerId: json['workerId'] as String?,
      serviceType: json['serviceType'] as String? ?? '',
      packageType: json['packageType'] as String? ?? '',
      bookingDate: json['bookingDate'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      durationHours: json['durationHours'] as int? ?? 1,
      addressText: address?['text'] as String? ?? '',
      addressLat: (address?['lat'] as num?)?.toDouble() ?? 0.0,
      addressLng: (address?['lng'] as num?)?.toDouble() ?? 0.0,
      specialNotes: json['specialNotes'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: json['paymentStatus'] as String? ?? 'unpaid',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'customerId': customerId,
      'workerId': workerId,
      'serviceType': serviceType,
      'packageType': packageType,
      'bookingDate': bookingDate,
      'startTime': startTime,
      'durationHours': durationHours,
      'address': {
        'text': addressText,
        'lat': addressLat,
        'lng': addressLng,
      },
      'specialNotes': specialNotes,
      'status': status,
      'price': price,
      'paymentStatus': paymentStatus,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
