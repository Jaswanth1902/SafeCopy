# PHASE 2 QUICK TEST GUIDE

## What You Can Test Right Now ✅

Phase 2 is now **100% complete** and ready for testing. Here's what's been built:

### Three New/Updated Files:

1. **`mobile_app/lib/services/encryption_service.dart`** (168 lines)
   - AES-256-GCM encryption for files
   - Key generation, IV vectors, auth tags
   - Secure memory shredding
   - Round-trip encryption verification

2. **`mobile_app/lib/screens/upload_screen.dart`** (769 lines)
   - Complete Flutter upload UI
   - File picker integration
   - Encryption progress tracking
   - Upload progress bars
   - Success/error dialogs
   - Retry logic

3. **`mobile_app/lib/main.dart`** (Updated)
   - Connected UploadPage to real UploadScreen
   - Injected EncryptionService and ApiService
   - Now uses Provider pattern for services

### End-to-End Flow

```
File Selection (FilePicker)
         ↓
    Encrypt (AES-256-GCM)
         ↓
    Upload (Multipart POST)
         ↓
Backend Storage (PostgreSQL)
         ↓
Return file_id (Success Dialog)
```

## Before You Test

### 1. Database Setup
```bash
# Create PostgreSQL database
psql -U postgres -c "CREATE DATABASE secure_print_db;"

# Deploy schema
psql -U postgres -d secure_print_db < database/schema_simplified.sql

# Verify
psql -U postgres -d secure_print_db -c "SELECT * FROM files LIMIT 1;"
```

### 2. Backend Setup
```bash
cd backend
npm install  # if needed
node server.js
# Should see: "Server running on port 5000"
```

### 3. Mobile App Dependencies
```bash
cd mobile_app
flutter pub get
```

## How to Test

### Test 1: Basic Encryption
Test that AES-256-GCM encryption works locally.

```dart
// In Flutter app, add this temporary test code:
import 'services/encryption_service.dart';

void testEncryption() async {
  final service = EncryptionService();
  
  // Generate key
  final key = service.generateAES256Key();
  print('✅ Key generated: ${key.length} bytes');
  
  // Test data
  final testData = Uint8List.fromList('Hello World'.codeUnits);
  
  // Encrypt
  final encrypted = await service.encryptFileAES256(testData, key);
  print('✅ Encrypted: ${encrypted['encrypted'].toString().substring(0, 20)}...');
  
  // Decrypt
  final decrypted = await service.decryptFileAES256(
    encrypted['encrypted'],
    encrypted['iv'],
    encrypted['authTag'],
    key,
  );
  print('✅ Decrypted: ${String.fromCharCodes(decrypted)}');
  
  // Verify
  final verified = await service.verifyEncryption(testData, encrypted);
  print('✅ Verified: $verified');
}
```

### Test 2: File Upload Flow
Test the complete mobile app upload.

```bash
# 1. Start Flutter app
cd mobile_app
flutter run

# 2. In app:
#    - Tap "Upload" tab
#    - Tap "Select File" button
#    - Choose a small file (~1-5MB)
#    - Tap "Encrypt & Upload"

# 3. Watch for:
#    ✅ File selected message
#    ✅ Encryption progress (should be fast)
#    ✅ Upload progress bar
#    ✅ Success dialog with file_id
#    ✅ file_id appears in dialog

# 4. Verify in database:
psql -U postgres -d secure_print_db
SELECT id, file_name, file_size_bytes, is_printed FROM files;
# Should show: your uploaded file with is_printed = false
```

### Test 3: Backend Verification
Test that backend received encrypted data correctly.

```bash
# Query the database
psql -U postgres -d secure_print_db

# Check uploaded files
SELECT 
  id,
  file_name,
  file_size_bytes,
  LENGTH(encrypted_file_data) as encrypted_size,
  LENGTH(iv_vector) as iv_size,
  LENGTH(auth_tag) as tag_size,
  created_at
FROM files
ORDER BY created_at DESC
LIMIT 5;

# Expected output:
#  - encrypted_size: much larger than original (with padding)
#  - iv_size: exactly 16 bytes
#  - tag_size: exactly 16 bytes
```

### Test 4: Error Handling
Test error scenarios.

```bash
# Test 1: Backend offline
# 1. Stop backend server (Ctrl+C)
# 2. Try uploading file in app
# 3. Should see error: "Connection refused" or similar
# 4. Tap "Retry" button

# Test 2: No file selected
# 1. Tap "Encrypt & Upload" without selecting file
# 2. Should see: "Please select a file first"

# Test 3: Very large file
# 1. Select large file (>100MB)
# 2. May see timeout error
# 3. This is expected (needs timeout config in Phase 3)
```

## Expected Results ✅

### File Upload Success
```
🎉 SUCCESS!

file_id: 550e8400-e29b-41d4-a716-446655440000
file_name: my_document.pdf
status: Encrypted and uploaded successfully

[Copy File ID]  [Close]
```

### Database Verification
```sql
  id          |   file_name   | file_size_bytes | is_printed
-|-|-|-
 550e8400... | my_document.pdf |  50000        | f
```

### Logs (should see)
```
🔐 Starting encryption...
✅ AES key generated
✅ File encrypted
📤 Uploading to: http://localhost:5000/api/upload
   File: my_document.pdf (50000 bytes)
✅ Upload complete
🎉 File uploaded with ID: 550e8400...
```

## Troubleshooting

### Issue: "Connection refused"
**Cause:** Backend not running
**Fix:** 
```bash
cd backend
node server.js
```

### Issue: "Database error"
**Cause:** PostgreSQL not running or schema not deployed
**Fix:**
```bash
# Start PostgreSQL
# Then:
psql -U postgres -d secure_print_db < database/schema_simplified.sql
```

### Issue: File picker doesn't open
**Cause:** Permissions not granted
**Fix:**
1. Settings → Apps → MyApp → Permissions
2. Enable "Files and Media"
3. Restart app

### Issue: Encryption very slow
**Cause:** Large file or weak device
**Fix:**
- Normal for 50MB+ files
- Test with smaller files first
- Try on faster device/simulator

### Issue: "Unsupported media type" error
**Cause:** MIME type detection failed
**Fix:**
- App adds default MIME type
- Should still work
- Choose common file type (.pdf, .txt, .jpg)

## Next Steps (Phase 3)

Once Phase 2 testing is verified:

### Windows Print App
1. Create `owner_app/lib/screens/print_screen.dart`
2. Display list of files from `/api/files`
3. Download and decrypt in memory
4. Print to Windows printer
5. Delete file after printing
6. Auto-delete after 24 hours (configurable)

**Estimated Time:** 6-8 hours

## Quick Status Summary

| Component | Status | Lines |
|-----------|--------|-------|
| Encryption Service | ✅ Complete | 168 |
| Upload Screen | ✅ Complete | 769 |
| API Service | ✅ Complete | 300+ |
| Main Integration | ✅ Complete | Updated |
| **Total** | **✅ READY** | **1,200+** |

**Phase 2 is COMPLETE and READY FOR TESTING!**

Need help? Check the detailed documentation in `PHASE_2_MOBILE_UPLOAD_COMPLETE.md`
