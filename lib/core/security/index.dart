/// Security Library
/// 
/// Sprint 5: Security Hardening for HelaService
/// 
/// This library provides security utilities:
/// - Input validation and sanitization
/// - NIC/Phone validation
/// - Password validation
/// - XSS/Injection protection
/// 
/// Usage:
/// ```dart
/// import 'package:home_service_app/core/security/index.dart';
/// ```

// Validators
export '../utils/nic_validator.dart';
export '../utils/phone_validator.dart';
export '../utils/validators.dart';

/// Security library version
const String securityLibraryVersion = '1.0.0';

/// Security configuration
class SecurityConfig {
  SecurityConfig._();

  // Rate limiting
  static const int maxOtpRequestsPerMinute = 3;
  static const int maxJobCreationsPerMinute = 10;
  static const int maxSearchRequestsPerMinute = 30;
  static const int maxFeedbackPerHour = 5;
  static const int maxApiRequestsPerMinute = 100;

  // Input validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int maxNameLength = 100;
  static const int maxAddressLength = 500;
  static const int maxDescriptionLength = 1000;
  static const int maxFeedbackLength = 2000;

  // Data retention (PDPA)
  static const int messageRetentionDays = 30;
  static const int jobArchiveDays = 90;
  static const int rateLimitRetentionHours = 24;
}

/// Security status
class SecurityStatus {
  final bool appCheckEnabled;
  final bool inputValidationEnabled;
  final bool rateLimitingEnabled;
  final bool auditLoggingEnabled;

  const SecurityStatus({
    this.appCheckEnabled = true,
    this.inputValidationEnabled = true,
    this.rateLimitingEnabled = true,
    this.auditLoggingEnabled = true,
  });

  static const enabled = SecurityStatus();
  static const disabled = SecurityStatus(
    appCheckEnabled: false,
    inputValidationEnabled: false,
    rateLimitingEnabled: false,
    auditLoggingEnabled: false,
  );
}

/// Quick validation helpers
class QuickValidate {
  QuickValidate._();

  /// NIC validation
  static bool nic(String value) => 
      NICValidator.validate(value) == null;

  /// Phone validation
  static bool phone(String value) => 
      PhoneValidator.validate(value) == null;

  /// Email validation
  static bool email(String value, {bool required = false}) =>
      SLValidators.isValidSriLankanPhone(value); // Use phone validation for now

  /// Name validation
  static bool name(String value, {int minLength = 2}) =>
      value.trim().length >= minLength;

  /// Password validation
  static bool password(String value, {int minLength = 8}) =>
      value.length >= minLength;

  /// OTP validation
  static bool otp(String value, {int length = 6}) =>
      RegExp(r'^[0-9]+$').hasMatch(value) && value.length == length;

  /// Amount validation
  static bool amount(String value, {double maxAmount = 100000}) {
    final amount = double.tryParse(value);
    return amount != null && amount > 0 && amount <= maxAmount;
  }
}

/// Sanitization helpers
class QuickSanitize {
  QuickSanitize._();

  /// Sanitize for HTML display
  static String html(String input) => 
      input.replaceAll('<', '&lt;').replaceAll('>', '&gt;');

  /// Sanitize for plain text display
  static String text(String input) => 
      input.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
}
