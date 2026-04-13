import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Encryption Service for PDPA Compliance
/// 
/// Encrypts sensitive data (NIC, addresses, phone numbers) before storage.
/// Uses AES-256 encryption with CBC mode.
/// 
/// Phase 1: Critical Security & Stability
class EncryptionService {
  late final encrypt.Encrypter _encrypter;
  late final String _encryptionKey;
  
  /// Initialize with a 32-character encryption key
  /// 
  /// For production, this should come from:
  /// - Environment variables (local dev)
  /// - Google Cloud KMS (production)
  /// - Firebase Remote Config (with encryption)
  EncryptionService(String encryptionKey) {
    if (encryptionKey.length < 32) {
      throw ArgumentError('Encryption key must be at least 32 characters');
    }
    
    _encryptionKey = encryptionKey.substring(0, 32);
    final key = encrypt.Key.fromUtf8(_encryptionKey);
    _encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc),
    );
  }
  
  /// Encrypt plaintext data
  /// 
  /// Returns base64 encoded encrypted string with IV prepended
  String encryptData(String plainText) {
    if (plainText.isEmpty) return plainText;
    
    try {
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypted = _encrypter.encrypt(plainText, iv: iv);
      
      // Prepend IV to encrypted data for decryption
      final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
      combined.setAll(0, iv.bytes);
      combined.setAll(iv.bytes.length, encrypted.bytes);
      
      return base64Encode(combined);
    } catch (e) {
      throw EncryptionException('Failed to encrypt data: $e');
    }
  }
  
  /// Decrypt encrypted data
  /// 
  /// Expects base64 encoded string with IV prepended
  String decryptData(String encryptedText) {
    if (encryptedText.isEmpty) return encryptedText;
    
    try {
      final combined = base64Decode(encryptedText);
      
      // Extract IV (first 16 bytes)
      final iv = encrypt.IV(Uint8List.fromList(combined.sublist(0, 16)));
      
      // Extract encrypted data (remaining bytes)
      final encryptedBytes = combined.sublist(16);
      final encrypted = encrypt.Encrypted(encryptedBytes);
      
      return _encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw EncryptionException('Failed to decrypt data: $e');
    }
  }
  
  /// Hash sensitive data for comparison (one-way)
  /// 
  /// Use this for data that needs to be compared but not decrypted
  /// e.g., NIC verification without storing plaintext
  String hashData(String data, {String? salt}) {
    final bytes = utf8.encode(data + (salt ?? _encryptionKey));
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Verify data against hash
  bool verifyHash(String data, String hash, {String? salt}) {
    return hashData(data, salt: salt) == hash;
  }
  
  /// Mask sensitive data for display
  /// 
  /// e.g., "853202937V" -> "85****37V"
  String maskData(String data, {int visibleChars = 2}) {
    if (data.length <= visibleChars * 2) return data;
    
    final start = data.substring(0, visibleChars);
    final end = data.substring(data.length - visibleChars);
    final maskedLength = data.length - (visibleChars * 2);
    
    return '$start${'*' * maskedLength}$end';
  }
  
  /// Check if data is encrypted (heuristic)
  /// 
  /// Returns true if data appears to be base64 encoded
  /// and has the expected structure
  bool isEncrypted(String data) {
    if (data.isEmpty) return false;
    
    try {
      final decoded = base64Decode(data);
      // Encrypted data should be at least 16 bytes (IV) + some encrypted content
      return decoded.length > 16;
    } catch (e) {
      return false;
    }
  }
}

/// Exception for encryption errors
class EncryptionException implements Exception {
  final String message;
  
  EncryptionException(this.message);
  
  @override
  String toString() => 'EncryptionException: $message';
}

/// Mixin for entities that need encryption
/// 
/// Usage:
/// ```dart
/// class WorkerProfile with EncryptableMixin {
///   final String nic;
///   
///   Map<String, dynamic> toEncryptedJson(EncryptionService encryption) {
///     return {
///       'nic_encrypted': encryptField(nic, encryption),
///     };
///   }
/// }
/// ```
mixin EncryptableMixin {
  String? encryptField(String? value, EncryptionService encryption) {
    if (value == null || value.isEmpty) return value;
    return encryption.encryptData(value);
  }
  
  String? decryptField(String? encryptedValue, EncryptionService encryption) {
    if (encryptedValue == null || encryptedValue.isEmpty) return encryptedValue;
    return encryption.decryptData(encryptedValue);
  }
}
