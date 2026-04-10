/// Base exception class for HelaService
class ServerException implements Exception {
  final String message;
  final String? code;

  const ServerException(this.message, {this.code});

  @override
  String toString() => 'ServerException: $message (code: $code)';
}

class CacheException implements Exception {
  final String message;

  const CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException([this.message = 'No internet connection']);

  @override
  String toString() => 'NetworkException: $message';
}

class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException: $message (code: $code)';
}

class ValidationException implements Exception {
  final String message;
  final Map<String, String>? errors;

  const ValidationException(this.message, {this.errors});

  @override
  String toString() => 'ValidationException: $message';
}

class LocationException implements Exception {
  final String message;

  const LocationException(this.message);

  @override
  String toString() => 'LocationException: $message';
}

class PermissionException implements Exception {
  final String message;

  const PermissionException(this.message);

  @override
  String toString() => 'PermissionException: $message';
}
