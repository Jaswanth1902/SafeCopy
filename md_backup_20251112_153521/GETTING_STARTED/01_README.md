# Secure File Printing System - Complete Project Guide

## 📋 Project Overview

This is a comprehensive secure file printing application that protects user privacy through:
- **Client-side encryption** before file transmission
- **Encrypted storage** on the server
- **Owner-side decryption** only during printing
- **Automatic file deletion** after print completion

### Core Principles
1. **User Privacy**: Files never exist in plaintext except on the user's device
2. **Owner Protection**: Prevents owner from storing or viewing unencrypted files
3. **Automatic Cleanup**: Files are automatically deleted after printing
4. **Audit Trail**: Complete logging of all actions

---

## 📁 Project Structure

```
SecureFilePrintSystem/
├── ARCHITECTURE.md              # Detailed system architecture
├── SETUP.md                     # Quick start guide
├── README.md                    # This file
│
├── backend/                     # Node.js Express API Server
│   ├── server.js               # Main server file
│   ├── package.json            # Dependencies
│   ├── middleware/
│   │   └── auth.js            # Authentication middleware
│   ├── services/
│   │   ├── authService.js     # JWT & password utilities
│   │   └── encryptionService.js # AES-256 & RSA encryption
│   ├── routes/                 # API endpoint routes (to be created)
│   ├── controllers/            # Business logic (to be created)
│   ├── models/                 # Database models (to be created)
│   └── README.md              # Backend documentation
│
├── database/
│   ├── schema.sql             # PostgreSQL schema with all tables
│   └── migrations/            # Database migrations
│
├── mobile_app/                 # Flutter User Mobile App
│   ├── lib/
│   │   ├── main.dart          # App entry point
│   │   ├── models/            # Data models
│   │   ├── screens/           # UI screens
│   │   ├── services/          # Business logic
│   │   └── widgets/           # Reusable widgets
│   └── pubspec.yaml           # Dependencies
│
├── desktop_app/                # Flutter Owner Windows App
│   ├── lib/
│   │   ├── main.dart          # App entry point
│   │   ├── models/            # Data models
│   │   ├── screens/           # UI screens
│   │   ├── services/          # Business logic
│   │   └── widgets/           # Reusable widgets
│   ├── windows/               # Windows-specific code
│   └── pubspec.yaml           # Dependencies
│
└── docs/                       # Additional documentation
    ├── API.md                 # API documentation
    ├── SECURITY.md            # Security guidelines
    ├── DEPLOYMENT.md          # Deployment guide
    └── TROUBLESHOOTING.md     # Common issues & solutions
```

---

## 🔐 Security Architecture

### Encryption Flow

**User Side (Uploading File)**
```
User selects file
       ↓
Generate random AES-256 key
       ↓
Encrypt file with AES-256-GCM
       ↓
Encrypt symmetric key with owner's RSA public key
       ↓
Send encrypted file + encrypted key to server
```

**Server Side (Storing File)**
```
Receive encrypted data
       ↓
Authenticate user
       ↓
Store encrypted file & encrypted key (separate)
       ↓
Create print job record
       ↓
Send job confirmation to user
```

**Owner Side (Printing File)**
```
Retrieve pending print job
       ↓
Download encrypted file & encrypted key
       ↓
Decrypt symmetric key using owner's RSA private key
       ↓
Decrypt file using symmetric key
       ↓
Send to printer
       ↓
Request server to delete file
       ↓
Server shreds and deletes all data
```

### Key Cryptographic Standards
- **File Encryption**: AES-256-GCM (256-bit key, 128-bit IV)
- **Key Encryption**: RSA-2048 with OAEP padding
- **Password Hashing**: bcrypt with 10 salt rounds
- **Authentication**: JWT-HS256
- **Integrity**: HMAC-SHA256

---

## 🚀 Quick Start

### 1. Prerequisites
```bash
Node.js 18+
Flutter 3.0+
PostgreSQL 14+
Git
VS Code or Android Studio
```

### 2. Database Setup
```bash
createdb secure_print
psql -U postgres -d secure_print -f database/schema.sql
```

### 3. Backend Setup
```bash
cd backend
npm install
cp .env.example .env
# Edit .env with your configuration
npm run dev
```

### 4. Mobile App Setup
```bash
cd mobile_app
flutter pub get
flutter run -d <device_id>
```

### 5. Desktop App Setup
```bash
cd desktop_app
flutter pub get
flutter run -d windows
```

---

## 📡 API Endpoints

### Authentication

#### User Registration
```http
POST /api/users/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "full_name": "John Doe"
}

Response:
{
  "statusCode": 201,
  "data": {
    "userId": "uuid",
    "email": "user@example.com",
    "token": "jwt_token",
    "refreshToken": "refresh_token"
  }
}
```

#### Owner Registration
```http
POST /api/owners/register
Content-Type: application/json

{
  "email": "owner@printshop.com",
  "password": "SecurePass123!",
  "full_name": "Print Shop Owner",
  "public_key": "-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----"
}
```

### File Operations

#### Upload Encrypted File
```http
POST /api/files/upload
Authorization: Bearer {token}
Content-Type: multipart/form-data

{
  "encryptedFile": <binary>,
  "encryptedSymmetricKey": <binary>,
  "fileName": "document.pdf",
  "fileSize": 1024,
  "ownerId": "owner_uuid"
}

Response:
{
  "statusCode": 201,
  "data": {
    "jobId": "job_uuid",
    "status": "PENDING",
    "createdAt": "2025-11-12T10:00:00Z"
  }
}
```

#### Download Encrypted File (Owner)
```http
GET /api/files/{fileId}
Authorization: Bearer {owner_token}

Response:
{
  "statusCode": 200,
  "data": {
    "encryptedFile": <binary>,
    "encryptedSymmetricKey": <binary>,
    "fileName": "document.pdf"
  }
}
```

### Print Jobs

#### Get Pending Jobs (Owner)
```http
GET /api/owners/jobs/pending
Authorization: Bearer {owner_token}

Response:
{
  "statusCode": 200,
  "data": [
    {
      "jobId": "job_uuid",
      "fileName": "document.pdf",
      "fileSize": 1024,
      "userId": "user_uuid",
      "createdAt": "2025-11-12T10:00:00Z"
    }
  ]
}
```

#### Complete Print Job
```http
POST /api/owners/jobs/{jobId}/complete
Authorization: Bearer {owner_token}
Content-Type: application/json

{
  "printerName": "HP LaserJet Pro",
  "pagesPrinted": 5
}

Response:
{
  "statusCode": 200,
  "data": {
    "jobId": "job_uuid",
    "status": "COMPLETED",
    "completedAt": "2025-11-12T10:05:00Z"
  }
}
```

---

## 🛠️ Development Workflow

### Adding a New Feature

1. **Backend**
   - Update database schema if needed
   - Create database migration
   - Create API route/controller
   - Add authentication/validation
   - Write tests

2. **Mobile App**
   - Create UI screen
   - Add data model
   - Create API service
   - Implement encryption logic
   - Add tests

3. **Desktop App**
   - Create UI screen
   - Add data model
   - Create API service
   - Implement decryption logic
   - Add tests

### Code Style Guidelines

**Backend (JavaScript)**
```javascript
// Use async/await
async function processFile(file) {
  try {
    const result = await encryptFile(file);
    return result;
  } catch (error) {
    logger.error('File processing failed', error);
    throw new Error('Processing failed');
  }
}

// Use const for constants
const AES_KEY_SIZE = 256;

// Use descriptive function names
function hashFileForIntegrity(fileData) { }
```

**Flutter (Dart)**
```dart
// Use async/await
Future<String> uploadEncryptedFile(File file) async {
  try {
    final response = await apiService.post('/files/upload', file);
    return response.jobId;
  } catch (e) {
    log('Upload failed: $e');
    rethrow;
  }
}

// Use final for constants
final kAesKeySize = 256;
```

---

## 🧪 Testing

### Backend Tests
```bash
cd backend
npm test
npm run test:watch
npm test -- --coverage
```

### Flutter Tests
```bash
cd mobile_app
flutter test
flutter test --coverage

cd desktop_app
flutter test
```

---

## 📦 Deployment

### Development
- Local Node.js server on port 5000
- Local PostgreSQL database
- Flutter dev builds

### Staging
- Cloud VPS (AWS EC2, Azure VM, etc.)
- Managed database (AWS RDS, Azure SQL)
- Staging certificates (Let's Encrypt)

### Production
- Load-balanced API servers
- Managed database with backups
- CDN for static assets
- SSL/TLS certificates
- Monitoring and alerting

See `docs/DEPLOYMENT.md` for detailed deployment guide.

---

## 🔒 Security Checklist

### Development
- [ ] All passwords hashed with bcrypt
- [ ] JWT secrets strong (32+ characters)
- [ ] Database connection encrypted
- [ ] HTTPS enabled locally with self-signed certs
- [ ] No hardcoded secrets
- [ ] Rate limiting configured
- [ ] Input validation on all endpoints
- [ ] CORS properly configured

### Before Production
- [ ] Security audit completed
- [ ] All dependencies updated and scanned
- [ ] Penetration testing done
- [ ] SSL/TLS certificates installed
- [ ] Database backups automated
- [ ] Monitoring and alerting configured
- [ ] Incident response plan created
- [ ] Compliance requirements met (GDPR, etc.)

---

## 📊 Database Schema Overview

### Main Tables
- **users**: User accounts
- **owners**: Printer operator accounts
- **files**: Encrypted file storage
- **print_jobs**: Print job records
- **audit_logs**: Activity audit trail
- **sessions**: Active user sessions
- **encryption_keys**: Owner's RSA public keys

See `database/schema.sql` for complete schema with indexes and constraints.

---

## 🐛 Common Issues & Solutions

### Issue: Database Connection Failed
**Solution**: Ensure PostgreSQL is running and DATABASE_URL is correct
```bash
psql -U postgres -c "SELECT 1"
```

### Issue: JWT Token Invalid
**Solution**: Verify JWT_SECRET is set correctly and token hasn't expired
```bash
# Decode token to check expiration
node -e "console.log(require('jsonwebtoken').decode('token'))"
```

### Issue: File Upload Fails
**Solution**: Check file size limits and disk space
```bash
# Check disk usage
df -h
```

See `docs/TROUBLESHOOTING.md` for more solutions.

---

## 📚 Documentation

- **ARCHITECTURE.md** - Detailed system design and flow
- **SETUP.md** - Step-by-step setup instructions
- **backend/README.md** - Backend API documentation
- **docs/API.md** - Complete API endpoint reference
- **docs/SECURITY.md** - Security implementation details
- **docs/DEPLOYMENT.md** - Production deployment guide
- **docs/TROUBLESHOOTING.md** - Common issues and solutions

---

## 🤝 Contributing

1. Create a feature branch: `git checkout -b feature/new-feature`
2. Commit changes: `git commit -am 'Add new feature'`
3. Push to branch: `git push origin feature/new-feature`
4. Submit pull request

### Code Review Checklist
- [ ] Tests written and passing
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] No security vulnerabilities
- [ ] No hardcoded credentials

---

## 📝 License

Proprietary - All rights reserved

---

## 📞 Support

For issues or questions:
1. Check `docs/TROUBLESHOOTING.md`
2. Review existing issues in version control
3. Contact development team

---

## 🎯 Roadmap

### Phase 1 (Current)
- [x] Architecture planning
- [x] Database schema
- [x] Backend foundation
- [ ] API endpoints implementation
- [ ] Mobile app implementation

### Phase 2
- [ ] Desktop app implementation
- [ ] Integration testing
- [ ] Security audit

### Phase 3
- [ ] Performance optimization
- [ ] Production deployment
- [ ] User documentation

### Phase 4
- [ ] Analytics dashboard
- [ ] Advanced features
- [ ] Mobile app enhancements

---

**Last Updated**: November 12, 2025
**Version**: 1.0.0
**Maintainers**: Development Team
