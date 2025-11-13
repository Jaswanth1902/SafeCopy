// ========================================
// DESKTOP APP - OWNER API SERVICE
// Handles API communication for desktop app
// ========================================

import 'package:http/http.dart' as http;
import 'dart:convert';

// ========================================
// MODELS
// ========================================

class OwnerLoginResponse {
  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> owner;

  OwnerLoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.owner,
  });

  factory OwnerLoginResponse.fromJson(Map<String, dynamic> json) {
    return OwnerLoginResponse(
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      owner: json['owner'] ?? {},
    );
  }
}

class PrintFile {
  final String fileId;
  final String fileName;
  final String userId;
  final String uploadedAt;
  final bool printed;

  PrintFile({
    required this.fileId,
    required this.fileName,
    required this.userId,
    required this.uploadedAt,
    required this.printed,
  });

  factory PrintFile.fromJson(Map<String, dynamic> json) {
    return PrintFile(
      fileId: json['file_id'] ?? '',
      fileName: json['file_name'] ?? 'Unknown',
      userId: json['user_id'] ?? '',
      uploadedAt: json['uploaded_at'] ?? '',
      printed: json['printed'] ?? false,
    );
  }
}

// ========================================
// OWNER API SERVICE
// ========================================

class OwnerApiService {
  static const String apiBaseUrl = 'http://localhost:5000';

  // ========================================
  // OWNER LOGIN
  // ========================================

  Future<OwnerLoginResponse> loginOwner({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$apiBaseUrl/api/owners/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return OwnerLoginResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Login failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // GET PRINT JOBS
  // ========================================

  Future<List<PrintFile>> getPrintJobs({required String accessToken}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$apiBaseUrl/api/files'),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final files = List<Map<String, dynamic>>.from(data['files'] ?? []);
        return files.map((f) => PrintFile.fromJson(f)).toList();
      } else {
        throw Exception('Failed to load print jobs: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // GET FILE FOR PRINTING
  // ========================================

  Future<Map<String, dynamic>> getFileForPrinting({
    required String fileId,
    required String accessToken,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$apiBaseUrl/api/print/$fileId'),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['file'] ?? {};
      } else if (response.statusCode == 403) {
        throw Exception('Permission denied');
      } else {
        throw Exception('File not found');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // SUBMIT PRINT JOB
  // ========================================

  Future<void> submitPrintJob({
    required String fileId,
    required String accessToken,
    required int copies,
    required bool color,
    required String paperSize,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$apiBaseUrl/api/print/$fileId'),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'file_id': fileId,
              'copies': copies,
              'color': color,
              'paper_size': paperSize,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Print job submission failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // DELETE FILE
  // ========================================

  Future<void> deleteFile({
    required String fileId,
    required String accessToken,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$apiBaseUrl/api/delete/$fileId'),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Delete failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // GET OWNER PUBLIC KEY
  // ========================================

  Future<String> getOwnerPublicKey({required String ownerId}) async {
    try {
      final response = await http
          .get(Uri.parse('$apiBaseUrl/api/owners/public-key/$ownerId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['public_key'] ?? '';
      } else {
        throw Exception('Failed to get public key');
      }
    } catch (e) {
      rethrow;
    }
  }
}
