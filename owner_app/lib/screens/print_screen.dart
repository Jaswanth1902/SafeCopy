// ========================================
// PRINT SCREEN - OWNER APP
// Secure File Printing System
// Downloads, decrypts, and prints files
// ========================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';
import '../services/decryption_service.dart';
import '../services/printer_service.dart';
import '../services/api_service.dart';

// ========================================
// PRINT SCREEN - MAIN WIDGET
// ========================================

class PrintScreen extends StatefulWidget {
  const PrintScreen({Key? key}) : super(key: key);

  @override
  State<PrintScreen> createState() => _PrintScreenState();
}

class _PrintScreenState extends State<PrintScreen> {
  // State variables
  List<FileItem> fileList = [];
  bool isLoadingFiles = false;
  bool isDownloading = false;
  bool isDecrypting = false;
  bool isPrinting = false;
  String? selectedFileId;
  String? statusMessage;
  String? errorMessage;
  double downloadProgress = 0.0;
  double printProgress = 0.0;
  Printer? selectedPrinter;
  List<Printer> availablePrinters = [];

  // Constants
  static const String apiBaseUrl = 'http://localhost:5000';
  late DecryptionService decryptionService;
  late PrinterService printerService;
  late ApiService apiService;

  @override
  void initState() {
    super.initState();
    decryptionService = context.read<DecryptionService>();
    printerService = context.read<PrinterService>();
    apiService = context.read<ApiService>();
    _initializeScreen();
  }

  // ========================================
  // INITIALIZE SCREEN
  // ========================================

  Future<void> _initializeScreen() async {
    await _loadFileList();
    await _loadAvailablePrinters();
  }

  // ========================================
  // LOAD FILE LIST FROM SERVER
  // ========================================

  Future<void> _loadFileList() async {
    setState(() {
      isLoadingFiles = true;
      statusMessage = 'Loading file list...';
      errorMessage = null;
    });

    try {
      final files = await apiService.listFiles();

      setState(() {
        fileList = files.where((f) => !f.isPrinted).toList();
        isLoadingFiles = false;
        statusMessage = 'Found ${fileList.length} files';
      });

      debugPrint('✅ Loaded ${fileList.length} files');
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load files: $e';
        isLoadingFiles = false;
      });
      debugPrint('❌ Error loading files: $e');
      _showErrorDialog('Failed to load files', e.toString());
    }
  }

  // ========================================
  // LOAD AVAILABLE PRINTERS
  // ========================================

  Future<void> _loadAvailablePrinters() async {
    try {
      final printers = await printerService.getAvailablePrinters();
      final defaultPrinter = await printerService.getDefaultPrinter();

      setState(() {
        availablePrinters = printers;
        selectedPrinter = defaultPrinter;
      });

      debugPrint('✅ Loaded ${printers.length} printers');
    } catch (e) {
      debugPrint('⚠️ Warning: Could not load printers: $e');
    }
  }

  // ========================================
  // DOWNLOAD AND DECRYPT FILE
  // ========================================

  Future<Uint8List?> _downloadAndDecryptFile(String fileId) async {
    setState(() {
      isDownloading = true;
      isDecrypting = false;
      statusMessage = 'Downloading file...';
      downloadProgress = 0.0;
      errorMessage = null;
    });

    try {
      debugPrint('📥 Downloading file: $fileId');

      // Download encrypted file
      final response = await apiService.getFileForPrinting(fileId);

      if (response == null) {
        throw Exception('No file data received');
      }

      setState(() {
        isDownloading = false;
        isDecrypting = true;
        statusMessage = 'Decrypting file...';
      });

      debugPrint('✅ Downloaded ${response.encryptedData.length} bytes');
      debugPrint('   IV: ${response.ivVector.toString().substring(0, 20)}...');
      debugPrint('   Auth Tag: ${response.authTag.toString().substring(0, 20)}...');

      // Validate decryption parameters
      decryptionService.validateDecryptionParameters(
        encryptedData: response.encryptedData,
        iv: response.ivVector,
        authTag: response.authTag,
        key: response.decryptionKey,
      );

      // Decrypt file
      final decrypted = await decryptionService.decryptFileAES256(
        response.encryptedData,
        response.ivVector,
        response.authTag,
        response.decryptionKey,
      );

      setState(() {
        isDecrypting = false;
      });

      debugPrint('✅ Decrypted to ${decrypted.length} bytes');
      return decrypted;
    } catch (e) {
      setState(() {
        errorMessage = 'Decryption failed: $e';
        isDownloading = false;
        isDecrypting = false;
      });
      debugPrint('❌ Error: $e');
      rethrow;
    }
  }

  // ========================================
  // PRINT FILE
  // ========================================

  Future<void> _printFile(String fileId, String fileName) async {
    if (selectedPrinter == null && availablePrinters.isEmpty) {
      _showErrorDialog(
        'No Printer Available',
        'No printer found. Please install a printer.',
      );
      return;
    }

    try {
      setState(() {
        isPrinting = true;
        statusMessage = 'Downloading and decrypting...';
        printProgress = 0.25;
      });

      // Download and decrypt
      final decrypted = await _downloadAndDecryptFile(fileId);

      if (decrypted == null) {
        throw Exception('Failed to decrypt file');
      }

      setState(() {
        printProgress = 0.5;
        statusMessage = 'Preparing to print...';
      });

      // Guess extension
      final extension = decryptionService.guessFileExtension(decrypted);

      setState(() {
        printProgress = 0.75;
        statusMessage = 'Sending to printer...';
      });

      // Print file
      final success = await printerService.printFile(
        fileData: decrypted,
        fileName: fileName,
        fileExtension: extension,
        printer: selectedPrinter,
      );

      if (success) {
        setState(() {
          printProgress = 1.0;
          statusMessage = 'Print completed successfully!';
          isPrinting = false;
        });

        debugPrint('✅ Print completed');

        // Mark as printed and delete
        await _markPrintedAndDelete(fileId);

        // Refresh file list
        await _loadFileList();

        _showSuccessDialog('Print Successful', 'File has been printed and deleted from server.');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Print failed: $e';
        isPrinting = false;
      });
      debugPrint('❌ Print error: $e');
      _showErrorDialog('Print Failed', e.toString());
    }
  }

  // ========================================
  // MARK PRINTED AND DELETE
  // ========================================

  Future<void> _markPrintedAndDelete(String fileId) async {
    try {
      debugPrint('🗑️ Deleting file from server: $fileId');
      await apiService.deleteFile(fileId);
      debugPrint('✅ File deleted');
    } catch (e) {
      debugPrint('⚠️ Warning: Could not delete file: $e');
      // Don't fail the print if deletion fails
    }
  }

  // ========================================
  // SHOW ERROR DIALOG
  // ========================================

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(message),
        ),
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
  // SHOW SUCCESS DIALOG
  // ========================================

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
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
  // BUILD UI
  // ========================================

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 20),

            // Printer Selection
            _buildPrinterSelector(),
            const SizedBox(height: 20),

            // Status Messages
            if (statusMessage != null) _buildStatusMessage(),
            if (errorMessage != null) _buildErrorMessage(),
            const SizedBox(height: 20),

            // File List
            _buildFileList(),
            const SizedBox(height: 20),

            // Progress Indicators
            if (isDownloading || isDecrypting || isPrinting) _buildProgressIndicators(),
          ],
        ),
      ),
    );
  }

  // ========================================
  // BUILD HEADER
  // ========================================

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Print Files',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: _loadFileList,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Download encrypted files, decrypt locally, and print securely',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  // ========================================
  // BUILD PRINTER SELECTOR
  // ========================================

  Widget _buildPrinterSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Printer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (availablePrinters.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  '⚠️ No printers available. Please install a printer.',
                  style: TextStyle(color: Colors.orange),
                ),
              )
            else
              DropdownButton<Printer>(
                value: selectedPrinter,
                isExpanded: true,
                items: availablePrinters
                    .map((printer) => DropdownMenuItem(
                          value: printer,
                          child: Text(printer.name),
                        ))
                    .toList(),
                onChanged: (printer) {
                  setState(() {
                    selectedPrinter = printer;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // BUILD STATUS MESSAGE
  // ========================================

  Widget _buildStatusMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusMessage!,
              style: TextStyle(color: Colors.blue.shade700),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // BUILD ERROR MESSAGE
  // ========================================

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // BUILD FILE LIST
  // ========================================

  Widget _buildFileList() {
    if (isLoadingFiles) {
      return const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading files...'),
          ],
        ),
      );
    }

    if (fileList.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.inbox,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No files to print',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: fileList
          .map((file) => _buildFileCard(file))
          .toList(),
    );
  }

  // ========================================
  // BUILD FILE CARD
  // ========================================

  Widget _buildFileCard(FileItem file) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.fileName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(file.fileSizeBytes / 1024).toStringAsFixed(1)} KB',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    file.isPrinted ? 'Printed' : 'Ready',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: file.isPrinted ? Colors.green.shade100 : Colors.blue.shade100,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Print button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (isPrinting || isDownloading || isDecrypting)
                    ? null
                    : () => _printFile(file.id, file.fileName),
                icon: const Icon(Icons.print),
                label: const Text('Print'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // BUILD PROGRESS INDICATORS
  // ========================================

  Widget _buildProgressIndicators() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progress',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (isDownloading)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Downloading...'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: downloadProgress),
                  const SizedBox(height: 16),
                ],
              ),
            if (isDecrypting)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Decrypting...'),
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(value: 0.5),
                  const SizedBox(height: 16),
                ],
              ),
            if (isPrinting)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Printing...'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: printProgress),
                  const SizedBox(height: 16),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ========================================
// FILE ITEM MODEL
// ========================================

class FileItem {
  final String id;
  final String fileName;
  final int fileSizeBytes;
  final bool isPrinted;
  final DateTime createdAt;

  FileItem({
    required this.id,
    required this.fileName,
    required this.fileSizeBytes,
    required this.isPrinted,
    required this.createdAt,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      id: json['id'] ?? '',
      fileName: json['file_name'] ?? 'Unknown',
      fileSizeBytes: json['file_size_bytes'] ?? 0,
      isPrinted: json['is_printed'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
    );
  }
}
