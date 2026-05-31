import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/booking.dart';
import '../domain/service_category.dart';
import 'package:uuid/uuid.dart';

class BookingRepository {
  final FirebaseFirestore _firestore;

  BookingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<ServiceCategory>> getAvailableServices() async {
    try {
      final snap = await _firestore
          .collection('service_catalog')
          .where('isActive', isEqualTo: true)
          .where('layer', isEqualTo: 'category')
          .get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.map((d) {
          final data = d.data();
          return ServiceCategory(
            id: d.id,
            name: data['name'] as String? ?? d.id,
            baseRatePerHour: (data['baseRatePerHour'] as num?)?.toDouble() ?? 0,
            active: data['isActive'] as bool? ?? true,
          );
        }).toList();
      }
    } catch (_) {}
    // Fallback to hardcoded list when Firestore is unavailable (emulator / tests)
    return [
      ServiceCategory(id: 'elder_companionship', name: 'Elder Companionship', baseRatePerHour: 600, active: true),
      ServiceCategory(id: 'babysitting', name: 'Babysitting', baseRatePerHour: 650, active: true),
      ServiceCategory(id: 'kitchen_helper', name: 'Kitchen Helper', baseRatePerHour: 450, active: true),
      ServiceCategory(id: 'laundry_helper', name: 'Laundry Helper', baseRatePerHour: 400, active: true),
      ServiceCategory(id: 'hourly_household_support', name: 'Hourly Household Support', baseRatePerHour: 400, active: true),
    ];
  }

  Future<double> getWalletBalance(String customerId) async {
    try {
      final doc = await _firestore.collection('wallets').doc(customerId).get();
      final data = doc.data();
      if (data != null) {
        final available = (data['availableBalance'] as num?)?.toDouble();
        final total = (data['balance'] as num?)?.toDouble();
        final held = (data['heldBalance'] as num?)?.toDouble() ?? 0;
        return available ?? ((total ?? 0) - held);
      }
    } catch (_) {}
    return 0.0;
  }

  Future<Booking> createBooking(Booking booking) async {
    final id = const Uuid().v4();
    final data = {
      ...booking.toJson(),
      'bookingId': id,
      'status': 'requested',
      'paymentStatus': 'unpaid',
      'createdAt': FieldValue.serverTimestamp(),
    };
    await _firestore.collection('bookings').doc(id).set(data);
    return Booking(
      bookingId: id,
      customerId: booking.customerId,
      serviceType: booking.serviceType,
      packageType: booking.packageType,
      bookingDate: booking.bookingDate,
      startTime: booking.startTime,
      durationHours: booking.durationHours,
      addressText: booking.addressText,
      addressLat: booking.addressLat,
      addressLng: booking.addressLng,
      specialNotes: booking.specialNotes,
      isRecurring: booking.isRecurring,
      recurringPattern: booking.recurringPattern,
      recurringEndDate: booking.recurringEndDate,
      status: 'requested',
      price: booking.price,
      paymentStatus: 'unpaid',
      createdAt: DateTime.now(),
    );
  }

  Future<List<Booking>> getCustomerBookings(String customerId) async {
    try {
      final snap = await _firestore
          .collection('bookings')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map((d) => Booking.fromJson(d.data())).toList();
    } catch (_) {
      return [];
    }
  }
}
