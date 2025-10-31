import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safe Copy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Safe Copy File Upload'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<void> uploadFile() async {
    print("📱 Starting file picker...");
    final result = await FilePicker.platform.pickFiles();
    if (result == null) {
      print("❌ No file selected");
      return;
    }

    print("📂 File selected: ${result.files.single.name}");
    final file = File(result.files.single.path!);

    // Using the computer's IP address
    final uri = Uri.parse("http://10.238.112.65:5000/upload");
    print("🌐 Uploading to: $uri");

    try {
      var request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      print("📤 Sending request...");
      var response = await request.send();

      if (response.statusCode == 200) {
        print("✅ Upload successful!");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ File uploaded successfully")),
          );
        }
      } else {
        print("❌ Upload failed with status: ${response.statusCode}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Upload failed: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      print("❌ Error during upload: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Upload error: $e")),
        );
      }
    }
  }

  // Server base URL — adjust if the Flask server is on another machine
  final String serverBase = "http://127.0.0.1:5000";

  Future<List<String>> fetchFileList() async {
    try {
      final uri = Uri.parse('$serverBase/files');
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        // Decode a simple JSON map {"files": [...]} without adding extra deps
        final body = resp.body;
        // crude parsing to avoid importing dart:convert for this small app
        final filesStart = body.indexOf('[');
        final filesEnd = body.indexOf(']');
        if (filesStart != -1 && filesEnd != -1 && filesEnd > filesStart) {
          final listContent = body.substring(filesStart + 1, filesEnd);
          if (listContent.trim().isEmpty) return [];
          final parts = listContent.split(',').map((s) {
            return s.trim().replaceAll('"', '').replaceAll("'", '');
          }).toList();
          return parts.map((p) => p.trim()).toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ Error fetching file list: $e');
      return [];
    }
  }

  Future<void> downloadFile(String filename) async {
    try {
      final uri =
          Uri.parse('$serverBase/files/${Uri.encodeComponent(filename)}');
      print('⬇️ Downloading from $uri');
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        String downloadsDir;
        if (Platform.isWindows) {
          final user = Platform.environment['USERPROFILE'] ?? '';
          downloadsDir = '$user\\Downloads';
        } else {
          downloadsDir = Directory.systemTemp.path;
        }

        final outPath = '$downloadsDir\\$filename';
        final outFile = File(outPath);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(resp.bodyBytes);
        print('✅ Saved to $outPath');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Saved to $outPath')),
          );
        }
      } else {
        print('❌ Download failed: ${resp.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Download failed: ${resp.statusCode}')),
          );
        }
      }
    } catch (e) {
      print('❌ Error downloading file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error downloading: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Upload to server or download files from the server:',
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: uploadFile,
              child: const Text('Upload File'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final files = await fetchFileList();
                if (files.isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('No files available on server')),
                    );
                  }
                  return;
                }

                // Show a dialog to pick a file to download
                showDialog(
                    context: context,
                    builder: (ctx) {
                      return SimpleDialog(
                        title: const Text('Files on server'),
                        children: files
                            .map((f) => SimpleDialogOption(
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    downloadFile(f);
                                  },
                                  child: Text(f),
                                ))
                            .toList(),
                      );
                    });
              },
              child: const Text('Download From Server'),
            ),
          ],
        ),
      ),
    );
  }
}
