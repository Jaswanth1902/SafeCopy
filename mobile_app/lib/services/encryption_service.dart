// ========================================
// ENCRYPTION SERVICE - MOBILE APP
// Handles AES-256-GCM encryption
// ========================================

import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';
import 'package:encrypt/encrypt.dart' as enc;

class EncryptionService {
  // ========================================
  // GENERATE AES-256 KEY
  // ========================================

  Uint8List generateAES256Key() {
    // Generate 32 random bytes for AES-256
    final random = SecureRandom('Fortuna');
    final keyGenerator = KeyGenerator('AES');
    keyGenerator.init(KeyGeneratorParameters(256));
    final key = keyGenerator.generateKey();
    return Uint8List.fromList(key.bytes);
  }

  // ========================================
  // ENCRYPT FILE - AES-256-GCM
  // ========================================

  Future<Map<String, dynamic>> encryptFileAES256(
    Uint8List fileData,
    Uint8List key,
  ) async {
    try {
      // Generate random IV (16 bytes)
      final random = SecureRandom('Fortuna');
      final iv = random.nextBytes(16);

      // Create cipher
      final cipher = GCMBlockCipher(AESEngine());
      final keyParameter = KeyParameter(key);
      final encryptParams = AEADParameters(keyParameter, 128, iv, Uint8List(0));
      cipher.init(true, encryptParams);

      // Encrypt data
      final encrypted = cipher.process(fileData);

      // Extract auth tag (last 16 bytes)
      final encryptedWithoutTag =
          encrypted.sublist(0, encrypted.length - 16);
      final authTag = encrypted.sublist(encrypted.length - 16);

      return {
        'encrypted': encryptedWithoutTag,
        'iv': iv,
        'authTag': authTag,
        'key': key, // Store key securely in real app
      };
    } catch (e) {
      throw EncryptionException('Encryption failed: $e');
    }
  }

  // ========================================
  // DECRYPT FILE - AES-256-GCM
  // ========================================

  Future<Uint8List> decryptFileAES256(
    Uint8List encryptedData,
    Uint8List iv,
    Uint8List authTag,
    Uint8List key,
  ) async {
    try {
      // Create cipher
      final cipher = GCMBlockCipher(AESEngine());
      final keyParameter = KeyParameter(key);
      final encryptParams = AEADParameters(keyParameter, 128, iv, Uint8List(0));
      cipher.init(false, encryptParams);

      // Combine encrypted data with auth tag
      final encryptedWithTag = Uint8List.fromList([
        ...encryptedData,
        ...authTag,
      ]);

      // Decrypt data
      final decrypted = cipher.process(encryptedWithTag);

      return decrypted;
    } catch (e) {
      throw EncryptionException('Decryption failed: $e');
    }
  }

  // ========================================
  // HASH FILE - SHA-256
  // ========================================

  String hashFileSHA256(Uint8List data) {
    return sha256.convert(data).toString();
  }

  // ========================================
  // SHRED DATA - OVERWRITE MEMORY
  // ========================================

  void shredData(Uint8List data) {
    // Overwrite data 3 times (DoD 5220.22-M standard)
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < data.length; j++) {
        data[j] = (i % 2 == 0) ? 0xFF : 0x00;
      }
    }
    // Mark as cleared
    // In real app, would need to use FFI to truly clear memory
  }

  // ========================================
  // VERIFY ENCRYPTION
  // ========================================

  Future<bool> verifyEncryption(
    Uint8List originalData,
    Map<String, dynamic> encryptionResult,
  ) async {
    try {
      // Decrypt and verify we get original data back
      final decrypted = await decryptFileAES256(
        encryptionResult['encrypted'],
        encryptionResult['iv'],
        encryptionResult['authTag'],
        encryptionResult['key'],
      );

      // Compare
      return _bytesEqual(originalData, decrypted);
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // HELPER: COMPARE BYTES
  // ========================================

  bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// ========================================
// ENCRYPTION EXCEPTION
// ========================================

class EncryptionException implements Exception {
  final String message;

  EncryptionException(this.message);

  @override
  String toString() => message;
}
