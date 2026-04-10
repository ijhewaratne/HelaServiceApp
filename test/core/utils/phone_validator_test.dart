import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/core/utils/phone_validator.dart';

void main() {
  group('PhoneValidator', () {
    group('isValid', () {
      test('validates Sri Lankan mobile numbers', () {
        expect(PhoneValidator.isValid('+94771234567'), true);
        expect(PhoneValidator.isValid('0771234567'), true);
        expect(PhoneValidator.isValid('0711234567'), true);
        expect(PhoneValidator.isValid('0761234567'), true);
        expect(PhoneValidator.isValid('0751234567'), true);
        expect(PhoneValidator.isValid('0781234567'), true);
      });

      test('rejects invalid phone numbers', () {
        expect(PhoneValidator.isValid('123456789'), false); // Wrong prefix
        expect(PhoneValidator.isValid('077123456'), false); // Too short
        expect(PhoneValidator.isValid('07712345678'), false); // Too long
        expect(PhoneValidator.isValid(''), false);
        expect(PhoneValidator.isValid('invalid'), false);
      });
    });

    group('normalize', () {
      test('converts to international format', () {
        expect(PhoneValidator.normalize('0771234567'), '+94771234567');
        expect(PhoneValidator.normalize('+94771234567'), '+94771234567');
      });

      test('handles whitespace', () {
        expect(PhoneValidator.normalize(' 077 123 4567 '), '+94771234567');
      });
    });

    group('formatDisplay', () {
      test('formats for display', () {
        expect(PhoneValidator.formatDisplay('+94771234567'), '077 123 4567');
        expect(PhoneValidator.formatDisplay('0771234567'), '077 123 4567');
      });
    });
  });
}
