// Authentication Service
// Handles JWT token generation, validation, and password hashing

const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');

class AuthService {
  /**
   * Hash password using bcrypt
   * @param {string} password - Plain text password
   * @returns {Promise<string>} - Hashed password
   */
  static async hashPassword(password) {
    try {
      const salt = await bcrypt.genSalt(10);
      return await bcrypt.hash(password, salt);
    } catch (error) {
      throw new Error(`Password hashing failed: ${error.message}`);
    }
  }

  /**
   * Compare password with hash
   * @param {string} password - Plain text password
   * @param {string} hash - Password hash
   * @returns {Promise<boolean>} - True if password matches
   */
  static async comparePassword(password, hash) {
    try {
      return await bcrypt.compare(password, hash);
    } catch (error) {
      throw new Error(`Password comparison failed: ${error.message}`);
    }
  }

  /**
   * Generate JWT access token
   * @param {Object} payload - Token payload
   * @param {string} expiresIn - Token expiration (default: 1h)
   * @returns {string} - JWT token
   */
  static generateAccessToken(payload, expiresIn = '1h') {
    try {
      return jwt.sign(payload, process.env.JWT_SECRET, {
        expiresIn,
        algorithm: 'HS256',
      });
    } catch (error) {
      throw new Error(`Access token generation failed: ${error.message}`);
    }
  }

  /**
   * Generate JWT refresh token
   * @param {Object} payload - Token payload
   * @param {string} expiresIn - Token expiration (default: 7d)
   * @returns {string} - JWT token
   */
  static generateRefreshToken(payload, expiresIn = '7d') {
    try {
      return jwt.sign(payload, process.env.JWT_REFRESH_SECRET, {
        expiresIn,
        algorithm: 'HS256',
      });
    } catch (error) {
      throw new Error(`Refresh token generation failed: ${error.message}`);
    }
  }

  /**
   * Verify JWT access token
   * @param {string} token - JWT token
   * @returns {Object} - Decoded token payload
   * @throws {Error} - If token is invalid or expired
   */
  static verifyAccessToken(token) {
    try {
      return jwt.verify(token, process.env.JWT_SECRET, {
        algorithms: ['HS256'],
      });
    } catch (error) {
      throw new Error(`Invalid or expired access token: ${error.message}`);
    }
  }

  /**
   * Verify JWT refresh token
   * @param {string} token - JWT token
   * @returns {Object} - Decoded token payload
   * @throws {Error} - If token is invalid or expired
   */
  static verifyRefreshToken(token) {
    try {
      return jwt.verify(token, process.env.JWT_REFRESH_SECRET, {
        algorithms: ['HS256'],
      });
    } catch (error) {
      throw new Error(`Invalid or expired refresh token: ${error.message}`);
    }
  }

  /**
   * Decode JWT token without verification
   * @param {string} token - JWT token
   * @returns {Object} - Decoded token payload
   */
  static decodeToken(token) {
    try {
      return jwt.decode(token);
    } catch (error) {
      return null;
    }
  }

  /**
   * Hash token for storage in database
   * @param {string} token - Token to hash
   * @returns {string} - SHA-256 hash of token
   */
  static hashToken(token) {
    return crypto.createHash('sha256').update(token).digest('hex');
  }

  /**
   * Validate password strength
   * @param {string} password - Password to validate
   * @returns {Object} - { isValid, errors }
   */
  static validatePassword(password) {
    const errors = [];

    if (!password || password.length < 8) {
      errors.push('Password must be at least 8 characters long');
    }

    if (!/[A-Z]/.test(password)) {
      errors.push('Password must contain at least one uppercase letter');
    }

    if (!/[a-z]/.test(password)) {
      errors.push('Password must contain at least one lowercase letter');
    }

    if (!/[0-9]/.test(password)) {
      errors.push('Password must contain at least one digit');
    }

    if (!/[!@#$%^&*]/.test(password)) {
      errors.push('Password must contain at least one special character (!@#$%^&*)');
    }

    return {
      isValid: errors.length === 0,
      errors,
    };
  }

  /**
   * Validate email format
   * @param {string} email - Email to validate
   * @returns {boolean} - True if valid email format
   */
  static validateEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  /**
   * Generate random code (for OTP, etc.)
   * @param {number} length - Code length
   * @returns {string} - Random code
   */
  static generateCode(length = 6) {
    const digits = '0123456789';
    let code = '';
    for (let i = 0; i < length; i++) {
      code += digits.charAt(Math.floor(Math.random() * digits.length));
    }
    return code;
  }
}

module.exports = AuthService;
