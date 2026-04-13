import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/core/security/encryption_service.dart';

/// Tests for EncryptionService
/// 
/// Phase 4: Testing Infrastructure
void main() {
  late EncryptionService encryptionService;
  
  const testKey = 'my-32-character-encryption-key!!';
  const testData = '853202937V'; // Test NIC
  
  setUp(() {
    encryptionService = EncryptionService(testKey);
  });
  
  group('Constructor', () {
    test('should create with valid 32-character key', () {
      expect(() => EncryptionService(testKey), returnsNormally);
    });
    
    test('should throw error with key shorter than 32 characters', () {
      expect(
        () => EncryptionService('short-key'),
        throwsArgumentError,
      );
    });
    
    test('should use first 32 characters of longer key', () {
      final longKey = testKey + 'extra-characters';
      expect(() => EncryptionService(longKey), returnsNormally);
    });
  });
  
  group('Encrypt/Decrypt', () {
    test('should encrypt and decrypt data correctly', () {
      // Arrange & Act
      final encrypted = encryptionService.encryptData(testData);
      final decrypted = encryptionService.decryptData(encrypted);
      
      // Assert
      expect(decrypted, equals(testData));
      expect(encrypted, isNot(equals(testData))); // Should be different
    });
    
    test('should produce different ciphertext for same plaintext', () {
      // Arrange & Act
      final encrypted1 = encryptionService.encryptData(testData);
      final encrypted2 = encryptionService.encryptData(testData);
      
      // Assert - Due to different IVs, ciphertexts should be different
      expect(encrypted1, isNot(equals(encrypted2)));
      
      // But both should decrypt to the same plaintext
      expect(encryptionService.decryptData(encrypted1), equals(testData));
      expect(encryptionService.decryptData(encrypted2), equals(testData));
    });
    
    test('should handle empty string', () {
      // Arrange & Act
      final encrypted = encryptionService.encryptData('');
      final decrypted = encryptionService.decryptData(encrypted);
      
      // Assert
      expect(decrypted, equals(''));
    });
    
    test('should throw exception for invalid encrypted data', () {
      // Arrange
      const invalidData = 'not-valid-base64!!!';
      
      // Act & Assert
      expect(
        () => encryptionService.decryptData(invalidData),
        throwsA(isA<EncryptionException>()),
      );
    });
  });
  
  group('Hash Data', () {
    test('should produce consistent hash for same data', () {
      // Arrange & Act
      final hash1 = encryptionService.hashData(testData);
      final hash2 = encryptionService.hashData(testData);
      
      // Assert
      expect(hash1, equals(hash2));
    });
    
    test('should produce different hash for different data', () {
      // Arrange & Act
      final hash1 = encryptionService.hashData('data1');
      final hash2 = encryptionService.hashData('data2');
      
      // Assert
      expect(hash1, isNot(equals(hash2)));
    });
    
    test('should verify hash correctly', () {
      // Arrange
      final hash = encryptionService.hashData(testData);
      
      // Act & Assert
      expect(encryptionService.verifyHash(testData, hash), isTrue);
      expect(encryptionService.verifyHash('wrong-data', hash), isFalse);
    });
  });
  
  group('Mask Data', () {
    test('should mask middle characters', () {
      // Arrange & Act
      final masked = encryptionService.maskData(testData);
      
      // Assert - '853202937V' (10 chars) with 2 visible each side
      // = '85' + '******' + '7V' = '85******7V'
      expect(masked, equals('85******7V'));
      expect(masked.length, equals(testData.length));
    });
    
    test('should handle short strings', () {
      // Arrange & Act
      final masked = encryptionService.maskData('1234');
      
      // Assert - Should return as-is if too short
      expect(masked, equals('1234'));
    });
    
    test('should use custom visible character count', () {
      // Arrange & Act
      final masked = encryptionService.maskData(testData, visibleChars: 3);
      
      // Assert - with 3 visible chars: 3 at start + 3 at end = 6 visible
      // '853202937V' has 10 chars, so 4 masked in middle
      // Result: '853' + '****' + '37V' = '853****37V'
      expect(masked, equals('853****37V'));
    });
  });
  
  group('Is Encrypted', () {
    test('should return true for encrypted data', () {
      // Arrange
      final encrypted = encryptionService.encryptData(testData);
      
      // Act & Assert
      expect(encryptionService.isEncrypted(encrypted), isTrue);
    });
    
    test('should return false for plain text', () {
      // Act & Assert
      expect(encryptionService.isEncrypted(testData), isFalse);
      expect(encryptionService.isEncrypted('plain text'), isFalse);
    });
    
    test('should return false for empty string', () {
      // Act & Assert
      expect(encryptionService.isEncrypted(''), isFalse);
    });
    
    test('should return false for invalid base64', () {
      // Act & Assert
      expect(encryptionService.isEncrypted('not-base64!!!'), isFalse);
    });
  });
  
  group('Encryptable Mixin', () {
    test('should encrypt and decrypt fields', () {
      // Arrange
      final testObject = _TestEncryptable();
      
      // Act
      final encrypted = testObject.encryptField(testData, encryptionService);
      final decrypted = testObject.decryptField(encrypted, encryptionService);
      
      // Assert
      expect(decrypted, equals(testData));
    });
    
    test('should handle null values', () {
      // Arrange
      final testObject = _TestEncryptable();
      
      // Act
      final encrypted = testObject.encryptField(null, encryptionService);
      final decrypted = testObject.decryptField(null, encryptionService);
      
      // Assert
      expect(encrypted, isNull);
      expect(decrypted, isNull);
    });
  });
  
  group('Cross-instance compatibility', () {
    test('same key should decrypt data from different instance', () {
      // Arrange
      final service1 = EncryptionService(testKey);
      final service2 = EncryptionService(testKey);
      final encrypted = service1.encryptData(testData);
      
      // Act
      final decrypted = service2.decryptData(encrypted);
      
      // Assert
      expect(decrypted, equals(testData));
    });
    
    test('different key should fail to decrypt', () {
      // Arrange
      final service1 = EncryptionService(testKey);
      final service2 = EncryptionService('different-32-character-key-here!');
      final encrypted = service1.encryptData(testData);
      
      // Act & Assert
      expect(
        () => service2.decryptData(encrypted),
        throwsA(isA<EncryptionException>()),
      );
    });
  });
}

/// Test class for EncryptableMixin
class _TestEncryptable with EncryptableMixin {}
