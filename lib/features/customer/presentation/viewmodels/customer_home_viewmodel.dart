import 'package:flutter/foundation.dart';
import '../../domain/booking.dart';
import '../../data/booking_repository.dart';

class CustomerViewModel extends ChangeNotifier {
  final BookingRepository _bookingRepository;

  bool _isLoading = false;
  String? _errorMessage;
  List<Booking> _activeBookings = [];

  CustomerViewModel(this._bookingRepository);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Booking> get activeBookings => _activeBookings;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> fetchMyBookings(String customerId) async {
    _setLoading(true);
    _setError(null);
    try {
      _activeBookings = await _bookingRepository.getCustomerBookings(customerId);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
}
