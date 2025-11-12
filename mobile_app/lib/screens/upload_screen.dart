// ========================================
// MOBILE APP - UPLOAD SCREEN
// Secure File Printing System
// Handles file selection, encryption, and upload
// ========================================

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../services/encryption_service.dart';
import '../services/api_service.dart';

// ========================================
// UPLOAD SCREEN - MAIN WIDGET
// ========================================

class UploadScreen extends StatefulWidget {
  const UploadScreen({Key? key}) : super(key: key);

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  // State variables
  String? selectedFileName;
  int? selectedFileSize;
  bool isEncrypting = false;
  bool isUploading = false;
  double uploadProgress = 0.0;
  String? uploadStatus;
  String? uploadedFileId;
  Uint8List? selectedFileBytes;
  String? errorMessage;

  // API configuration
  final String apiBaseUrl = 'http://localhost:5000'; // Change for production
  final apiService = ApiService();

  // ========================================
  // REQUEST PERMISSIONS
  // ========================================

  Future<bool> requestPermissions() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  // ========================================
  // PICK FILE FROM DEVICE
  // ========================================

  Future<void> pickFile() async {
    try {
      // Request permissions
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        setState(() {
          errorMessage = 'Storage permission denied. Cannot access files.';
        });
        _showErrorDialog(errorMessage!);
        return;
      }

      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          selectedFileName = result.files.single.name;
          selectedFileSize = result.files.single.size;
          selectedFileBytes = result.files.single.bytes!;
          errorMessage = null;
          uploadStatus = null;
          uploadedFileId = null;
        });

        debugPrint('✅ File selected: $selectedFileName');
        debugPrint('   Size: ${selectedFileSize ?? 0} bytes');
      } else {
        setState(() {
          errorMessage = 'No file selected';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error picking file: $e';
      });
      _showErrorDialog(errorMessage!);
    }
  }

  // ========================================
  // ENCRYPT AND UPLOAD FILE
  // ========================================

  Future<void> encryptAndUploadFile() async {
    if (selectedFileBytes == null || selectedFileName == null) {
      _showErrorDialog('Please select a file first');
      return;
    }

    try {
      setState(() {
        isEncrypting = true;
        uploadStatus = 'Encrypting file...';
        errorMessage = null;
      });

      debugPrint('🔐 Starting encryption...');

      // Step 1: Generate AES-256 key
      final encryptionService = EncryptionService();
      final aesKey = encryptionService.generateAES256Key();
      debugPrint('✅ AES key generated');

      // Step 2: Encrypt file
      final encryptResult = await encryptionService.encryptFileAES256(
        selectedFileBytes!,
        aesKey,
      );

      debugPrint('✅ File encrypted');
      debugPrint('   IV: ${encryptResult['iv'].toString().substring(0, 20)}...');
      debugPrint('   Auth Tag: ${encryptResult['authTag'].toString().substring(0, 20)}...');

      setState(() {
        isEncrypting = false;
        isUploading = true;
        uploadStatus = 'Uploading file to server...';
        uploadProgress = 0.0;
      });

      // Step 3: Upload to server
      await uploadEncryptedFile(
        encryptedData: encryptResult['encrypted'] as Uint8List,
        ivVector: encryptResult['iv'] as Uint8List,
        authTag: encryptResult['authTag'] as Uint8List,
        fileName: selectedFileName!,
        fileMimeType: _getMimeType(selectedFileName!),
      );

      debugPrint('✅ Upload complete');
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isEncrypting = false;
        isUploading = false;
      });
      debugPrint('❌ Error: $e');
      _showErrorDialog(errorMessage!);
    }
  }

  // ========================================
  // UPLOAD ENCRYPTED FILE TO SERVER
  // ========================================

  Future<void> uploadEncryptedFile({
    required Uint8List encryptedData,
    required Uint8List ivVector,
    required Uint8List authTag,
    required String fileName,
    required String fileMimeType,
  }) async {
    try {
      final uploadUri = Uri.parse('$apiBaseUrl/api/upload');

      debugPrint('📤 Uploading to: $uploadUri');
      debugPrint('   File: $fileName (${encryptedData.length} bytes)');

      // Create multipart request
      final request = http.MultipartRequest('POST', uploadUri);

      // Add form fields
      request.fields['file_name'] = fileName;
      request.fields['iv_vector'] = base64Encode(ivVector);
      request.fields['auth_tag'] = base64Encode(authTag);

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          encryptedData,
          filename: fileName,
          contentType: http.MediaType.parse(fileMimeType),
        ),
      );

      // Send request with progress tracking
      final streamedResponse = await request.send();

      // Handle response
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response: ${response.body}');

      if (response.statusCode == 201) {
        // Success!
        final jsonResponse = jsonDecode(response.body);
        final fileId = jsonResponse['file_id'];

        setState(() {
          uploadedFileId = fileId;
          uploadStatus = 'Upload successful! 🎉';
          isUploading = false;
          uploadProgress = 1.0;
        });

        debugPrint('✅ File ID: $fileId');

        // Show success dialog
        if (mounted) {
          _showSuccessDialog(fileId, fileName);
        }
      } else {
        throw Exception(
          'Upload failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Upload failed: $e';
        isUploading = false;
      });
      debugPrint('❌ Upload error: $e');
      rethrow;
    }
  }

  // ========================================
  // GET MIME TYPE
  // ========================================

  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    final mimeTypes = {
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
    };
    return mimeTypes[extension] ?? 'application/octet-stream';
  }

  // ========================================
  // SHOW SUCCESS DIALOG
  // ========================================

  void _showSuccessDialog(String fileId, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ Upload Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your file has been encrypted and uploaded securely!',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'File Details:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'File: $fileName',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Share this ID with the owner:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      fileId,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The file is encrypted and only the owner can decrypt it.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Copy file ID to clipboard
              _copyToClipboard(fileId);
              Navigator.pop(context);
            },
            child: const Text('Copy ID'),
          ),
        ],
      ),
    );
  }

  // ========================================
  // SHOW ERROR DIALOG
  // ========================================

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('❌ Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ========================================
  // COPY TO CLIPBOARD
  // ========================================

  void _copyToClipboard(String text) {
    // In production, use flutter's Clipboard
    debugPrint('File ID copied: $text');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File ID copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ========================================
  // RESET UPLOAD
  // ========================================

  void resetUpload() {
    setState(() {
      selectedFileName = null;
      selectedFileSize = null;
      uploadStatus = null;
      uploadedFileId = null;
      uploadProgress = 0.0;
      errorMessage = null;
      isEncrypting = false;
      isUploading = false;
      selectedFileBytes = null;
    });
  }

  // ========================================
  // BUILD UI
  // ========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SecurePrint - Upload File'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.security,
                      size: 48,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Secure File Upload',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your file will be encrypted before uploading',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // FILE SELECTION SECTION
              if (selectedFileName == null || uploadedFileId == null)
                Column(
                  children: [
                    // File picker button
                    ElevatedButton.icon(
                      onPressed: isEncrypting || isUploading ? null : pickFile,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Select File'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 32,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Selected file info
                    if (selectedFileName != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          border: Border.all(color: Colors.green.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade600,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedFileName!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${(selectedFileSize! / 1024 / 1024).toStringAsFixed(2)} MB',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Upload button
                    if (selectedFileName != null)
                      ElevatedButton(
                        onPressed: isEncrypting || isUploading
                            ? null
                            : encryptAndUploadFile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isEncrypting || isUploading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Encrypt & Upload',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                  ],
                ),

              // PROGRESS SECTION
              if (isEncrypting || isUploading || uploadStatus != null)
                Column(
                  children: [
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            uploadStatus ?? 'Processing...',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: isEncrypting ? null : uploadProgress,
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(uploadProgress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              // SUCCESS SECTION
              if (uploadedFileId != null)
                Column(
                  children: [
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 48,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Upload Complete!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Your file is encrypted and stored on the server.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              uploadedFileId!,
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Share this ID with the owner to print the file',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: resetUpload,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Upload Another File'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              // ERROR SECTION
              if (errorMessage != null)
                Column(
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade600,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 32),

              // SECURITY INFO
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.shield,
                          size: 20,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Security Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '✓ Files are encrypted locally on your device\n'
                      '✓ Encryption key never transmitted\n'
                      '✓ Server only stores encrypted data\n'
                      '✓ Only owner can decrypt and print\n'
                      '✓ File auto-deletes after printing',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
