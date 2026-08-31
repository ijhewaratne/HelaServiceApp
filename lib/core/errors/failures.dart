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

/// Sign-in paused pending a second-factor (MFA) code. Not a terminal error —
/// the caller should prompt for the authenticator code and complete sign-in
/// via AuthRepository.completeMfaChallenge.
class MfaRequiredFailure extends Failure {
  const MfaRequiredFailure() : super('Two-factor authentication code required');
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
  factory GenericFailure.duplicateNIC() =>
      const GenericFailure('NIC already exists');

  /// Factory constructor for file too large errors
  factory GenericFailure.fileTooLarge() =>
      const GenericFailure('File size exceeds limit');

  /// Factory constructor for network errors
  factory GenericFailure.network() =>
      const GenericFailure('Network connection error');
}

/// Payment-specific failures
class PaymentFailure extends Failure {
  final String? code;
  final PaymentFailureType type;

  const PaymentFailure(
    String message, {
    this.code,
    this.type = PaymentFailureType.unknown,
  }) : super(message);

  @override
  List<Object?> get props => [message, code, type];
}

/// Types of payment failures
enum PaymentFailureType {
  initialization,
  network,
  cancelled,
  declined,
  timeout,
  invalidAmount,
  unknown,
}
