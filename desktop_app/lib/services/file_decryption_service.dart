// ========================================
// DESKTOP APP - FILE DECRYPTION SERVICE
// Decrypts files using owner's RSA private key
// ========================================

import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/asymmetric/rsa_key_parser.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';

// ========================================
// FILE DECRYPTION SERVICE
// ========================================

class FileDecryptionService {
  // ========================================
  // DECRYPT FILE
  // ========================================

  static Future<Uint8List?> decryptFile({
    required Uint8List encryptedData,
    required String privateKeyPem,
    required String iv,
    required String authTag,
  }) async {
    try {
      // 1. Parse RSA private key from PEM
      final privateKey = _parsePrivateKey(privateKeyPem);
      if (privateKey == null) {
        throw Exception('Invalid private key');
      }

      // 2. Decrypt the AES key using RSA
      final encryptedKeyBytes = base64Decode(
        iv,
      ); // Note: In real impl, this should be encrypted key
      final decryptedAesKey = _decryptWithRsa(encryptedKeyBytes, privateKey);

      if (decryptedAesKey == null) {
        throw Exception('Failed to decrypt AES key');
      }

      // 3. Decrypt the file using AES-256-GCM
      final decryptedData = _decryptAes256Gcm(
        encryptedData: encryptedData,
        aesKey: decryptedAesKey,
        iv: base64Decode(iv),
        authTag: base64Decode(authTag),
      );

      return decryptedData;
    } catch (e) {
      debugPrint('Error decrypting file: $e');
      return null;
    }
  }

  // ========================================
  // PARSE PRIVATE KEY FROM PEM
  // ========================================

  static RSAPrivateKey? _parsePrivateKey(String pemKey) {
    try {
      // Remove PEM headers and whitespace
      var key = pemKey
          .replaceAll('-----BEGIN PRIVATE KEY-----', '')
          .replaceAll('-----END PRIVATE KEY-----', '')
          .replaceAll('-----BEGIN RSA PRIVATE KEY-----', '')
          .replaceAll('-----END RSA PRIVATE KEY-----', '')
          .replaceAll('\n', '')
          .replaceAll('\r', '')
          .trim();

      // Decode base64
      final keyBytes = base64Decode(key);

      // Parse using RSA key parser
      final parser = RSAKeyParser();
      final parsedKey = parser.parse(keyBytes);

      if (parsedKey is RSAPrivateKey) {
        return parsedKey as RSAPrivateKey;
      }

      return null;
    } catch (e) {
      debugPrint('Error parsing private key: $e');
      return null;
    }
  }

  // ========================================
  // DECRYPT WITH RSA
  // ========================================

  static Uint8List? _decryptWithRsa(
    Uint8List encryptedData,
    RSAPrivateKey privateKey,
  ) {
    try {
      // Use PKCS1 padding
      final encryptor = RSAEngine()
        ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));

      final decrypted = encryptor.process(encryptedData);
      return decrypted;
    } catch (e) {
      debugPrint('Error decrypting with RSA: $e');
      return null;
    }
  }

  // ========================================
  // DECRYPT AES-256-GCM
  // ========================================

  static Uint8List? _decryptAes256Gcm({
    required Uint8List encryptedData,
    required Uint8List aesKey,
    required Uint8List iv,
    required Uint8List authTag,
  }) {
    try {
      // TODO: Implement AES-256-GCM decryption
      // For now, return a placeholder
      // In production, use proper AES-GCM library

      debugPrint('Decrypting ${encryptedData.length} bytes with AES-256-GCM');
      debugPrint('Key length: ${aesKey.length}, IV length: ${iv.length}');

      return encryptedData; // Placeholder
    } catch (e) {
      debugPrint('Error decrypting with AES-256-GCM: $e');
      return null;
    }
  }

  // ========================================
  // SAVE DECRYPTED FILE
  // ========================================

  static Future<String?> saveDecryptedFile({
    required Uint8List decryptedData,
    required String originalFileName,
  }) async {
    try {
      // Save to temp directory
      final tempDir = Directory.systemTemp;
      final tempFile = File(
        '${tempDir.path}/decrypt_${DateTime.now().millisecondsSinceEpoch}_$originalFileName',
      );

      await tempFile.writeAsBytes(decryptedData);
      return tempFile.path;
    } catch (e) {
      debugPrint('Error saving decrypted file: $e');
      return null;
    }
  }
}

// ========================================
// DEBUG HELPER
// ========================================

void debugPrint(String message) {
  print('[FileDecryption] $message');
}
