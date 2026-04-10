import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';

/// Abstract repository for booking operations
abstract class BookingRepository {
  /// Create a new booking
  Future<Either<Failure, Map<String, dynamic>>> createBooking(
    Map<String, dynamic> bookingData,
  );
  
  /// Get booking by ID
  Future<Either<Failure, Map<String, dynamic>>> getBooking(String bookingId);
  
  /// Update booking
  Future<Either<Failure, Map<String, dynamic>>> updateBooking(
    String bookingId,
    Map<String, dynamic> data,
  );
  
  /// Cancel booking
  Future<Either<Failure, void>> cancelBooking(
    String bookingId, {
    String? reason,
  });
  
  /// Get customer bookings
  Future<Either<Failure, List<Map<String, dynamic>>>> getCustomerBookings(
    String customerId,
  );
  
  /// Get worker bookings
  Future<Either<Failure, List<Map<String, dynamic>>>> getWorkerBookings(
    String workerId,
  );
  
  /// Get active booking for customer
  Future<Either<Failure, Map<String, dynamic>?>> getActiveBookingForCustomer(
    String customerId,
  );
  
  /// Get active booking for worker
  Future<Either<Failure, Map<String, dynamic>?>> getActiveBookingForWorker(
    String workerId,
  );
  
  /// Assign worker to booking
  Future<Either<Failure, Map<String, dynamic>>> assignWorker(
    String bookingId,
    String workerId,
  );
  
  /// Update booking status
  Future<Either<Failure, Map<String, dynamic>>> updateBookingStatus(
    String bookingId,
    String status, {
    Map<String, dynamic>? additionalData,
  });
  
  /// Stream booking updates
  Stream<Either<Failure, Map<String, dynamic>>> watchBooking(String bookingId);
}
