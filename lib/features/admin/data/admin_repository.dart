import '../../worker/domain/worker_profile.dart';
import '../../customer/domain/booking.dart';
import '../domain/incident.dart';

class AdminRepository {
  Future<List<WorkerProfile>> getPendingWorkers() async {
    // Abstracted: Fetch WorkerProfiles where status == 'pending'
    await Future.delayed(const Duration(milliseconds: 600));
    return [
      WorkerProfile(
        uid: 'wrk_999',
        name: 'Pending Jane',
        phone: '+94711111111',
        district: 'Colombo',
        serviceTypes: ['cleaning'],
        languages: ['English'],
        verificationStatus: 'pending',
        rating: 0.0,
        completedJobs: 0,
        isAvailable: false,
        availabilityMode: 'part_time'
      )
    ];
  }

  Future<void> updateWorkerStatus(String workerId, String status) async {
    // Abstracted: Update status in Firestore
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<List<Booking>> getActiveBookings() async {
    // Abstracted: Fetch Bookings where status in ['requested', 'assigned', 'checked_in']
    await Future.delayed(const Duration(milliseconds: 600));
    return [
      Booking(
        bookingId: 'bk_123',
        customerId: 'cus_456',
        workerId: null, // Needs assignment
        serviceType: 'cleaning',
        packageType: '4_hours',
        bookingDate: '2026-03-20',
        startTime: '10:00 AM',
        durationHours: 4,
        addressText: 'No 15, Colombo 05',
        addressLat: 6.89,
        addressLng: 79.86,
        specialNotes: '',
        status: 'requested',
        price: 4800,
        paymentStatus: 'paid',
        createdAt: DateTime.now()
      )
    ];
  }

  Future<void> assignWorkerToBooking(String bookingId, String workerId) async {
    // Abstracted: Update workerId and change status to 'assigned'
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<List<Incident>> getOpenIncidents() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      Incident(
        incidentId: 'inc_888',
        bookingId: 'bk_123',
        reportedBy: 'cus_456',
        type: 'late_arrival',
        description: 'Worker arrived 40 minutes late',
        severity: 'medium',
        status: 'open',
        createdAt: DateTime.now()
      )
    ];
  }
}
