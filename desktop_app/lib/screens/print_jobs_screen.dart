// ========================================
// PRINT JOBS SCREEN - DESKTOP APP
// Display pending print jobs for owner
// ========================================

import 'package:flutter/material.dart';
import '../services/owner_api_service.dart';

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
  List<PrintFile> jobs = [];
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

      setState(() {
        jobs = printJobs;
        isLoading = false;
      });
    } catch (e) {
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
      final fileData = await _apiService.getFileForPrinting(
        fileId: fileId,
        accessToken: widget.accessToken,
      );

      // TODO: Decrypt file using owner's private RSA key
      // TODO: Send to Windows printer
      // TODO: Call POST /api/delete/{fileId} after printing

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Print job submitted')));

      _loadPrintJobs();
    } catch (e) {
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File deleted')));

      _loadPrintJobs();
    } catch (e) {
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
            if (jobs.isEmpty)
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
                              job['name']!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Size: ${job['size']}'),
                            Text('Uploaded: ${job['uploadedAt']}'),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  onPressed: () => _handlePrintJob(job['id']!),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  child: const Text('Print'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => _handleDeleteJob(job['id']!),
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
