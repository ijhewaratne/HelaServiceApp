import 'package:equatable/equatable.dart';

/// Base Failure class
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Server/Network failures
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Cache failures
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Not found failures
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Generic failure for backward compatibility
class GenericFailure extends Failure {
  const GenericFailure(super.message);

  /// Factory constructor for duplicate NIC errors
  factory GenericFailure.duplicateNIC() => const GenericFailure('NIC already exists');

  /// Factory constructor for file too large errors
  factory GenericFailure.fileTooLarge() => const GenericFailure('File size exceeds limit');

  /// Factory constructor for network errors
  factory GenericFailure.network() => const GenericFailure('Network connection error');
}
