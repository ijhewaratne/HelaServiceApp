import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/booking.dart';

/// Abstract repository for booking operations
/// 
/// Phase 2: Architecture Refactoring - Updated to use Booking entity
abstract class BookingRepository {
  /// Create a new booking
  Future<Either<Failure, Booking>> createBooking(Booking booking);
  
  /// Get booking by ID
  Future<Either<Failure, Booking>> getBooking(String bookingId);
  
  /// Update booking
  Future<Either<Failure, Booking>> updateBooking(
    String bookingId,
    Map<String, dynamic> data,
  );
  
  /// Cancel booking
  Future<Either<Failure, void>> cancelBooking(
    String bookingId, {
    String? reason,
  });
  
  /// Get customer bookings
  Future<Either<Failure, List<Booking>>> getCustomerBookings(String customerId);
  
  /// Get worker bookings
  Future<Either<Failure, List<Booking>>> getWorkerBookings(String workerId);
  
  /// Get active booking for customer
  Future<Either<Failure, Booking?>> getActiveBookingForCustomer(String customerId);
  
  /// Get active booking for worker
  Future<Either<Failure, Booking?>> getActiveBookingForWorker(String workerId);
  
  /// Assign worker to booking
  Future<Either<Failure, Booking>> assignWorker(String bookingId, String workerId);
  
  /// Update booking status
  Future<Either<Failure, Booking>> updateBookingStatus(
    String bookingId,
    BookingStatus status, {
    Map<String, dynamic>? additionalData,
  });
  
  /// Stream booking updates
  Stream<Either<Failure, Booking>> watchBooking(String bookingId);
}
