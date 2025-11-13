// ========================================
// MOBILE APP - FILE LIST SCREEN
// Displays user's uploaded files
// ========================================

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/user_service.dart';
import '../services/api_service.dart';
import 'print_screen.dart';

// ========================================
// FILE LIST SCREEN
// ========================================

class FileListScreen extends StatefulWidget {
  const FileListScreen({Key? key}) : super(key: key);

  @override
  State<FileListScreen> createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen> {
  final apiService = ApiService();
  final userService = UserService();

  List<Map<String, dynamic>> files = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final accessToken = await userService.getAccessToken();
      if (accessToken == null) {
        throw Exception('Not authenticated');
      }

      // Get user's files from API
      final response = await http
          .get(
            Uri.parse('${apiService.baseUrl}/api/files'),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Safely validate and cast files list
        List<Map<String, dynamic>> validatedFiles = [];
        try {
          if (data['files'] is List) {
            validatedFiles = (data['files'] as List)
                .where((item) => item is Map)
                .map((item) => Map<String, dynamic>.from(item as Map))
                .toList();
          }
        } catch (e) {
          debugPrint('⚠️ Error validating files list: $e');
          validatedFiles = [];
        }
        
        setState(() {
          files = validatedFiles;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load files: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
      debugPrint('❌ Error loading files: $e');
    }
  }

  void _openFile(String fileId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PrintScreen(fileId: fileId)),
    );
  }

  /// Safely format file ID for display: truncate to 8 chars with ellipsis or show placeholder
  String _formatFileId(dynamic fileId) {
    if (fileId == null || fileId.toString().isEmpty) {
      return 'No ID';
    }
    final idStr = fileId.toString();
    if (idStr.length <= 8) {
      return idStr;
    }
    return '${idStr.substring(0, 8)}...';
  }

  void _deleteFile(String fileId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                final accessToken = await userService.getAccessToken();
                if (accessToken == null) throw Exception('Not authenticated');

                final response = await http
                    .post(
                      Uri.parse('${apiService.baseUrl}/api/delete/$fileId'),
                      headers: {
                        'Authorization': 'Bearer $accessToken',
                        'Content-Type': 'application/json',
                      },
                    )
                    .timeout(const Duration(seconds: 10));

                if (response.statusCode == 200) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('File deleted')));
                  _loadFiles();
                } else {
                  throw Exception('Delete failed');
                }
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Files'),
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.shade600,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $errorMessage',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadFiles,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : files.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No files yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to upload
                      Navigator.pushNamed(context, '/upload');
                    },
                    icon: const Icon(Icons.upload),
                    label: const Text('Upload a File'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadFiles,
              child: ListView.builder(
                itemCount: files.length,
                padding: const EdgeInsets.all(12),
                itemBuilder: (context, index) {
                  final file = files[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.insert_drive_file,
                        color: Colors.blue.shade600,
                      ),
                      title: Text(file['file_name'] ?? 'Unknown'),
                      subtitle: Text(
                        'ID: ${_formatFileId(file['file_id'])}',
                      ),
                      trailing: PopupMenuButton(
                        onSelected: (value) {
                          if (value == 'print') {
                            _openFile(file['file_id'] ?? '');
                          } else if (value == 'delete') {
                            _deleteFile(file['file_id'] ?? '');
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'print',
                            child: Text('Print'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                      onTap: () => _openFile(file['file_id'] ?? ''),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/upload'),
        tooltip: 'Upload File',
        child: const Icon(Icons.add),
      ),
    );
  }
}
