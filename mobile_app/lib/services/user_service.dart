// ========================================
// USER SERVICE - TOKEN & SECURE STORAGE
// Manages JWT tokens and secure storage
// ========================================

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _emailKey = 'user_email';

  final _storage = const FlutterSecureStorage();

  // ========================================
  // TOKEN STORAGE
  // ========================================

  /// Save access and refresh tokens securely
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String email,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: _accessTokenKey, value: accessToken),
        _storage.write(key: _refreshTokenKey, value: refreshToken),
        _storage.write(key: _userIdKey, value: userId),
        _storage.write(key: _emailKey, value: email),
      ]);
    } catch (e) {
      throw Exception('Failed to save tokens: $e');
    }
  }

  /// Get stored access token
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Get stored refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Get stored user ID
  Future<String?> getUserId() async {
    try {
      return await _storage.read(key: _userIdKey);
    } catch (e) {
      return null;
    }
  }

  /// Get stored email
  Future<String?> getEmail() async {
    try {
      return await _storage.read(key: _emailKey);
    } catch (e) {
      return null;
    }
  }

  // ========================================
  // AUTHENTICATION STATUS
  // ========================================

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return false;
    return !isTokenExpired(token);
  }  }

  /// Logout - clear all stored tokens
  Future<void> logout() async {
    try {
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _userIdKey),
        _storage.delete(key: _emailKey),
      ]);
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }

  // ========================================
  // TOKEN VALIDATION
  // ========================================

  /// Simple JWT decode (does NOT verify signature)
  /// For production, use jwt package to properly decode and validate
  Map<String, dynamic>? decodeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Decode payload (second part)
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));

      return jsonDecode(decoded);
    } catch (e) {
      return null;
    }
  }

  /// Check if token is expired
  bool isTokenExpired(String token) {
    final payload = decodeToken(token);
    if (payload == null) return true;

    final expTime = payload['exp'];
    if (expTime == null) return true;

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= expTime;
  }
}
