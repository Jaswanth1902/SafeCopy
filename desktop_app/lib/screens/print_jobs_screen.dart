// ========================================
// PRINT JOBS SCREEN - DESKTOP APP
// Display pending print jobs for owner
// ========================================

import 'package:flutter/material.dart';
import '../services/owner_api_service.dart';

// Typed model for print jobs to provide compile-time safety
class PrintJob {
  final String id;
  final String name;
  final String size;
  final String uploadedAt;

  PrintJob({
    required this.id,
    required this.name,
    required this.size,
    required this.uploadedAt,
  });

  factory PrintJob.fromJson(Map<String, dynamic> json) {
    return PrintJob(
      id: (json['id'] ?? json['file_id'] ?? '').toString(),
      name: (json['name'] ?? json['file_name'] ?? 'Unknown').toString(),
      size: (json['size'] ?? json['file_size'] ?? 'Unknown size').toString(),
      uploadedAt:
          (json['uploadedAt'] ?? json['uploaded_at'] ?? 'Unknown date').toString(),
    );
  }

  factory PrintJob.fromPrintFile(PrintFile pf) {
    return PrintJob(
      id: pf.fileId,
      name: pf.fileName,
      size: '',
      uploadedAt: pf.uploadedAt,
    );
  }
}

class PrintJobsScreen extends StatefulWidget {
  final String ownerId;
  final String accessToken;

  const PrintJobsScreen({
    Key? key,
    required this.ownerId,
    required this.accessToken,
  }) : super(key: key);

  @override
  State<PrintJobsScreen> createState() => _PrintJobsScreenState();
}

class _PrintJobsScreenState extends State<PrintJobsScreen> {
  final _apiService = OwnerApiService();
  List<PrintJob> jobs = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPrintJobs();
  }

  Future<void> _loadPrintJobs() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final printJobs = await _apiService.getPrintJobs(
        accessToken: widget.accessToken,
      );

      if (!context.mounted) return;

      // Normalize API result into typed PrintJob list
      final raw = List<dynamic>.from(printJobs);
      final parsed = raw.map<PrintJob>((item) {
        if (item is PrintFile) return PrintJob.fromPrintFile(item);
        if (item is Map<String, dynamic>) return PrintJob.fromJson(item);
        if (item is Map) return PrintJob.fromJson(Map<String, dynamic>.from(item));
        debugPrint('⚠️ Unexpected item type in print jobs: ${item.runtimeType}');
        throw FormatException('Unexpected item type in print jobs: ${item.runtimeType}, value: $item');
      }).toList();
      setState(() {
        jobs = parsed;
        isLoading = false;
      });
    } catch (e) {
      if (!context.mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
      debugPrint('❌ Error loading print jobs: $e');
    }
  }

  Future<void> _handlePrintJob(String fileId) async {
    try {
      // Get encrypted file
      await _apiService.getFileForPrinting(
        fileId: fileId,
        accessToken: widget.accessToken,
      );
      // Functionality pending: decryption, printing, and deletion
      // TODO: Implement file retrieval once decryption logic is added
      // TODO: Decrypt file using owner's private RSA key
      // TODO: Send to Windows printer
      // TODO: Call POST /api/delete/{fileId} after printing

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Print feature coming soon')));

      _loadPrintJobs();
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _handleDeleteJob(String fileId) async {
    try {
      await _apiService.deleteFile(
        fileId: fileId,
        accessToken: widget.accessToken,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File deleted')));

      _loadPrintJobs();
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Print Jobs'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (errorMessage != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $errorMessage'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPrintJobs,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (jobs.isEmpty)
              const Expanded(child: Center(child: Text('No pending jobs')))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Size: ${job.size}'),
                            Text('Uploaded: ${job.uploadedAt}'),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  onPressed: job.id.isNotEmpty ? () => _handlePrintJob(job.id) : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  child: const Text('Print'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: job.id.isNotEmpty ? () => _handleDeleteJob(job.id) : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
