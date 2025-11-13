// ========================================
// API SERVICE - HTTP COMMUNICATION
// Handles all backend API calls
// ========================================

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

class ApiService {
  final String baseUrl = 'http://localhost:5000';

  // ========================================
  // AUTHENTICATION
  // ========================================

  Future<LoginResponse> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return LoginResponse.fromJson(json);
      } else {
        throw ApiException(
          'Login failed: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Login error: $e', -1);
    }
  }

  Future<RegisterResponse> registerUser({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/register');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'full_name': fullName,
        }),
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return RegisterResponse.fromJson(json);
      } else {
        throw ApiException(
          'Registration failed: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Registration error: $e', -1);
    }
  }

  Future<void> logoutUser({required String refreshToken}) async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/logout');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
    } catch (e) {
      // Logout errors are not critical
    }
  }

  // ========================================
  // UPLOAD FILE
  // ========================================

  Future<UploadResponse> uploadFile({
    required Uint8List encryptedData,
    required Uint8List ivVector,
    required Uint8List authTag,
    required String fileName,
    required String fileMimeType,
    required String accessToken,
    required String ownerId,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/upload');

      // Create multipart request
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $accessToken';

      // Add fields
      request.fields['file_name'] = fileName;
      request.fields['iv_vector'] = base64Encode(ivVector);
      request.fields['auth_tag'] = base64Encode(authTag);
      request.fields['owner_id'] = ownerId;

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          encryptedData,
          filename: fileName,
          contentType: http.MediaType.parse(fileMimeType),
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return UploadResponse.fromJson(json);
      } else {
        throw ApiException(
          'Upload failed: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Upload error: $e', -1);
    }
  }

  // ========================================
  // LIST FILES
  // ========================================

  Future<List<FileItem>> listFiles({required String accessToken}) async {
    try {
      final url = Uri.parse('$baseUrl/api/files');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final files = (json['files'] as List)
            .map((f) => FileItem.fromJson(f))
            .toList();
        return files;
      } else {
        throw ApiException(
          'Failed to list files: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('List files error: $e', -1);
    }
  }

  // ========================================
  // GET FILE FOR PRINTING
  // ========================================

  Future<PrintFileResponse> getFileForPrinting({
    required String fileId,
    required String accessToken,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/print/$fileId');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return PrintFileResponse.fromJson(json);
      } else {
        throw ApiException(
          'Failed to get file: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Get file error: $e', -1);
    }
  }

  // ========================================
  // DELETE FILE
  // ========================================

  Future<DeleteResponse> deleteFile({
    required String fileId,
    required String accessToken,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/delete/$fileId');
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return DeleteResponse.fromJson(json);
      } else {
        throw ApiException(
          'Failed to delete file: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Delete file error: $e', -1);
    }
  }

  // ========================================
  // CHECK HEALTH
  // ========================================

  Future<bool> checkHealth() async {
    try {
      final url = Uri.parse('$baseUrl/health');
      final response = await http.get(url);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

// ========================================
// RESPONSE MODELS
// ========================================

class UploadResponse {
  final bool success;
  final String fileId;
  final String fileName;
  final int fileSizeBytes;
  final String uploadedAt;
  final String message;

  UploadResponse({
    required this.success,
    required this.fileId,
    required this.fileName,
    required this.fileSizeBytes,
    required this.uploadedAt,
    required this.message,
  });

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      success: json['success'] ?? false,
      fileId: json['file_id'] ?? '',
      fileName: json['file_name'] ?? '',
      fileSizeBytes: json['file_size_bytes'] ?? 0,
      uploadedAt: json['uploaded_at'] ?? '',
      message: json['message'] ?? '',
    );
  }
}

class FileItem {
  final String fileId;
  final String fileName;
  final int fileSizeBytes;
  final String uploadedAt;
  final bool isPrinted;
  final String? printedAt;
  final String status;

  FileItem({
    required this.fileId,
    required this.fileName,
    required this.fileSizeBytes,
    required this.uploadedAt,
    required this.isPrinted,
    this.printedAt,
    required this.status,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      fileId: json['file_id'] ?? '',
      fileName: json['file_name'] ?? '',
      fileSizeBytes: json['file_size_bytes'] ?? 0,
      uploadedAt: json['uploaded_at'] ?? '',
      isPrinted: json['is_printed'] ?? false,
      printedAt: json['printed_at'],
      status: json['status'] ?? 'UNKNOWN',
    );
  }
}

class PrintFileResponse {
  final bool success;
  final String fileId;
  final String fileName;
  final int fileSizeBytes;
  final String uploadedAt;
  final bool isPrinted;
  final String encryptedFileData;
  final String ivVector;
  final String authTag;
  final String message;

  PrintFileResponse({
    required this.success,
    required this.fileId,
    required this.fileName,
    required this.fileSizeBytes,
    required this.uploadedAt,
    required this.isPrinted,
    required this.encryptedFileData,
    required this.ivVector,
    required this.authTag,
    required this.message,
  });

  factory PrintFileResponse.fromJson(Map<String, dynamic> json) {
    return PrintFileResponse(
      success: json['success'] ?? false,
      fileId: json['file_id'] ?? '',
      fileName: json['file_name'] ?? '',
      fileSizeBytes: json['file_size_bytes'] ?? 0,
      uploadedAt: json['uploaded_at'] ?? '',
      isPrinted: json['is_printed'] ?? false,
      encryptedFileData: json['encrypted_file_data'] ?? '',
      ivVector: json['iv_vector'] ?? '',
      authTag: json['auth_tag'] ?? '',
      message: json['message'] ?? '',
    );
  }
}

class DeleteResponse {
  final bool success;
  final String fileId;
  final String status;
  final String deletedAt;
  final String message;

  DeleteResponse({
    required this.success,
    required this.fileId,
    required this.status,
    required this.deletedAt,
    required this.message,
  });

  factory DeleteResponse.fromJson(Map<String, dynamic> json) {
    return DeleteResponse(
      success: json['success'] ?? false,
      fileId: json['file_id'] ?? '',
      status: json['status'] ?? '',
      deletedAt: json['deleted_at'] ?? '',
      message: json['message'] ?? '',
    );
  }
}

class UserInfo {
  final String id;
  final String email;
  final String? fullName;

  UserInfo({required this.id, required this.email, this.fullName});

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'],
    );
  }
}

class LoginResponse {
  final bool success;
  final String accessToken;
  final String refreshToken;
  final UserInfo user;

  LoginResponse({
    required this.success,
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      user: UserInfo.fromJson(json['user'] ?? {}),
    );
  }
}

class RegisterResponse {
  final bool success;
  final String accessToken;
  final String refreshToken;
  final UserInfo user;

  RegisterResponse({
    required this.success,
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      success: json['success'] ?? false,
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      user: UserInfo.fromJson(json['user'] ?? {}),
    );
  }
}

// ========================================
// API EXCEPTION
// ========================================

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
