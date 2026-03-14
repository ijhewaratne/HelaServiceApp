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
    return Booking(
      bookingId: json['bookingId'] ?? '',
      customerId: json['customerId'] ?? '',
      workerId: json['workerId'],
      serviceType: json['serviceType'] ?? '',
      packageType: json['packageType'] ?? '',
      bookingDate: json['bookingDate'] ?? '',
      startTime: json['startTime'] ?? '',
      durationHours: json['durationHours'] ?? 1,
      addressText: json['address']?['text'] ?? '',
      addressLat: (json['address']?['lat'] ?? 0.0).toDouble(),
      addressLng: (json['address']?['lng'] ?? 0.0).toDouble(),
      specialNotes: json['specialNotes'] ?? '',
      status: json['status'] ?? 'draft',
      price: (json['price'] ?? 0.0).toDouble(),
      paymentStatus: json['paymentStatus'] ?? 'unpaid',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : DateTime.now(),
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
