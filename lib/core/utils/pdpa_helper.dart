import 'dart:convert';
import 'package:crypto/crypto.dart';

class PDPAManager {
  // 1. Strict Medical Data Blocking
  // Under Sri Lankan PDPA, medical/health records are Special Category Data.
  // Our system currently operates as a home service MVP, not a medical EHR.
  static bool canStoreMedicalData(String serviceType) {
    if (serviceType == 'elder_care' || serviceType == 'medical_assistance') {
      return false; // MVP v1 strictly forbids raw medical data ingestion into Cloud Firestore.
    }
    return false; // Default off across all services
  }

  // 2. Pseudonymization Utility
  // For protecting vulnerable parties (e.g. babysitting subjects)
  static String pseudonymizeChildName(String name) {
    var bytes = utf8.encode(name);
    var digest = md5.convert(bytes); // For display masking only.
    return "Child_${digest.toString().substring(0, 8)}";
  }

  // 3. Sensitive Data Encryption Stub (Transit)
  // Ensures NICs and precise addresses are theoretically obfuscated before leaving the device.
  // In production, implement a robust Key Management Service (KMS) or symmetric AES-256 process here
  static Map<String, dynamic> encryptSensitiveData(String nic, String address) {
    // NOTE: For MVP purposes, this simply returns a payload map.
    // The actual AES-Key derivation via 'encrypt' package should live here in Prod.
    return {
      'encrypted_nic': 'ENCRYPTED_STUB_$nic',
      'encrypted_address': 'ENCRYPTED_STUB_$address',
      'encryption_version': 'v1_aes_stub',
    };
  }

  // Decryption Stub
  static String decryptSensitiveData(String encryptedString) {
    return encryptedString.replaceFirst('ENCRYPTED_STUB_', '');
  }
}
