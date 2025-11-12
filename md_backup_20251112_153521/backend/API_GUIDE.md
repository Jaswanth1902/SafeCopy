# 🚀 Backend API Setup & Testing Guide

## Overview

Your backend now has **4 production-ready API endpoints**:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/upload` | POST | Upload encrypted file from mobile app |
| `/api/files` | GET | List all files waiting to print |
| `/api/print/:file_id` | GET | Download encrypted file for printing |
| `/api/delete/:file_id` | POST | Delete file after printing |

---

## Step 1: Install Dependencies

```bash
cd backend
npm install
```

**Packages installed:**
- `express` - Web server
- `postgres` (pg) - Database connection
- `multer` - File upload handling
- `uuid` - Generate unique file IDs
- `dotenv` - Environment variables
- `cors` - Cross-origin requests
- `helmet` - Security headers
- `compression` - Response compression

---

## Step 2: Create Database

### Option A: Using PostgreSQL CLI (Recommended)

```bash
# Create database
createdb secure_print

# Load schema
psql -U postgres -d secure_print -f database/schema_simplified.sql
```

### Option B: Using pgAdmin GUI

1. Open pgAdmin
2. Right-click Databases → Create → Database
3. Name: `secure_print`
4. Click Create
5. Open Query Tool
6. Copy-paste contents of `database/schema_simplified.sql`
7. Click Execute

### Option C: Using Docker (Optional)

```bash
# Run PostgreSQL in Docker
docker run --name secure-print-db \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=secure_print \
  -p 5432:5432 \
  -d postgres:latest

# Then load schema
psql -h localhost -U postgres -d secure_print -f database/schema_simplified.sql
```

---

## Step 3: Configure Environment Variables

Create `.env` file in `backend/` directory:

```bash
# Server Configuration
NODE_ENV=development
PORT=5000

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=secure_print

# CORS Configuration
CORS_ORIGIN=http://localhost:3000

# File Upload Limits
MAX_FILE_SIZE=524288000  # 500MB
```

---

## Step 4: Start Backend Server

```bash
# Development mode (with auto-restart)
npm run dev

# OR Production mode
npm start
```

**Expected output:**
```
==================================================
Secure File Printing System - API Server
Server running on http://localhost:5000
Environment: development
==================================================
```

---

## Step 5: Test the Endpoints

### Test 1: Health Check

```bash
curl http://localhost:5000/health
```

**Expected response:**
```json
{
  "status": "OK",
  "timestamp": "2025-11-12T10:00:00.000Z",
  "environment": "development"
}
```

### Test 2: List Files (Empty)

```bash
curl http://localhost:5000/api/files
```

**Expected response:**
```json
{
  "success": true,
  "count": 0,
  "files": [],
  "message": "0 file(s) waiting to be printed"
}
```

### Test 3: Upload Encrypted File

You need to upload an encrypted file. Here's how:

#### Step A: Create a test encrypted file

First, generate test encryption data:

```bash
node -e "
const crypto = require('crypto');

// Generate test data
const key = crypto.randomBytes(32);  // AES-256 key
const iv = crypto.randomBytes(16);   // IV
const testData = Buffer.from('Hello, World!');

// Encrypt
const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
let encrypted = cipher.update(testData);
encrypted = Buffer.concat([encrypted, cipher.final()]);
const authTag = cipher.getAuthTag();

console.log('Key (hex):', key.toString('hex'));
console.log('IV (base64):', iv.toString('base64'));
console.log('Auth Tag (base64):', authTag.toString('base64'));
console.log('Encrypted Data (base64):', encrypted.toString('base64'));
"
```

This will output something like:
```
Key (hex): abc123...
IV (base64): aBcDeF1234...
Auth Tag (base64): xYz789...
Encrypted Data (base64): qWe456...
```

#### Step B: Use Postman to upload

1. **Import collection:**
   - Open Postman
   - Click Import
   - Select `Secure_File_Print_API.postman_collection.json`
   - Click Import

2. **Use the Upload request:**
   - Click "Upload File (Encrypted)" request
   - Go to Body tab
   - For "file": Click "Select Files" and pick any binary file
   - For "file_name": Enter `document.pdf`
   - For "iv_vector": Paste the IV (base64) from above
   - For "auth_tag": Paste the Auth Tag (base64) from above
   - Click Send

**Expected response:**
```json
{
  "success": true,
  "file_id": "550e8400-e29b-41d4-a716-446655440000",
  "file_name": "document.pdf",
  "file_size_bytes": 13,
  "uploaded_at": "2025-11-12T10:05:00.000Z",
  "message": "File uploaded successfully. Share the file_id with the owner."
}
```

### Test 4: List Files (With Data)

```bash
curl http://localhost:5000/api/files
```

**Expected response:**
```json
{
  "success": true,
  "count": 1,
  "files": [
    {
      "file_id": "550e8400-e29b-41d4-a716-446655440000",
      "file_name": "document.pdf",
      "file_size_bytes": 13,
      "uploaded_at": "2025-11-12T10:05:00.000Z",
      "is_printed": false,
      "printed_at": null,
      "status": "WAITING_TO_PRINT"
    }
  ],
  "message": "1 file(s) waiting to be printed"
}
```

### Test 5: Download File for Printing

```bash
curl http://localhost:5000/api/print/550e8400-e29b-41d4-a716-446655440000
```

**Expected response:**
```json
{
  "success": true,
  "file_id": "550e8400-e29b-41d4-a716-446655440000",
  "file_name": "document.pdf",
  "file_size_bytes": 13,
  "uploaded_at": "2025-11-12T10:05:00.000Z",
  "is_printed": false,
  "encrypted_file_data": "base64-encoded-encrypted-data",
  "iv_vector": "aBcDeF1234...",
  "auth_tag": "xYz789...",
  "message": "Decrypt this file on your PC before printing",
  "decryption_instructions": { ... }
}
```

### Test 6: Delete File After Printing

```bash
curl -X POST http://localhost:5000/api/delete/550e8400-e29b-41d4-a716-446655440000
```

**Expected response:**
```json
{
  "success": true,
  "file_id": "550e8400-e29b-41d4-a716-446655440000",
  "file_name": "document.pdf",
  "status": "DELETED",
  "deleted_at": "2025-11-12T10:10:00.000Z",
  "message": "File has been permanently deleted from server"
}
```

### Test 7: Verify File is Deleted

```bash
curl http://localhost:5000/api/files
```

**Expected response:**
```json
{
  "success": true,
  "count": 0,
  "files": [],
  "message": "0 file(s) waiting to be printed"
}
```

---

## API Documentation

### 1. POST /api/upload

**Upload encrypted file from mobile app**

**Request:**
```
POST /api/upload
Content-Type: multipart/form-data

form-data:
  - file: <binary encrypted file>
  - file_name: "document.pdf"
  - iv_vector: "base64-encoded-iv"
  - auth_tag: "base64-encoded-auth-tag"
```

**Response (201 Created):**
```json
{
  "success": true,
  "file_id": "uuid",
  "file_name": "document.pdf",
  "file_size_bytes": 1024,
  "uploaded_at": "2025-11-12T10:00:00.000Z",
  "message": "File uploaded successfully..."
}
```

**Error Response (400):**
```json
{
  "error": "No file provided"
}
```

---

### 2. GET /api/files

**List all files waiting to print**

**Request:**
```
GET /api/files
Accept: application/json
```

**Response (200 OK):**
```json
{
  "success": true,
  "count": 2,
  "files": [
    {
      "file_id": "uuid-1",
      "file_name": "document.pdf",
      "file_size_bytes": 1024,
      "uploaded_at": "2025-11-12T10:00:00.000Z",
      "is_printed": false,
      "printed_at": null,
      "status": "WAITING_TO_PRINT"
    },
    {
      "file_id": "uuid-2",
      "file_name": "report.docx",
      "file_size_bytes": 2048,
      "uploaded_at": "2025-11-12T10:30:00.000Z",
      "is_printed": true,
      "printed_at": "2025-11-12T10:35:00.000Z",
      "status": "PRINTED_AND_DELETED"
    }
  ],
  "message": "2 file(s) waiting to be printed"
}
```

---

### 3. GET /api/print/:file_id

**Download encrypted file for printing**

**Request:**
```
GET /api/print/550e8400-e29b-41d4-a716-446655440000
Accept: application/json
```

**Response (200 OK):**
```json
{
  "success": true,
  "file_id": "uuid",
  "file_name": "document.pdf",
  "file_size_bytes": 1024,
  "uploaded_at": "2025-11-12T10:00:00.000Z",
  "is_printed": false,
  "encrypted_file_data": "base64-encoded-encrypted-binary-data",
  "iv_vector": "base64-encoded-iv",
  "auth_tag": "base64-encoded-auth-tag",
  "message": "Decrypt this file on your PC before printing",
  "decryption_instructions": {
    "step1": "Receive the encrypted_file_data, iv_vector, and auth_tag",
    "step2": "You must have the decryption key (shared by uploader)",
    "step3": "Call decryptFileAES256(...)",
    "step4": "Decryption happens ONLY in memory",
    "step5": "Send decrypted data to printer",
    "step6": "Call DELETE /api/delete/{file_id}"
  }
}
```

**Error Response (404):**
```json
{
  "error": true,
  "message": "File not found or already deleted",
  "file_id": "uuid"
}
```

---

### 4. POST /api/delete/:file_id

**Delete file after printing**

**Request:**
```
POST /api/delete/550e8400-e29b-41d4-a716-446655440000
Content-Type: application/json
```

**Response (200 OK):**
```json
{
  "success": true,
  "file_id": "uuid",
  "file_name": "document.pdf",
  "status": "DELETED",
  "deleted_at": "2025-11-12T10:10:00.000Z",
  "message": "File has been permanently deleted from server"
}
```

**Error Response (404):**
```json
{
  "error": true,
  "message": "File not found",
  "file_id": "uuid"
}
```

---

## Troubleshooting

### Issue: "Cannot find module 'pg'"

**Solution:**
```bash
cd backend
npm install
```

### Issue: "ECONNREFUSED - Database connection failed"

**Solution:**
```bash
# Check if PostgreSQL is running
# On Windows:
net start postgresql-x64-15

# On Mac:
brew services start postgresql

# On Linux:
sudo systemctl start postgresql
```

Then check connection:
```bash
psql -U postgres -d secure_print -c "SELECT COUNT(*) FROM files;"
```

### Issue: "Table 'files' does not exist"

**Solution:**
```bash
# Load schema
psql -U postgres -d secure_print -f database/schema_simplified.sql

# Verify
psql -U postgres -d secure_print -c "\dt"
```

### Issue: "File upload returns 400 error"

**Solution:**
Ensure you're sending:
- `file` (binary data)
- `file_name` (string)
- `iv_vector` (base64 string)
- `auth_tag` (base64 string)

All 4 fields are required!

---

## Next Steps

✅ **Backend endpoints are complete and tested!**

Now you need to:

1. **Create Mobile App Upload Screen** (Phase 2)
   - File picker integration
   - Encryption integration
   - HTTP upload to `/api/upload`

2. **Create Windows App Print Screen** (Phase 3)
   - List files from `/api/files`
   - Download from `/api/print/:id`
   - Decrypt and print
   - Delete via `/api/delete/:id`

---

## Quick Reference

**Start server:**
```bash
cd backend && npm run dev
```

**Create database:**
```bash
createdb secure_print && psql -U postgres -d secure_print -f database/schema_simplified.sql
```

**Test health:**
```bash
curl http://localhost:5000/health
```

**Test list files:**
```bash
curl http://localhost:5000/api/files
```

**Import Postman collection:**
- File: `Secure_File_Print_API.postman_collection.json`
- Use pre-built requests for all 4 endpoints

---

## Production Deployment

When deploying to production:

1. Set `NODE_ENV=production`
2. Use environment-specific `.env` file
3. Enable HTTPS (TLS 1.3)
4. Set up proper database backups
5. Use reverse proxy (nginx, Apache)
6. Enable rate limiting
7. Use secrets management service

See `DEPLOYMENT.md` for details.

---

**Status: Backend API Complete ✅**

**Next: Build mobile app upload screen or Windows app print screen?**
