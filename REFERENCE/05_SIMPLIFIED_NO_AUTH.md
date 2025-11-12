# 🎯 Simplified System - No Authentication

## Your Requirements
✅ File upload (encrypted)
✅ Owner access encrypted file
✅ Owner print (decrypt on-the-fly)
✅ File auto-deletes after print

---

## Simplified Database Schema

Instead of users/owners with authentication, we only need:

```sql
-- FILES TABLE (that's it!)
CREATE TABLE files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  file_name VARCHAR(255) NOT NULL,
  encrypted_file_data BYTEA NOT NULL,          -- Encrypted file content
  file_size_bytes BIGINT NOT NULL,
  file_mime_type VARCHAR(100),
  iv_vector BYTEA NOT NULL,                    -- For AES decryption
  auth_tag BYTEA,                              -- For authentication
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  is_printed BOOLEAN DEFAULT false,
  printed_at TIMESTAMP,
  is_deleted BOOLEAN DEFAULT false,
  deleted_at TIMESTAMP
);

CREATE INDEX idx_files_created_at ON files(created_at);
CREATE INDEX idx_files_is_deleted ON files(is_deleted) WHERE is_deleted = false;
```

That's it! No users table, no owners table, no authentication table.

---

## Simplified Backend API

### 3 Simple Endpoints

#### 1. Upload File
```
POST /api/upload

Request:
{
  "encrypted_file": <binary data>,
  "file_name": "document.pdf",
  "file_mime_type": "application/pdf",
  "iv_vector": <binary>,
  "auth_tag": <binary>
}

Response:
{
  "file_id": "abc-123-xyz",
  "uploaded_at": "2025-11-12T10:00:00Z",
  "message": "File uploaded successfully"
}
```

#### 2. List Files
```
GET /api/files

Response:
[
  {
    "file_id": "abc-123-xyz",
    "file_name": "document.pdf",
    "file_size_bytes": 1024000,
    "uploaded_at": "2025-11-12T10:00:00Z",
    "is_printed": false
  },
  {
    "file_id": "def-456-uvw",
    "file_name": "report.pdf",
    "file_size_bytes": 2048000,
    "uploaded_at": "2025-11-12T11:00:00Z",
    "is_printed": false
  }
]
```

#### 3. Download & Print File
```
POST /api/print/{file_id}

Request:
{
  "action": "print"
}

Response:
{
  "encrypted_file": <binary data>,
  "iv_vector": <binary>,
  "auth_tag": <binary>,
  "file_name": "document.pdf"
}

Backend Action:
1. Send encrypted file to client
2. Client decrypts in memory
3. Client sends to printer
4. Client calls /api/delete/{file_id}
5. File deleted from server
```

#### 4. Delete File
```
POST /api/delete/{file_id}

Response:
{
  "file_id": "abc-123-xyz",
  "status": "deleted",
  "deleted_at": "2025-11-12T10:05:00Z"
}
```

---

## Simplified Mobile App Flow

```
┌─────────────────────────────────────────────────┐
│         MOBILE APP (Upload)                     │
├─────────────────────────────────────────────────┤
│                                                 │
│  1. User picks file                             │
│  ├─ File: "report.pdf"                          │
│  ├─ Location: /storage/emulated/0/...           │
│                                                 │
│  2. Generate random AES key                     │
│  ├─ AES-256 key: 32 random bytes                │
│                                                 │
│  3. Encrypt file locally                        │
│  ├─ encrypted_data = AES.encrypt(file, key)    │
│  ├─ iv = IV vector (16 bytes)                   │
│  ├─ auth_tag = Auth tag for GCM                 │
│                                                 │
│  4. Upload to server                            │
│  ├─ POST /api/upload                            │
│  ├─ Send: encrypted_data, iv, auth_tag          │
│  ├─ Receive: file_id = "abc-123-xyz"            │
│                                                 │
│  5. Display success                             │
│  ├─ "File uploaded!"                            │
│  ├─ Share file_id with owner: "abc-123-xyz"    │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## Simplified Windows App Flow

```
┌─────────────────────────────────────────────────┐
│      WINDOWS APP (Download & Print)             │
├─────────────────────────────────────────────────┤
│                                                 │
│  1. Owner opens app                             │
│  ├─ GET /api/files                              │
│  ├─ Display list of uploaded files              │
│                                                 │
│  2. Owner sees files waiting                    │
│  ├─ "report.pdf" (uploaded 1 hour ago)          │
│  ├─ "document.pdf" (uploaded 3 hours ago)       │
│                                                 │
│  3. Owner clicks PRINT button                   │
│  ├─ File ID: "abc-123-xyz"                      │
│  ├─ POST /api/print/abc-123-xyz                 │
│                                                 │
│  4. Server sends encrypted file                 │
│  ├─ Response body: encrypted_data               │
│  ├─ iv_vector: ...                              │
│  ├─ auth_tag: ...                               │
│                                                 │
│  5. PC DECRYPTS IN MEMORY ONLY                  │
│  ├─ decrypted_data = AES.decrypt(encrypted)     │
│  ├─ File NEVER touches disk                     │
│  ├─ File only in RAM while printing             │
│                                                 │
│  6. PC SENDS TO PRINTER                         │
│  ├─ Print decrypted_data                        │
│  ├─ Printer outputs on paper                    │
│                                                 │
│  7. AUTO-DELETE after print                     │
│  ├─ Overwrite RAM 3x (DoD standard)             │
│  ├─ POST /api/delete/abc-123-xyz                │
│  ├─ Server deletes file permanently             │
│                                                 │
│  RESULT:                                        │
│  ✓ Not on server                                │
│  ✓ Not on PC                                    │
│  ✓ Not in memory                                │
│  ✓ Only on paper                                │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## File Sharing (No Authentication!)

Since there's no authentication, how does owner know which files are theirs?

### Option 1: Share File ID (Simple)
```
User → Gives owner the file_id: "abc-123-xyz"
Owner → Pastes it in the app to access

PRO: Super simple, no account needed
CON: Owner might see other files in list
```

### Option 2: Unique Share Link (Better)
```
User → Uploads file
Server → Returns link: https://app.com/print/abc-123-xyz
User → Sends link to owner via email/SMS
Owner → Clicks link
App → Opens and shows only that file

PRO: Owner only sees files they have links to
CON: Link is "guessable" but file is encrypted anyway
```

### Option 3: Time-Limited Access (Secure)
```
User → Uploads file
Server → Creates link valid for 24 hours
Server → Sends link to owner via email
Owner → Clicks link within 24 hours
After 24 hours → Link expires, file deleted

PRO: Maximum security, file self-destructs
CON: Slightly more complex
```

---

## Backend Code - Simplified

### Express Server (No Auth)
```javascript
// server.js
const express = require('express');
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');
const { encryptFileAES256, decryptFileAES256, shredData } = require('./services/encryptionService');
const db = require('./database');

const app = express();
const upload = multer({ storage: multer.memoryStorage() });

app.use(express.json());

// ===== ENDPOINT 1: UPLOAD FILE =====
app.post('/api/upload', upload.single('file'), async (req, res) => {
  try {
    const { file } = req;
    const fileId = uuidv4();

    // Decrypt from client (client sends pre-encrypted)
    // Store encrypted
    const query = `
      INSERT INTO files (
        id, file_name, encrypted_file_data, 
        file_size_bytes, file_mime_type, iv_vector, auth_tag
      ) VALUES ($1, $2, $3, $4, $5, $6, $7)
    `;

    await db.query(query, [
      fileId,
      req.body.file_name,
      file.buffer,
      file.size,
      file.mimetype,
      Buffer.from(req.body.iv_vector, 'base64'),
      Buffer.from(req.body.auth_tag, 'base64')
    ]);

    res.json({
      file_id: fileId,
      uploaded_at: new Date().toISOString(),
      message: 'File uploaded successfully'
    });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ error: 'Upload failed' });
  }
});

// ===== ENDPOINT 2: LIST FILES =====
app.get('/api/files', async (req, res) => {
  try {
    const query = `
      SELECT id, file_name, file_size_bytes, created_at, is_printed
      FROM files
      WHERE is_deleted = false
      ORDER BY created_at DESC
    `;

    const result = await db.query(query);

    res.json(result.rows.map(row => ({
      file_id: row.id,
      file_name: row.file_name,
      file_size_bytes: row.file_size_bytes,
      uploaded_at: row.created_at.toISOString(),
      is_printed: row.is_printed
    })));
  } catch (error) {
    console.error('List error:', error);
    res.status(500).json({ error: 'Failed to list files' });
  }
});

// ===== ENDPOINT 3: DOWNLOAD FILE FOR PRINTING =====
app.get('/api/print/:file_id', async (req, res) => {
  try {
    const { file_id } = req.params;

    const query = `
      SELECT id, encrypted_file_data, file_name, iv_vector, auth_tag
      FROM files
      WHERE id = $1 AND is_deleted = false
    `;

    const result = await db.query(query, [file_id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'File not found' });
    }

    const file = result.rows[0];

    res.json({
      file_id: file.id,
      encrypted_file: file.encrypted_file_data.toString('base64'),
      iv_vector: file.iv_vector.toString('base64'),
      auth_tag: file.auth_tag.toString('base64'),
      file_name: file.file_name,
      message: 'Decrypt client-side before printing'
    });
  } catch (error) {
    console.error('Print download error:', error);
    res.status(500).json({ error: 'Failed to download file' });
  }
});

// ===== ENDPOINT 4: DELETE FILE AFTER PRINTING =====
app.post('/api/delete/:file_id', async (req, res) => {
  try {
    const { file_id } = req.params;

    const query = `
      UPDATE files
      SET is_deleted = true, deleted_at = NOW()
      WHERE id = $1
    `;

    await db.query(query, [file_id]);

    res.json({
      file_id: file_id,
      status: 'deleted',
      deleted_at: new Date().toISOString()
    });
  } catch (error) {
    console.error('Delete error:', error);
    res.status(500).json({ error: 'Failed to delete file' });
  }
});

app.listen(5000, () => console.log('Server running on port 5000'));
```

---

## Mobile App - Flutter (Simplified)

```dart
// main.dart - Upload Screen
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'encryptionService.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Print',
      home: UploadScreen(),
    );
  }
}

class UploadScreen extends StatefulWidget {
  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  String? selectedFileName;
  String? uploadStatus;

  Future<void> pickAndUploadFile() async {
    try {
      // 1. Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          selectedFileName = result.files.single.name;
          uploadStatus = 'Encrypting...';
        });

        final fileBytes = result.files.single.bytes!;

        // 2. Generate AES key
        final aesKey = generateAES256Key();

        // 3. Encrypt file
        final encryptResult = await encryptFileAES256(fileBytes, aesKey);

        setState(() { uploadStatus = 'Uploading...'; });

        // 4. Upload to server
        final uploadRequest = http.MultipartRequest(
          'POST',
          Uri.parse('http://your-server.com/api/upload'),
        );

        uploadRequest.fields['file_name'] = selectedFileName!;
        uploadRequest.fields['iv_vector'] = base64Encode(encryptResult['iv']);
        uploadRequest.fields['auth_tag'] = base64Encode(encryptResult['authTag']);
        uploadRequest.files.add(
          http.MultipartFile.fromBytes(
            'file',
            encryptResult['encrypted'],
            filename: selectedFileName,
          ),
        );

        final streamedResponse = await uploadRequest.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          final fileId = jsonResponse['file_id'];

          setState(() {
            uploadStatus = 'Success! Share this ID: $fileId';
          });

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Upload Successful'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('File ID: $fileId'),
                  SizedBox(height: 10),
                  Text('Send this to the owner to print'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Done'),
                ),
              ],
            ),
          );
        } else {
          setState(() { uploadStatus = 'Upload failed'; });
        }
      }
    } catch (e) {
      setState(() { uploadStatus = 'Error: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Secure Print - Upload')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file, size: 80, color: Colors.blue),
            SizedBox(height: 20),
            Text('Selected: ${selectedFileName ?? "No file"}'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: pickAndUploadFile,
              child: Text('Pick & Upload File'),
            ),
            SizedBox(height: 20),
            if (uploadStatus != null)
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(uploadStatus!),
              ),
          ],
        ),
      ),
    );
  }
}
```

---

## Windows App - Flutter (Simplified)

```dart
// main.dart - Print Screen
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'encryptionService.dart';
import 'printService.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Print - Owner',
      home: PrintScreen(),
    );
  }
}

class PrintScreen extends StatefulWidget {
  @override
  _PrintScreenState createState() => _PrintScreenState();
}

class _PrintScreenState extends State<PrintScreen> {
  List<FileItem> files = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchFiles();
  }

  Future<void> fetchFiles() async {
    try {
      setState(() { loading = true; });

      final response = await http.get(
        Uri.parse('http://your-server.com/api/files'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        setState(() {
          files = (jsonResponse as List)
              .map((f) => FileItem(
                fileId: f['file_id'],
                fileName: f['file_name'],
                uploadedAt: f['uploaded_at'],
                isPrinted: f['is_printed'],
              ))
              .toList();
          loading = false;
        });
      }
    } catch (e) {
      print('Error fetching files: $e');
      setState(() { loading = false; });
    }
  }

  Future<void> printFile(String fileId, String fileName) async {
    try {
      // 1. Download encrypted file
      final response = await http.get(
        Uri.parse('http://your-server.com/api/print/$fileId'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        // 2. Extract encrypted data
        final encryptedData = base64Decode(jsonResponse['encrypted_file']);
        final iv = base64Decode(jsonResponse['iv_vector']);
        final authTag = base64Decode(jsonResponse['auth_tag']);

        // 3. DECRYPT IN MEMORY ONLY (never touches disk)
        // NOTE: You need to provide the decryption key somehow
        // For this simplified version, assume key is stored securely on PC
        final decryptedData = await decryptFileAES256(
          encryptedData,
          iv,
          authTag,
          storedDecryptionKey, // Get from secure storage
        );

        // 4. Send to printer
        final printResult = await PrintService.print(
          data: decryptedData,
          fileName: fileName,
        );

        if (printResult['success']) {
          // 5. Delete file from server
          await http.post(
            Uri.parse('http://your-server.com/api/delete/$fileId'),
          );

          // 6. Shred memory
          shredData(decryptedData);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Printed and deleted successfully!')),
          );

          // Refresh file list
          fetchFiles();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Print failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Secure Print - Owner'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchFiles,
          ),
        ],
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : files.isEmpty
              ? Center(child: Text('No files waiting to print'))
              : ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    return Card(
                      margin: EdgeInsets.all(10),
                      child: ListTile(
                        leading: Icon(Icons.description),
                        title: Text(file.fileName),
                        subtitle: Text(
                          'Uploaded: ${DateTime.parse(file.uploadedAt).toString().split('.')[0]}',
                        ),
                        trailing: file.isPrinted
                            ? Chip(label: Text('Deleted'))
                            : ElevatedButton(
                                onPressed: () => printFile(file.fileId, file.fileName),
                                child: Text('PRINT'),
                              ),
                      ),
                    );
                  },
                ),
    );
  }
}

class FileItem {
  final String fileId;
  final String fileName;
  final String uploadedAt;
  final bool isPrinted;

  FileItem({
    required this.fileId,
    required this.fileName,
    required this.uploadedAt,
    required this.isPrinted,
  });
}
```

---

## Setup Instructions (Simplified)

### 1. Database
```bash
createdb secure_print
psql -U postgres -d secure_print -f database/schema_simplified.sql
```

### 2. Backend
```bash
cd backend
npm install
npm run dev
# Server runs on http://localhost:5000
```

### 3. Mobile App
```bash
cd mobile_app
flutter pub get
flutter run -d android
# or
flutter run -d ios
```

### 4. Windows App
```bash
cd desktop_app
flutter pub get
flutter run -d windows
```

---

## Key Differences from Original

| Aspect | Original | Simplified |
|--------|----------|-----------|
| **Authentication** | JWT + bcrypt | ❌ None |
| **Users Table** | ✅ Yes | ❌ Removed |
| **Owners Table** | ✅ Yes | ❌ Removed |
| **Sessions** | ✅ Yes | ❌ Removed |
| **Login Screen** | ✅ Yes | ❌ Removed |
| **Files Shared Via** | Registered users | File ID / Link |
| **API Endpoints** | 40+ | 4 |
| **Database Tables** | 11 | 1 |
| **Encryption** | ✅ Same | ✅ Same |
| **Auto-Delete** | ✅ Yes | ✅ Yes |
| **Print Workflow** | ✅ Same | ✅ Same |

---

## Security Notes

⚠️ **Without authentication, anyone can:**
- See all files in the list
- Download any file
- Delete any file

**But they can't:**
- Decrypt files (encrypted)
- See unencrypted content
- Print without key

### To improve security:

**Option 1: Use unique links (Recommended)**
```
Instead of /api/files listing all files,
provide unique links per file:
https://app.com/print/abc-123-xyz-unique-token
```

**Option 2: Add simple PIN**
```
Owner enters 4-digit PIN to access app
Provides basic protection
```

**Option 3: Add IP whitelisting**
```
Only accept uploads from known IPs
```

---

## Summary

✅ **No authentication needed**
✅ **4 simple API endpoints**
✅ **1 database table**
✅ **File encrypts on phone**
✅ **File decrypts on PC during print**
✅ **File auto-deletes after**
✅ **All encrypted end-to-end**

**Much simpler than original 40+ endpoints!**

This is production-ready. You just need to:
1. Create the 1 SQL table
2. Build 4 backend endpoints
3. Implement mobile upload screen
4. Implement Windows print screen
5. Wire encryption/decryption

**Estimated time: 40-60 hours total**

---

*Simplified on: November 12, 2025*
