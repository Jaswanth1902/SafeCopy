// ========================================
// API SERVICE - OWNER APP
// HTTP communication with backend
// ========================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  // ========================================
  // GET FILE LIST
  // ========================================

  Future<List<FileListItem>> listFiles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/files'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final files = (json['files'] as List)
            .map((f) => FileListItem.fromJson(f))
            .toList();
        return files;
      } else {
        throw ApiException('Failed to load files: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('List files error: $e');
    }
  }

  // ========================================
  // GET FILE FOR PRINTING
  // ========================================

  Future<PrintFileResponse?> getFileForPrinting(String fileId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/print/$fileId'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['file'] == null) {
          return null;
        }

        final encryptedData = base64Decode(json['file']);
        final iv = base64Decode(json['iv_vector']);
        final authTag = base64Decode(json['auth_tag']);

        // In a real app, you would retrieve the encryption key from secure storage
        // For now, we'll use a placeholder
        final key = Uint8List(32);

        return PrintFileResponse(
          fileName: json['file_name'],
          fileSizeBytes: json['file_size_bytes'],
          encryptedData: encryptedData,
          ivVector: iv,
          authTag: authTag,
          decryptionKey: key,
        );
      } else if (response.statusCode == 404) {
        throw ApiException('File not found');
      } else {
        throw ApiException('Failed to get file: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Get file error: $e');
    }
  }

  // ========================================
  // DELETE FILE
  // ========================================

  Future<bool> deleteFile(String fileId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/delete/$fileId'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['success'] ?? true;
      } else {
        throw ApiException('Failed to delete file: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Delete file error: $e');
    }
  }

  // ========================================
  // CHECK BACKEND HEALTH
  // ========================================

  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

// ========================================
// RESPONSE MODELS
// ========================================

class FileListItem {
  final String id;
  final String fileName;
  final int fileSizeBytes;
  final bool isPrinted;
  final DateTime createdAt;

  FileListItem({
    required this.id,
    required this.fileName,
    required this.fileSizeBytes,
    required this.isPrinted,
    required this.createdAt,
  });

  factory FileListItem.fromJson(Map<String, dynamic> json) {
    return FileListItem(
      id: json['id'] ?? '',
      fileName: json['file_name'] ?? 'Unknown',
      fileSizeBytes: json['file_size_bytes'] ?? 0,
      isPrinted: json['is_printed'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
    );
  }
}

class PrintFileResponse {
  final String fileName;
  final int fileSizeBytes;
  final Uint8List encryptedData;
  final Uint8List ivVector;
  final Uint8List authTag;
  final Uint8List decryptionKey;

  PrintFileResponse({
    required this.fileName,
    required this.fileSizeBytes,
    required this.encryptedData,
    required this.ivVector,
    required this.authTag,
    required this.decryptionKey,
  });
}

// ========================================
// API EXCEPTION
// ========================================

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}
