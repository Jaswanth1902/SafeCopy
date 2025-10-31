import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final serverBase = 'http://127.0.0.1:5000';
  try {
    final listUri = Uri.parse('$serverBase/files');
    print('Fetching file list from $listUri');
    final resp = await http.get(listUri);
    if (resp.statusCode != 200) {
      print('Failed to fetch file list: ${resp.statusCode}');
      return;
    }

    final Map<String, dynamic> body = jsonDecode(resp.body);
    final List files = body['files'] ?? [];

    if (files.isEmpty) {
      print('No files available on server.');
      return;
    }

    print('Files on server:');
    for (var i = 0; i < files.length; i++) {
      print('  [$i] ${files[i]}');
    }

    final filename = files.first.toString();
    print('\nDownloading first file: $filename');

    final downloadUri =
        Uri.parse('$serverBase/files/${Uri.encodeComponent(filename)}');
    final dresp = await http.get(downloadUri);
    if (dresp.statusCode != 200) {
      print('Download failed: ${dresp.statusCode}');
      return;
    }

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
    await outFile.writeAsBytes(dresp.bodyBytes);

    print('Saved file to: $outPath');
  } catch (e, st) {
    print('Error: $e');
    print(st);
  }
}
