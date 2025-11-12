// ========================================
// DECRYPTION SERVICE - OWNER APP
// Handles AES-256-GCM decryption
// ========================================

import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

class DecryptionService {
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
      throw DecryptionException('Decryption failed: $e');
    }
  }

  // ========================================
  // VERIFY FILE INTEGRITY
  // ========================================

  bool verifyFileIntegrity(Uint8List decryptedData) {
    // In a real app, you might:
    // 1. Check file headers/magic numbers
    // 2. Verify file format
    // 3. Calculate checksum
    // For now, just verify it's not empty
    return decryptedData.isNotEmpty;
  }

  // ========================================
  // HASH FILE - SHA-256
  // ========================================

  String hashFileSHA256(Uint8List data) {
    return sha256.convert(data).toString();
  }

  // ========================================
  // VALIDATE DECRYPTION PARAMETERS
  // ========================================

  bool validateDecryptionParameters({
    required Uint8List encryptedData,
    required Uint8List iv,
    required Uint8List authTag,
    required Uint8List key,
  }) {
    // Check sizes
    if (iv.length != 16) {
      throw DecryptionException('Invalid IV size: ${iv.length} (expected 16)');
    }
    if (authTag.length != 16) {
      throw DecryptionException('Invalid auth tag size: ${authTag.length} (expected 16)');
    }
    if (key.length != 32) {
      throw DecryptionException('Invalid key size: ${key.length} (expected 32)');
    }
    if (encryptedData.isEmpty) {
      throw DecryptionException('Encrypted data is empty');
    }

    return true;
  }

  // ========================================
  // DECODE BASE64 PARAMETERS
  // ========================================

  Uint8List decodeBase64(String encoded) {
    try {
      return Uint8List.fromList(base64Decode(encoded));
    } catch (e) {
      throw DecryptionException('Base64 decode failed: $e');
    }
  }

  // ========================================
  // GET FILE EXTENSION FROM BYTES
  // ========================================

  String guessFileExtension(Uint8List data) {
    if (data.length < 4) return '.bin';

    // Check common file signatures
    final header = data.sublist(0, 4);

    // PDF
    if (header[0] == 0x25 && header[1] == 0x50 && header[2] == 0x44) {
      return '.pdf';
    }

    // PNG
    if (header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E) {
      return '.png';
    }

    // JPEG
    if (header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF) {
      return '.jpg';
    }

    // ZIP (docx, xlsx, etc)
    if (header[0] == 0x50 && header[1] == 0x4B && header[2] == 0x03) {
      return '.zip';
    }

    // GIF
    if (header[0] == 0x47 && header[1] == 0x49 && header[2] == 0x46) {
      return '.gif';
    }

    // Default
    return '.bin';
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
  }
}

// ========================================
// DECRYPTION EXCEPTION
// ========================================

class DecryptionException implements Exception {
  final String message;

  DecryptionException(this.message);

  @override
  String toString() => message;
}
