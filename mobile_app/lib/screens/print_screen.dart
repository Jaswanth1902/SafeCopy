// ========================================
// MOBILE APP - PRINT SCREEN
// Allows user to request file printing
// ========================================

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/user_service.dart';
import '../services/api_service.dart';

// ========================================
// PRINT SCREEN
// ========================================

class PrintScreen extends StatefulWidget {
  final String fileId;

  const PrintScreen({Key? key, required this.fileId}) : super(key: key);

  @override
  State<PrintScreen> createState() => _PrintScreenState();
}

class _PrintScreenState extends State<PrintScreen> {
  final apiService = ApiService();
  final userService = UserService();

  Map<String, dynamic>? fileInfo;
  bool isLoading = true;
  bool isSubmitting = false;
  String? errorMessage;
  String? successMessage;

  // Print settings
  int numberOfCopies = 1;
  bool colorPrinting = true;
  String selectedPaperSize = 'A4';

  @override
  void initState() {
    super.initState();
    _loadFileInfo();
  }

  Future<void> _loadFileInfo() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final accessToken = await userService.getAccessToken();
      if (accessToken == null) {
        throw Exception('Not authenticated');
      }

      // Get file info from API
      final response = await http
          .get(
            Uri.parse('${apiService.apiBaseUrl}/api/print/${widget.fileId}'),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          fileInfo = data['file'];
          isLoading = false;
        });
      } else if (response.statusCode == 403) {
        throw Exception('You do not have permission to print this file');
      } else if (response.statusCode == 404) {
        throw Exception('File not found');
      } else {
        throw Exception('Failed to load file: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
      debugPrint('❌ Error loading file: $e');
    }
  }

  Future<void> _submitPrintJob() async {
    try {
      setState(() {
        isSubmitting = true;
        errorMessage = null;
        successMessage = null;
      });

      final accessToken = await userService.getAccessToken();
      if (accessToken == null) {
        throw Exception('Not authenticated');
      }

      final printPayload = {
        'file_id': widget.fileId,
        'copies': numberOfCopies,
        'color': colorPrinting,
        'paper_size': selectedPaperSize,
      };

      final response = await http
          .post(
            Uri.parse('${apiService.apiBaseUrl}/api/print/${widget.fileId}'),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(printPayload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          successMessage = 'Print job submitted successfully!';
          isSubmitting = false;
        });

        // Show success and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Print job submitted'),
            duration: Duration(seconds: 2),
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context);
        });
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Print job submission failed');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isSubmitting = false;
      });
      debugPrint('❌ Error submitting print job: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Print File'),
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
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // File info card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.insert_drive_file,
                                color: Colors.blue.shade600,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fileInfo?['file_name'] ?? 'Unknown File',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ID: ${widget.fileId.substring(0, 8)}...',
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Print settings
                  const Text(
                    'Print Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Number of copies
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Number of Copies'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              IconButton(
                                onPressed: numberOfCopies > 1
                                    ? () => setState(() => numberOfCopies--)
                                    : null,
                                icon: const Icon(Icons.remove),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    numberOfCopies.toString(),
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: numberOfCopies < 10
                                    ? () => setState(() => numberOfCopies++)
                                    : null,
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Paper size
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Paper Size'),
                          const SizedBox(height: 12),
                          DropdownButton<String>(
                            value: selectedPaperSize,
                            isExpanded: true,
                            items: ['A4', 'A3', 'Letter', 'Legal']
                                .map(
                                  (size) => DropdownMenuItem(
                                    value: size,
                                    child: Text(size),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => selectedPaperSize = value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Color printing
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Color Printing'),
                          Switch(
                            value: colorPrinting,
                            onChanged: (value) {
                              setState(() => colorPrinting = value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Success message
                  if (successMessage != null)
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
                            child: Text(
                              successMessage!,
                              style: TextStyle(color: Colors.green.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Submit button
                  ElevatedButton.icon(
                    onPressed: isSubmitting ? null : _submitPrintJob,
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.print),
                    label: const Text('Submit Print Job'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
