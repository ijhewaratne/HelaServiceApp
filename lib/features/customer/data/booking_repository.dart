import '../domain/booking.dart';
import '../domain/service_category.dart';
import 'package:uuid/uuid.dart';

class BookingRepository {
  Future<List<ServiceCategory>> getAvailableServices() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      ServiceCategory(id: 'cleaning', name: 'Home Cleaning', baseRatePerHour: 1200, active: true),
      ServiceCategory(id: 'babysitting', name: 'Babysitting', baseRatePerHour: 1500, active: true),
      ServiceCategory(id: 'elder_care', name: 'Elder Care', baseRatePerHour: 1300, active: true),
    ];
  }

  Future<Booking> createBooking(Booking booking) async {
    await Future.delayed(const Duration(seconds: 1));
    return Booking(
      bookingId: const Uuid().v4(),
      customerId: booking.customerId,
      workerId: null,
      serviceType: booking.serviceType,
      packageType: booking.packageType,
      bookingDate: booking.bookingDate,
      startTime: booking.startTime,
      durationHours: booking.durationHours,
      addressText: booking.addressText,
      addressLat: booking.addressLat,
      addressLng: booking.addressLng,
      specialNotes: booking.specialNotes,
      status: 'requested',
      price: booking.price,
      paymentStatus: 'paid', // Assuming PSP integration went well in UI layer before this
      createdAt: DateTime.now(),
    );
  }

  Future<List<Booking>> getCustomerBookings(String customerId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return []; // Empty list for mock
  }
}
