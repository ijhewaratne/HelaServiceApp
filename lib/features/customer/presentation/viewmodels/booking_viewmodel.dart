import 'package:flutter/foundation.dart';
import '../../domain/booking.dart';
import '../../domain/service_category.dart';
import '../../data/booking_repository.dart';

class BookingViewModel extends ChangeNotifier {
  final BookingRepository _bookingRepository;

  bool _isLoading = false;
  String? _errorMessage;
  List<ServiceCategory> _availableServices = [];

  // Temporary booking state for the multi-step flow
  ServiceCategory? selectedCategory;
  String? bookingDate;
  String? startTime;
  int durationHours = 2;
  String? addressText;
  double? addressLat;
  double? addressLng;

  BookingViewModel(this._bookingRepository);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ServiceCategory> get availableServices => _availableServices;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> fetchServices() async {
    _setLoading(true);
    _setError(null);
    try {
      _availableServices = await _bookingRepository.getAvailableServices();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  double calculateTotalPrice() {
    if (selectedCategory == null) return 0;
    return selectedCategory!.baseRatePerHour * durationHours;
  }

  Future<bool> confirmBooking(String customerId) async {
    if (selectedCategory == null || bookingDate == null || startTime == null || addressText == null) {
      _setError("Missing required booking info");
      return false;
    }

    _setLoading(true);
    _setError(null);
    try {
      final newBooking = Booking(
        bookingId: '',
        customerId: customerId,
        serviceType: selectedCategory!.id,
        packageType: '${durationHours}_hours',
        bookingDate: bookingDate!,
        startTime: startTime!,
        durationHours: durationHours,
        addressText: addressText!,
        addressLat: addressLat ?? 6.9,
        addressLng: addressLng ?? 79.8,
        specialNotes: '',
        status: 'draft',
        price: calculateTotalPrice(),
        paymentStatus: 'unpaid',
        createdAt: DateTime.now(),
      );

      await _bookingRepository.createBooking(newBooking);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearBookingState() {
    selectedCategory = null;
    bookingDate = null;
    startTime = null;
    durationHours = 2;
    addressText = null;
    addressLat = null;
    addressLng = null;
    notifyListeners();
  }
}
