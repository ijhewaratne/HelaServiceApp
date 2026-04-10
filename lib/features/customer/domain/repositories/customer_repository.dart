import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';

/// Abstract repository for customer operations
abstract class CustomerRepository {
  /// Get customer profile by ID
  Future<Either<Failure, Map<String, dynamic>>> getCustomerProfile(String customerId);
  
  /// Create new customer profile
  Future<Either<Failure, Map<String, dynamic>>> createCustomerProfile(
    String customerId,
    Map<String, dynamic> data,
  );
  
  /// Update customer profile
  Future<Either<Failure, Map<String, dynamic>>> updateCustomerProfile(
    String customerId,
    Map<String, dynamic> data,
  );
  
  /// Delete customer profile
  Future<Either<Failure, void>> deleteCustomerProfile(String customerId);
  
  /// Get customer's booking history
  Future<Either<Failure, List<Map<String, dynamic>>>> getCustomerBookings(String customerId);
  
  /// Get customer's saved addresses
  Future<Either<Failure, List<Map<String, dynamic>>>> getSavedAddresses(String customerId);
  
  /// Add new saved address
  Future<Either<Failure, Map<String, dynamic>>> addSavedAddress(
    String customerId,
    Map<String, dynamic> address,
  );
  
  /// Update saved address
  Future<Either<Failure, Map<String, dynamic>>> updateSavedAddress(
    String customerId,
    String addressId,
    Map<String, dynamic> address,
  );
  
  /// Delete saved address
  Future<Either<Failure, void>> deleteSavedAddress(String customerId, String addressId);
}
