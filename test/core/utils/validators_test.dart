import 'package:flutter_test/flutter_test.dart';

/// Validators tests - centralized validation logic tests
void main() {
  group('EmailValidator', () {
    test('validates correct email addresses', () {
      final validEmails = [
        'test@example.com',
        'user.name@domain.co.uk',
        'user+tag@example.com',
        'firstname.lastname@company.com',
      ];
      
      for (final email in validEmails) {
        expect(EmailValidator.isValid(email), isTrue, reason: '$email should be valid');
      }
    });

    test('rejects invalid email addresses', () {
      final invalidEmails = [
        '',
        'invalid',
        '@example.com',
        'test@',
        'test@.com',
        'test..test@example.com',
        'test@example..com',
      ];
      
      for (final email in invalidEmails) {
        expect(EmailValidator.isValid(email), isFalse, reason: '$email should be invalid');
      }
    });
  });

  group('PasswordValidator', () {
    test('validates strong passwords', () {
      final validPasswords = [
        'Password123!',
        'Secure@Pass1',
        'MyStr0ng#Pwd',
        'C0mpl3x!Pass',
      ];
      
      for (final password in validPasswords) {
        expect(PasswordValidator.isValid(password), isTrue, reason: '$password should be valid');
      }
    });

    test('rejects weak passwords', () {
      final invalidPasswords = [
        '',
        'short',
        'password',
        'PASSWORD',
        '12345678',
        'Password', // no number
        'password123', // no uppercase
        'PASSWORD123', // no lowercase
      ];
      
      for (final password in invalidPasswords) {
        expect(PasswordValidator.isValid(password), isFalse, reason: '$password should be invalid');
      }
    });

    test('enforces minimum length of 8 characters', () {
      expect(PasswordValidator.isValid('Pass1!'), isFalse); // 6 chars
      expect(PasswordValidator.isValid('Pass12!'), isFalse); // 7 chars
      expect(PasswordValidator.isValid('Pass123!'), isTrue); // 8 chars
    });

    test('getStrength returns correct strength level', () {
      expect(PasswordValidator.getStrength(''), equals(PasswordStrength.weak));
      expect(PasswordValidator.getStrength('password'), equals(PasswordStrength.weak));
      expect(PasswordValidator.getStrength('Password1'), equals(PasswordStrength.medium));
      expect(PasswordValidator.getStrength('Password1!'), equals(PasswordStrength.strong));
    });
  });

  group('NameValidator', () {
    test('validates proper names', () {
      final validNames = [
        'John',
        'Mary Jane',
        'Jean-Luc',
        'O\'Connor',
        'Sri Lankan Name',
        'කමල්', // Sinhala name
      ];
      
      for (final name in validNames) {
        expect(NameValidator.isValid(name), isTrue, reason: '$name should be valid');
      }
    });

    test('rejects invalid names', () {
      final invalidNames = [
        '',
        '   ',
        '123',
        '@John',
        'John123',
        'J',
      ];
      
      for (final name in invalidNames) {
        expect(NameValidator.isValid(name), isFalse, reason: '$name should be invalid');
      }
    });

    test('enforces minimum length of 2 characters', () {
      expect(NameValidator.isValid('A'), isFalse);
      expect(NameValidator.isValid('AB'), isTrue);
    });

    test('enforces maximum length of 50 characters', () {
      expect(NameValidator.isValid('A' * 51), isFalse);
      expect(NameValidator.isValid('A' * 50), isTrue);
    });
  });

  group('AddressValidator', () {
    test('validates proper addresses', () {
      final validAddresses = [
        '123 Main Street',
        '45/A, Galle Road, Colombo 03',
        'Flat 5, Tower A, Apartment Complex',
        'No. 67, Jayanthipura, Battaramulla',
      ];
      
      for (final address in validAddresses) {
        expect(AddressValidator.isValid(address), isTrue, reason: '$address should be valid');
      }
    });

    test('rejects invalid addresses', () {
      final invalidAddresses = [
        '',
        '   ',
        'A',
      ];
      
      for (final address in invalidAddresses) {
        expect(AddressValidator.isValid(address), isFalse, reason: '$address should be invalid');
      }
    });

    test('enforces minimum length of 5 characters', () {
      expect(AddressValidator.isValid('1234'), isFalse);
      expect(AddressValidator.isValid('12345'), isTrue);
    });
  });

  group('AmountValidator', () {
    test('validates positive amounts', () {
      expect(AmountValidator.isValid('100'), isTrue);
      expect(AmountValidator.isValid('100.50'), isTrue);
      expect(AmountValidator.isValid('0.01'), isTrue);
    });

    test('rejects invalid amounts', () {
      expect(AmountValidator.isValid(''), isFalse);
      expect(AmountValidator.isValid('0'), isFalse);
      expect(AmountValidator.isValid('-100'), isFalse);
      expect(AmountValidator.isValid('abc'), isFalse);
      expect(AmountValidator.isValid('100.123'), isFalse); // 3 decimal places
    });

    test('validates maximum amount', () {
      expect(AmountValidator.isValid('999999.99', maxAmount: 1000000), isTrue);
      expect(AmountValidator.isValid('1000000', maxAmount: 1000000), isFalse);
    });
  });

  group('RequiredValidator', () {
    test('validates non-empty values', () {
      expect(RequiredValidator.isValid('test'), isTrue);
      expect(RequiredValidator.isValid(' '), isTrue);
      expect(RequiredValidator.isValid('0'), isTrue);
    });

    test('rejects null and empty values', () {
      expect(RequiredValidator.isValid(null), isFalse);
      expect(RequiredValidator.isValid(''), isFalse);
    });
  });
}

// Validator implementations for testing
class EmailValidator {
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  
  static bool isValid(String? email) {
    if (email == null || email.isEmpty) return false;
    return _emailRegex.hasMatch(email);
  }
}

class PasswordValidator {
  static bool isValid(String? password) {
    if (password == null || password.length < 8) return false;
    
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    return hasUppercase && hasLowercase && hasDigits && hasSpecialChars;
  }
  
  static PasswordStrength getStrength(String password) {
    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    
    if (score <= 2) return PasswordStrength.weak;
    if (score <= 3) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }
}

enum PasswordStrength { weak, medium, strong }

class NameValidator {
  static bool isValid(String? name) {
    if (name == null || name.trim().isEmpty) return false;
    if (name.length < 2 || name.length > 50) return false;
    // Allow letters, spaces, hyphens, apostrophes, and Unicode characters
    final validNameRegex = RegExp(r"^[\p{L}\s\-'']+$", unicode: true);
    return validNameRegex.hasMatch(name);
  }
}

class AddressValidator {
  static bool isValid(String? address) {
    if (address == null || address.trim().isEmpty) return false;
    if (address.trim().length < 5) return false;
    return true;
  }
}

class AmountValidator {
  static bool isValid(String? amount, {double maxAmount = 1000000}) {
    if (amount == null || amount.isEmpty) return false;
    
    final value = double.tryParse(amount);
    if (value == null) return false;
    if (value <= 0) return false;
    if (value >= maxAmount) return false;
    
    // Check for maximum 2 decimal places
    final decimalIndex = amount.indexOf('.');
    if (decimalIndex != -1 && amount.length - decimalIndex - 1 > 2) {
      return false;
    }
    
    return true;
  }
}

class RequiredValidator {
  static bool isValid(dynamic value) {
    if (value == null) return false;
    if (value is String && value.isEmpty) return false;
    return true;
  }
}
