import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/address.dart';

/// Abstract repository for customer operations
/// 
/// Phase 2: Architecture Refactoring - Updated to use Address entity
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
  Future<Either<Failure, List<Address>>> getSavedAddresses(String customerId);
  
  /// Add new saved address
  Future<Either<Failure, Address>> addSavedAddress(
    String customerId,
    Address address,
  );
  
  /// Update saved address
  Future<Either<Failure, Address>> updateSavedAddress(
    String customerId,
    String addressId,
    Address address,
  );
  
  /// Delete saved address
  Future<Either<Failure, void>> deleteSavedAddress(String customerId, String addressId);
}
