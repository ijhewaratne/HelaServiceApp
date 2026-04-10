class PhoneValidator {
  /// Validates Sri Lankan mobile numbers
  /// Accepts both formats: 07XXXXXXXX and +947XXXXXXXX
  static bool isValid(String phone) {
    final clean = phone.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');
    
    // Format: 07XXXXXXXX (10 digits starting with 07)
    final mobileRegex = RegExp(r'^07[0-9]{8}$');
    // Format: +947XXXXXXXX (11 digits with +94)
    final internationalRegex = RegExp(r'^\+94[0-9]{9}$');
    
    return mobileRegex.hasMatch(clean) || internationalRegex.hasMatch(clean);
  }

  /// Converts to international format (+94...)
  static String normalize(String phone) {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    
    if (clean.length == 10 && clean.startsWith('07')) {
      return '+94${clean.substring(1)}';
    }
    if (clean.length == 11 && clean.startsWith('94')) {
      return '+$clean';
    }
    if (phone.startsWith('+')) {
      return phone;
    }
    return phone;
  }

  /// Format for display: 077 123 4567
  static String formatDisplay(String phone) {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    
    // Handle international format
    String local = clean;
    if (clean.length == 11 && clean.startsWith('94')) {
      local = '0${clean.substring(2)}';
    }
    
    if (local.length == 10 && local.startsWith('07')) {
      return '${local.substring(0, 3)} ${local.substring(3, 6)} ${local.substring(6)}';
    }
    return phone;
  }

  static String? validate(String? value) {
    if (value == null || value.isEmpty) return 'Phone number required';
    if (!isValid(value)) return 'Enter valid SL mobile (07XXXXXXXX)';
    return null;
  }
}