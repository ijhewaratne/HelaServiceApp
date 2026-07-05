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
    final digits = nic.substring(0, 9);
    if (!RegExp(r'^[0-9]+$').hasMatch(digits)) return false;

    final dayOfYear = int.tryParse(nic.substring(2, 5));
    return _isValidDayOfYear(dayOfYear);
  }

  static bool _validateNewNIC(String nic) {
    // New format: YYYY + day-of-year/sex code + serial digits
    final year = int.tryParse(nic.substring(0, 4)) ?? 0;
    final dayOfYear = int.tryParse(nic.substring(4, 7));

    if (year < 1900 || year > DateTime.now().year) return false;
    return _isValidDayOfYear(dayOfYear);
  }

  static bool _isValidDayOfYear(int? dayOfYear) {
    if (dayOfYear == null) return false;
    if (dayOfYear >= 1 && dayOfYear <= 366) return true;
    if (dayOfYear >= 501 && dayOfYear <= 866) return true;
    return false;
  }

  /// Extract birth year from NIC
  static int? getBirthYear(String nic) {
    final clean = nic.trim().replaceAll(' ', '').toUpperCase();
    if (!isValid(clean)) return null;
    
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
