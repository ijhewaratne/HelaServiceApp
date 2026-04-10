import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/core/utils/nic_validator.dart';

void main() {
  group('NICValidator', () {
    group('isValid', () {
      test('validates old format NIC correctly', () {
        expect(NICValidator.isValid('853202937V'), true);
        expect(NICValidator.isValid('002202937V'), true);
        expect(NICValidator.isValid('992202937X'), true);
      });

      test('validates new format NIC correctly', () {
        expect(NICValidator.isValid('198532029372'), true);
        expect(NICValidator.isValid('200012029372'), true);
        expect(NICValidator.isValid('199901015678'), true);
      });

      test('rejects invalid NIC formats', () {
        expect(NICValidator.isValid('123456789'), false); // Too short
        expect(NICValidator.isValid('12345678901V'), false); // 11 chars
        expect(NICValidator.isValid('invalid'), false);
        expect(NICValidator.isValid(''), false);
        expect(NICValidator.isValid('853202937A'), false); // Invalid check digit
      });

      test('handles whitespace correctly', () {
        expect(NICValidator.isValid(' 853202937V '), true);
        expect(NICValidator.isValid('85 3202 937V'), true);
      });

      test('handles case insensitivity', () {
        expect(NICValidator.isValid('853202937v'), true);
        expect(NICValidator.isValid('853202937V'), true);
      });
    });

    group('getBirthYear', () {
      test('extracts birth year from old format (1900s)', () {
        expect(NICValidator.getBirthYear('853202937V'), 1985);
        expect(NICValidator.getBirthYear('992202937X'), 1999);
      });

      test('extracts birth year from old format (2000s)', () {
        expect(NICValidator.getBirthYear('002202937V'), 2000);
        expect(NICValidator.getBirthYear('052202937X'), 2005);
      });

      test('extracts birth year from new format', () {
        expect(NICValidator.getBirthYear('198532029372'), 1985);
        expect(NICValidator.getBirthYear('200001015678'), 2000);
      });

      test('returns null for invalid NIC', () {
        expect(NICValidator.getBirthYear('invalid'), null);
        expect(NICValidator.getBirthYear(''), null);
      });
    });

    group('isAdult', () {
      test('returns true for person 18+ years old', () {
        // Born in 1985 = 39+ years old (as of 2024)
        expect(NICValidator.isAdult('853202937V'), true);
        expect(NICValidator.isAdult('198532029372'), true);
      });

      test('returns false for minors', () {
        // Born in 2020 = 4 years old
        expect(NICValidator.isAdult('202002937V'), false);
        expect(NICValidator.isAdult('202001015678'), false);
      });

      test('returns false for invalid NIC', () {
        expect(NICValidator.isAdult('invalid'), false);
        expect(NICValidator.isAdult(''), false);
      });
    });

    group('validate', () {
      test('returns null for valid adult NIC', () {
        expect(NICValidator.validate('853202937V'), null);
      });

      test('returns error for empty value', () {
        expect(NICValidator.validate(null), 'NIC is required');
        expect(NICValidator.validate(''), 'NIC is required');
      });

      test('returns error for invalid format', () {
        expect(
          NICValidator.validate('123456789'),
          'Enter valid Sri Lankan NIC (e.g., 853202937V or 198532029372)',
        );
      });

      test('returns error for minor', () {
        expect(NICValidator.validate('202002937V'), 'Must be 18 or older');
      });
    });
  });
}
