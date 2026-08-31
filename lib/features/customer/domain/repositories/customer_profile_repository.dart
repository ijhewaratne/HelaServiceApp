import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/customer_profile.dart';

abstract class CustomerProfileRepository {
  Future<Either<Failure, CustomerProfile>> getProfile(String userId);
  Future<Either<Failure, CustomerProfile>> createProfile(
    CustomerProfile profile,
  );
  Future<Either<Failure, CustomerProfile>> updateProfile(
    CustomerProfile profile,
  );
  Future<Either<Failure, List<CustomerProfile>>> getAllCustomers();
  Future<Either<Failure, void>> suspendCustomer(String userId);
  Future<Either<Failure, void>> reactivateCustomer(String userId);
  Stream<CustomerProfile> watchProfile(String userId);
}
