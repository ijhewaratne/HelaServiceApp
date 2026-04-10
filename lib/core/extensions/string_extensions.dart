/// String extensions for common operations
extension StringExtensions on String {
  /// Check if string is a valid Sri Lankan phone number
  bool get isValidSriLankanPhone {
    final clean = replaceAll(RegExp(r'\s+'), '');
    final regex = RegExp(r'^(?:\+94|0)?7[0-9]{8}$');
    return regex.hasMatch(clean);
  }
  
  /// Format Sri Lankan phone number to standard format (+9477XXXXXXX)
  String get formatSriLankanPhone {
    final clean = replaceAll(RegExp(r'\s+'), '').replaceAll('+94', '');
    if (clean.startsWith('0')) {
      return '+94${clean.substring(1)}';
    }
    return '+94$clean';
  }
  
  /// Mask phone number for privacy (e.g., +9477XXXX123)
  String get maskPhoneNumber {
    if (length < 4) return this;
    final visibleStart = substring(0, length - 4);
    final visibleEnd = substring(length - 3);
    return '${visibleStart}XXX$visibleEnd';
  }
  
  /// Check if string is a valid NIC (old or new format)
  bool get isValidNIC {
    final clean = trim().replaceAll(' ', '').toUpperCase();
    // Old format: 9 digits + V/X
    final oldFormat = RegExp(r'^[0-9]{9}[VX]$');
    // New format: 12 digits
    final newFormat = RegExp(r'^[0-9]{12}$');
    return oldFormat.hasMatch(clean) || newFormat.hasMatch(clean);
  }
  
  /// Capitalize first letter of string
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
  
  /// Capitalize first letter of each word
  String get capitalizeWords {
    return split(' ').map((word) => word.capitalize).join(' ');
  }
  
  /// Truncate string with ellipsis
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }
  
  /// Remove all whitespace
  String get removeWhitespace {
    return replaceAll(RegExp(r'\s+'), '');
  }
  
  /// Check if string is null or empty
  bool get isNullOrEmpty => trim().isEmpty;
  
  /// Check if string is not null and not empty
  bool get isNotNullOrEmpty => trim().isNotEmpty;
  
  /// Parse to int safely
  int? get toIntOrNull => int.tryParse(this);
  
  /// Parse to double safely
  double? get toDoubleOrNull => double.tryParse(this);
  
  /// Check if string is a valid email
  bool get isValidEmail {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(this);
  }
  
  /// Mask email for privacy (e.g., i***@example.com)
  String get maskEmail {
    if (!contains('@')) return this;
    final parts = split('@');
    if (parts[0].length <= 2) return this;
    final masked = '${parts[0][0]}${'*' * (parts[0].length - 2)}${parts[0][parts[0].length - 1]}';
    return '$masked@${parts[1]}';
  }
}
