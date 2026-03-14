class PhoneValidator {
  /// Validates Sri Lankan mobile numbers
  static bool isValid(String phone) {
    final clean = phone.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');
    
    // Format: 07XXXXXXXX (10 digits starting with 07)
    final mobileRegex = RegExp(r'^07[0-9]{8}$');
    
    return mobileRegex.hasMatch(clean);
  }

  static String format(String phone) {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 10 && clean.startsWith('07')) {
      return '${clean.substring(0, 3)} ${clean.substring(3, 6)} ${clean.substring(6)}';
    }
    return phone;
  }

  static String? validate(String? value) {
    if (value == null || value.isEmpty) return 'Phone number required';
    if (!isValid(value)) return 'Enter valid SL mobile (07XXXXXXXX)';
    return null;
  }
}