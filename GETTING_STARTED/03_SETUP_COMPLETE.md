# Secure File Printing System - Setup Guide

## Quick Start

This guide will help you set up the complete Secure File Printing System.

### Prerequisites
- Node.js 18+
- Flutter 3.0+
- PostgreSQL 14+
- Git
- VS Code or Android Studio

### Project Structure
```
SecureFilePrintSystem/
├── backend/                 # Node.js/Express API server
├── mobile_app/              # Flutter user mobile app
├── desktop_app/             # Flutter owner Windows app
├── database/                # SQL migrations and schemas
├── docs/                    # Documentation
└── README.md
```

## Step 1: Backend Setup

### Create Backend Project
```bash
cd SecureFilePrintSystem
mkdir backend
cd backend
npm init -y
npm install express dotenv cors helmet bcryptjs jsonwebtoken crypto-js pointycastle multer uuid
npm install --save-dev nodemon jest supertest
```

### Environment Variables (.env)
```
PORT=5000
NODE_ENV=development
DATABASE_URL=postgresql://user:password@localhost:5432/secure_print
JWT_SECRET=your_jwt_secret_key_min_32_chars
JWT_REFRESH_SECRET=your_refresh_secret_key_min_32_chars
ENCRYPTION_KEY=your_encryption_key_for_db_fields
CORS_ORIGIN=http://localhost:3000
```

## Step 2: Database Setup

### Create PostgreSQL Database
```sql
CREATE DATABASE secure_print;
\c secure_print;

-- See database/schema.sql for complete schema
```

## Step 3: Mobile App Setup

### Create Flutter User Mobile App
```bash
flutter create --org com.secureprintapp mobile_app
cd mobile_app
```

### Update pubspec.yaml
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
  dio: ^5.0.0
  flutter_secure_storage: ^9.0.0
  pointycastle: ^3.7.0
  file_picker: ^5.0.0
  permission_handler: ^11.0.0
  intl: ^0.19.0
```

## Step 4: Desktop App Setup

### Create Flutter Windows App
```bash
flutter create --platforms windows desktop_app
cd desktop_app
```

### Update pubspec.yaml
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
  dio: ^5.0.0
  flutter_secure_storage: ^9.0.0
  pointycastle: ^3.7.0
  intl: ^0.19.0
  # Windows print API integration
  win32: ^4.0.0
  windows_taskbar: ^1.0.0
```

## Running the System

### Terminal 1: Backend
```bash
cd backend
npm start
# Server runs on http://localhost:5000
```

### Terminal 2: Mobile App
```bash
cd mobile_app
flutter run -d <device_id>
```

### Terminal 3: Desktop App
```bash
cd desktop_app
flutter run -d windows
```

## Testing

### Backend Tests
```bash
cd backend
npm test
```

### Flutter App Tests
```bash
cd mobile_app
flutter test
```

## Security Best Practices

1. **Never commit .env files** to version control
2. **Use environment variables** for all secrets
3. **Enable HTTPS** in production
4. **Rotate encryption keys** regularly
5. **Implement rate limiting** on all endpoints
6. **Use strong passwords** and MFA
7. **Regular security audits** and updates

## Troubleshooting

### Database Connection Issues
- Ensure PostgreSQL is running
- Check DATABASE_URL in .env
- Verify user credentials

### Flutter Build Issues
- Run `flutter clean`
- Run `flutter pub get`
- Check Flutter version with `flutter --version`

### Certificate Pinning Issues
- Update certificates in app configuration
- Clear app cache and reinstall

## Support & Documentation

- See `ARCHITECTURE.md` for detailed system design
- See `backend/README.md` for API documentation
- See `mobile_app/README.md` for mobile app setup
- See `desktop_app/README.md` for desktop app setup

## License

Proprietary - All rights reserved
