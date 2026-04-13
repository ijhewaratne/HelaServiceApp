import 'nic_validator.dart';
import 'phone_validator.dart';

/// Comprehensive input validation utilities for HelaService
/// Sprint 5: Security Hardening
/// 
/// Use these validators for all user input to prevent injection attacks
/// and ensure data integrity.
class InputValidators {
  InputValidators._(); // Private constructor

  // ============================================================================
  // PERSONAL INFORMATION
  // ============================================================================

  /// Validates Sri Lankan NIC (both old and new formats)
  static String? validateNIC(String? value) {
    return NICValidator.validate(value);
  }

  /// Validates Sri Lankan mobile phone number
  static String? validatePhone(String? value) {
    return PhoneValidator.validate(value);
  }

  /// Validates full name
  static String? validateName(String? value, {int minLength = 2, int maxLength = 100}) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    
    final trimmed = value.trim();
    
    if (trimmed.length < minLength) {
      return 'Name must be at least $minLength characters';
    }
    
    if (trimmed.length > maxLength) {
      return 'Name must be less than $maxLength characters';
    }
    
    // Only allow letters, spaces, and common name characters
    final validNameRegex = RegExp(r"^[a-zA-Z\s.'-]+$");
    if (!validNameRegex.hasMatch(trimmed)) {
      return 'Name contains invalid characters';
    }
    
    // Check for potential injection attempts
    if (_containsInjectionPattern(trimmed)) {
      return 'Name contains invalid characters';
    }
    
    return null;
  }

  /// Validates email address
  static String? validateEmail(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Email is required' : null;
    }
    
    final trimmed = value.trim().toLowerCase();
    
    // Strict email regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Enter a valid email address';
    }
    
    // Block suspicious domains
    final blockedDomains = [
      'tempmail.com',
      'throwaway.com',
      'mailinator.com',
      'guerrillamail.com',
    ];
    
    final domain = trimmed.split('@').last.toLowerCase();
    if (blockedDomains.contains(domain)) {
      return 'This email domain is not allowed';
    }
    
    return null;
  }

  // ============================================================================
  // ADDRESS & LOCATION
  // ============================================================================

  /// Validates address text
  static String? validateAddress(String? value, {int maxLength = 500}) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }
    
    final trimmed = value.trim();
    
    if (trimmed.length < 5) {
      return 'Address is too short';
    }
    
    if (trimmed.length > maxLength) {
      return 'Address is too long (max $maxLength characters)';
    }
    
    // Check for injection patterns
    if (_containsInjectionPattern(trimmed)) {
      return 'Address contains invalid characters';
    }
    
    return null;
  }

  /// Validates latitude
  static String? validateLatitude(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Latitude is required';
    }
    
    final lat = double.tryParse(value.trim());
    if (lat == null) {
      return 'Invalid latitude';
    }
    
    if (lat < -90 || lat > 90) {
      return 'Latitude must be between -90 and 90';
    }
    
    return null;
  }

  /// Validates longitude
  static String? validateLongitude(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Longitude is required';
    }
    
    final lng = double.tryParse(value.trim());
    if (lng == null) {
      return 'Invalid longitude';
    }
    
    if (lng < -180 || lng > 180) {
      return 'Longitude must be between -180 and 180';
    }
    
    return null;
  }

  // ============================================================================
  // SERVICE & BOOKING
  // ============================================================================

  /// Validates service description
  static String? validateDescription(String? value, {int maxLength = 1000}) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    
    final trimmed = value.trim();
    
    if (trimmed.length < 10) {
      return 'Description must be at least 10 characters';
    }
    
    if (trimmed.length > maxLength) {
      return 'Description is too long (max $maxLength characters)';
    }
    
    if (_containsInjectionPattern(trimmed)) {
      return 'Description contains invalid characters';
    }
    
    return null;
  }

  /// Validates feedback message
  static String? validateFeedback(String? value, {int minLength = 10, int maxLength = 2000}) {
    if (value == null || value.trim().isEmpty) {
      return 'Feedback is required';
    }
    
    final trimmed = value.trim();
    
    if (trimmed.length < minLength) {
      return 'Feedback must be at least $minLength characters';
    }
    
    if (trimmed.length > maxLength) {
      return 'Feedback is too long (max $maxLength characters)';
    }
    
    if (_containsInjectionPattern(trimmed)) {
      return 'Feedback contains invalid characters';
    }
    
    return null;
  }

  /// Validates OTP code
  static String? validateOTP(String? value, {int length = 6}) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }
    
    final trimmed = value.trim();
    
    if (trimmed.length != length) {
      return 'OTP must be $length digits';
    }
    
    if (!RegExp(r'^[0-9]+$').hasMatch(trimmed)) {
      return 'OTP must contain only digits';
    }
    
    return null;
  }

  /// Validates payment amount
  static String? validateAmount(String? value, {double maxAmount = 100000}) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    
    final amount = double.tryParse(value.trim());
    if (amount == null) {
      return 'Invalid amount';
    }
    
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    
    if (amount > maxAmount) {
      return 'Amount exceeds maximum (LKR $maxAmount)';
    }
    
    // Check for too many decimal places
    final decimalParts = value.trim().split('.');
    if (decimalParts.length > 1 && decimalParts[1].length > 2) {
      return 'Amount can have at most 2 decimal places';
    }
    
    return null;
  }

  // ============================================================================
  // PASSWORD & SECURITY
  // ============================================================================

  /// Validates password strength
  static String? validatePassword(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    
    if (value.length > 128) {
      return 'Password is too long';
    }
    
    // Check for at least one uppercase
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    // Check for at least one lowercase
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    
    // Check for at least one digit
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    // Check for at least one special character
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    
    return null;
  }

  /// Validates password confirmation
  static String? validatePasswordConfirmation(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  // ============================================================================
  // SANITIZATION
  // ============================================================================

  /// Sanitizes text input to prevent XSS and injection attacks
  static String sanitizeText(String input) {
    return input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;')
        .trim();
  }

  /// Removes potentially dangerous characters
  static String sanitizeForDisplay(String input) {
    // Remove control characters except newlines and tabs
    return input
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '')
        .trim();
  }

  // ============================================================================
  // PRIVATE HELPERS
  // ============================================================================

  /// Checks for common injection patterns
  static bool _containsInjectionPattern(String input) {
    final injectionPatterns = [
      r'<script',          // XSS
      r'javascript:',      // XSS
      r'on\w+\s*=',        // Event handlers
      r'SELECT\s+',        // SQL injection
      r'INSERT\s+',        // SQL injection
      r'UPDATE\s+',        // SQL injection
      r'DELETE\s+',        // SQL injection
      r'DROP\s+',          // SQL injection
      r'UNION\s+',         // SQL injection
      r'--',               // SQL comment
      r'/\*',              // SQL comment
      r'\*/',              // SQL comment
      r'\.\./',            // Path traversal
      r'\.\.\\',           // Path traversal
    ];
    
    final lowerInput = input.toLowerCase();
    for (final pattern in injectionPatterns) {
      if (RegExp(pattern).hasMatch(lowerInput)) {
        return true;
      }
    }
    return false;
  }
}

/// Validation result wrapper
class ValidationResult {
  final bool isValid;
  final String? error;
  final String? sanitizedValue;

  const ValidationResult._({
    required this.isValid,
    this.error,
    this.sanitizedValue,
  });

  factory ValidationResult.valid(String? sanitizedValue) {
    return ValidationResult._(
      isValid: true,
      sanitizedValue: sanitizedValue,
    );
  }

  factory ValidationResult.invalid(String error) {
    return ValidationResult._(
      isValid: false,
      error: error,
    );
  }

  bool get hasError => error != null;
}

/// Extension for easy validation on String
extension StringValidation on String? {
  /// Validates as NIC
  String? get asNIC => InputValidators.validateNIC(this);

  /// Validates as phone
  String? get asPhone => InputValidators.validatePhone(this);

  /// Validates as email
  String? asEmail({bool required = false}) => 
      InputValidators.validateEmail(this, required: required);

  /// Validates as name
  String? asName({int minLength = 2}) => 
      InputValidators.validateName(this, minLength: minLength);

  /// Sanitizes the string
  String? get sanitized => this != null ? InputValidators.sanitizeText(this!) : null;
}
