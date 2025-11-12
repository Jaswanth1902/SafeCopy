// Encryption Service
// Handles AES-256-GCM encryption and RSA key management

const crypto = require('crypto');

class EncryptionService {
  /**
   * Encrypt file with AES-256-GCM
   * @param {Buffer} fileData - File data to encrypt
   * @returns {Object} - { encryptedData, symmetricKey, iv, authTag }
   */
  static encryptFileAES256(fileData) {
    try {
      // Generate random symmetric key and IV
      const symmetricKey = crypto.randomBytes(32); // 256-bit key
      const iv = crypto.randomBytes(16); // 128-bit IV
      
      // Create cipher
      const cipher = crypto.createCipheriv('aes-256-gcm', symmetricKey, iv);
      
      // Encrypt data
      let encryptedData = cipher.update(fileData, 'utf8', 'hex');
      encryptedData += cipher.final('hex');
      
      // Get authentication tag
      const authTag = cipher.getAuthTag();
      
      return {
        encryptedData: Buffer.from(encryptedData, 'hex'),
        symmetricKey,
        iv,
        authTag,
      };
    } catch (error) {
      throw new Error(`AES-256 encryption failed: ${error.message}`);
    }
  }

  /**
   * Decrypt file with AES-256-GCM
   * @param {Buffer} encryptedData - Encrypted data
   * @param {Buffer} symmetricKey - Symmetric key
   * @param {Buffer} iv - Initialization vector
   * @param {Buffer} authTag - Authentication tag
   * @returns {Buffer} - Decrypted data
   */
  static decryptFileAES256(encryptedData, symmetricKey, iv, authTag) {
    try {
      // Create decipher
      const decipher = crypto.createDecipheriv('aes-256-gcm', symmetricKey, iv);
      
      // Set authentication tag
      decipher.setAuthTag(authTag);
      
      // Decrypt data
      let decryptedData = decipher.update(encryptedData, 'hex', 'utf8');
      decryptedData += decipher.final('utf8');
      
      return Buffer.from(decryptedData);
    } catch (error) {
      throw new Error(`AES-256 decryption failed: ${error.message}`);
    }
  }

  /**
   * Encrypt symmetric key with owner's public RSA key
   * @param {Buffer} symmetricKey - Symmetric key to encrypt
   * @param {string} publicKeyPEM - Owner's public key in PEM format
   * @returns {Buffer} - Encrypted symmetric key
   */
  static encryptSymmetricKeyRSA(symmetricKey, publicKeyPEM) {
    try {
      const encrypted = crypto.publicEncrypt(
        {
          key: publicKeyPEM,
          padding: crypto.constants.RSA_PKCS1_OAEP_PADDING,
          oaepHash: 'sha256',
        },
        symmetricKey
      );
      return encrypted;
    } catch (error) {
      throw new Error(`RSA encryption failed: ${error.message}`);
    }
  }

  /**
   * Decrypt symmetric key with owner's private RSA key
   * @param {Buffer} encryptedSymmetricKey - Encrypted symmetric key
   * @param {string} privateKeyPEM - Owner's private key in PEM format
   * @returns {Buffer} - Decrypted symmetric key
   */
  static decryptSymmetricKeyRSA(encryptedSymmetricKey, privateKeyPEM) {
    try {
      const decrypted = crypto.privateDecrypt(
        {
          key: privateKeyPEM,
          padding: crypto.constants.RSA_PKCS1_OAEP_PADDING,
          oaepHash: 'sha256',
        },
        encryptedSymmetricKey
      );
      return decrypted;
    } catch (error) {
      throw new Error(`RSA decryption failed: ${error.message}`);
    }
  }

  /**
   * Generate RSA key pair for owner
   * @returns {Promise<Object>} - { publicKey, privateKey }
   */
  static async generateRSAKeyPair() {
    return new Promise((resolve, reject) => {
      crypto.generateKeyPair(
        'rsa',
        {
          modulusLength: 2048,
          publicKeyEncoding: {
            type: 'spki',
            format: 'pem',
          },
          privateKeyEncoding: {
            type: 'pkcs8',
            format: 'pem',
          },
        },
        (err, publicKey, privateKey) => {
          if (err) reject(err);
          else resolve({ publicKey, privateKey });
        }
      );
    });
  }

  /**
   * Hash file for integrity verification
   * @param {Buffer} fileData - File data
   * @returns {string} - SHA-256 hash
   */
  static hashFile(fileData) {
    return crypto
      .createHash('sha256')
      .update(fileData)
      .digest('hex');
  }

  /**
   * Generate secure random token
   * @param {number} length - Token length in bytes
   * @returns {string} - Base64 encoded token
   */
  static generateToken(length = 32) {
    return crypto.randomBytes(length).toString('base64');
  }

  /**
   * Securely shred data (overwrite with random data)
   * @param {Buffer} buffer - Buffer to shred
   * @returns {Buffer} - Shredded buffer
   */
  static shredData(buffer) {
    if (!buffer) return null;
    
    // Overwrite with random data multiple times (DoD 5220.22-M standard: 3 passes)
    for (let pass = 0; pass < 3; pass++) {
      crypto.randomFillSync(buffer);
    }
    
    return buffer;
  }
}

module.exports = EncryptionService;
