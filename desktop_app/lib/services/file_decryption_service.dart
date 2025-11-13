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
import 'package:pointycastle/paddings/oaep.dart';
import 'package:pointycastle/paddings/oaep_encoding.dart';
import 'package:pointycastle/block/aes_fast.dart';
import 'package:pointycastle/block/modes/gcm.dart';

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
    required String encryptedAesKey,
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
      final encryptedKeyBytes = base64Decode(encryptedAesKey);
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

      // Parse using RSA key parser (pass the PEM string to parser)
      // Parse using RSA key parser (pass the PEM string to parser)
      final parser = RSAKeyParser();
      final parsedKey = parser.parse(pemKey);

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
      // Use OAEP padding for security
      final encryptor = OAEPEncoding(RSAEngine())
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
      // Validate inputs
      if (aesKey.length != 32) {
        debugPrint('Invalid AES key length: ${aesKey.length}. Expected 32 bytes for AES-256.');
        return null;
      }
      if (iv.isEmpty) {
        debugPrint('IV is required for AES-GCM');
        return null;
      }
      if (authTag.isEmpty) {
        debugPrint('Authentication tag is required for AES-GCM');
        return null;
      }

      // GCM expects ciphertext concatenated with the auth tag for processing
      final input = Uint8List.fromList([
        ...encryptedData,
        ...authTag,
      ]);

      final aead = GCMBlockCipher(AESFastEngine());
      final params = AEADParameters(KeyParameter(aesKey), authTag.length * 8, iv, Uint8List(0));
      aead.init(false, params); // false = decrypt

      final output = aead.process(input);
      return output;
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
      // Sanitize filename to prevent path traversal
      final sanitizedName = originalFileName.split('/').last.split('\\').last;
      
      // Save to temp directory
      final tempDir = Directory.systemTemp;
      final tempFile = File(
        '${tempDir.path}/decrypt_${DateTime.now().millisecondsSinceEpoch}_$sanitizedName',
      );

      await tempFile.writeAsBytes(decryptedData);
      return tempFile.path;
    } catch (e) {
      debugPrint('Error saving decrypted file: $e');
      return null;
    }
  }}

// ========================================
// DEBUG HELPER
// ========================================

void debugPrint(String message) {
  print('[FileDecryption] $message');
}
