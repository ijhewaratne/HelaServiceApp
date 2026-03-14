class NICValidator {
  /// Validates Sri Lankan NIC (both old and new formats)
  static bool isValid(String nic) {
    if (nic.isEmpty) return false;
    
    // Remove spaces and convert to uppercase
    final clean = nic.trim().replaceAll(' ', '').toUpperCase();
    
    // Old format: 9 digits + V/X (10 chars)
    // Example: 853202937V
    final oldFormat = RegExp(r'^[0-9]{9}[VX]$');
    
    // New format: 12 digits (12 chars)
    // Example: 198532029372
    final newFormat = RegExp(r'^[0-9]{12}$');
    
    if (oldFormat.hasMatch(clean)) {
      return _validateOldNIC(clean);
    } else if (newFormat.hasMatch(clean)) {
      return _validateNewNIC(clean);
    }
    
    return false;
  }

  static bool _validateOldNIC(String nic) {
    // Extract digits
    final digits = nic.substring(0, 9);
    final checkDigit = nic[9];
    
    // Check if first 9 are digits
    if (!RegExp(r'^[0-9]+$').hasMatch(digits)) return false;
    
    // Validate check digit (V for odd, X for even based on calculation)
    // This is a simplified check - real validation would involve MOD 11 check
    final checkVal = int.tryParse(digits[8]) ?? 0;
    if (checkDigit == 'V' && checkVal % 2 == 0) return false;
    if (checkDigit == 'X' && checkVal % 2 != 0) return false;
    
    return true;
  }

  static bool _validateNewNIC(String nic) {
    // New format: YYYYMMDDNNNN
    // First 4: Year (1900-2024)
    // Next 2: Month (01-12)
    // Next 2: Day (01-31)
    // Last 4: Serial
    
    final year = int.tryParse(nic.substring(0, 4)) ?? 0;
    final month = int.tryParse(nic.substring(4, 6)) ?? 0;
    final day = int.tryParse(nic.substring(6, 8)) ?? 0;
    
    if (year < 1900 || year > DateTime.now().year) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    
    return true;
  }

  /// Extract birth year from NIC
  static int? getBirthYear(String nic) {
    final clean = nic.trim().replaceAll(' ', '').toUpperCase();
    
    if (clean.length == 10) {
      // Old format: 853202937V -> 1985
      final yearDigits = int.tryParse(clean.substring(0, 2)) ?? 0;
      return yearDigits > 50 ? 1900 + yearDigits : 2000 + yearDigits;
    } else if (clean.length == 12) {
      // New format: 198532029372 -> 1985
      return int.tryParse(clean.substring(0, 4));
    }
    return null;
  }

  /// Check if person is 18+ based on NIC
  static bool isAdult(String nic) {
    final year = getBirthYear(nic);
    if (year == null) return false;
    return DateTime.now().year - year >= 18;
  }

  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'NIC is required';
    }
    if (!isValid(value)) {
      return 'Enter valid Sri Lankan NIC (e.g., 853202937V or 198532029372)';
    }
    if (!isAdult(value)) {
      return 'Must be 18 or older';
    }
    return null;
  }
}