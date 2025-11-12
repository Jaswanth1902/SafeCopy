# Backend API Server - README

## Overview

This is the Node.js/Express backend server for the Secure File Printing System. It handles:
- User and owner authentication
- File upload and encryption
- Print job management
- Audit logging
- Database operations

## Project Structure

```
backend/
├── server.js                    # Main Express server
├── package.json                 # Dependencies
├── .env.example                 # Environment variables template
├── config/
│   ├── database.js              # Database connection
│   └── constants.js             # Application constants
├── middleware/
│   ├── auth.js                  # Authentication & authorization
│   └── error.js                 # Error handling
├── routes/
│   ├── users.js                 # User endpoints
│   ├── owners.js                # Owner endpoints
│   ├── files.js                 # File upload/download
│   ├── jobs.js                  # Print job management
│   └── audit.js                 # Audit logging
├── controllers/
│   ├── userController.js        # User business logic
│   ├── ownerController.js       # Owner business logic
│   ├── fileController.js        # File operations
│   ├── jobController.js         # Print job operations
│   └── auditController.js       # Audit operations
├── services/
│   ├── authService.js           # Authentication utilities
│   ├── encryptionService.js     # Encryption/decryption
│   ├── fileService.js           # File handling
│   ├── jobService.js            # Job management
│   └── emailService.js          # Email notifications
├── models/
│   ├── userModel.js             # User database model
│   ├── ownerModel.js            # Owner database model
│   ├── fileModel.js             # File database model
│   ├── jobModel.js              # Print job database model
│   └── auditModel.js            # Audit log database model
└── utils/
    ├── validators.js            # Input validation
    ├── logger.js                # Application logging
    └── helpers.js               # Utility functions
```

## Installation

### Prerequisites
- Node.js 18+
- PostgreSQL 14+
- npm 8+

### Setup

1. **Install Dependencies**
   ```bash
   npm install
   ```

2. **Configure Environment Variables**
   ```bash
   cp .env.example .env
   ```

   Edit `.env` with your configuration:
   ```env
   PORT=5000
   NODE_ENV=development
   DATABASE_URL=postgresql://user:password@localhost:5432/secure_print
   JWT_SECRET=your_secret_key_min_32_characters
   JWT_REFRESH_SECRET=your_refresh_secret_min_32_characters
   CORS_ORIGIN=http://localhost:3000
   ```

3. **Create Database**
   ```bash
   createdb secure_print
   ```

4. **Run Database Migrations**
   ```bash
   npm run migrate
   ```

## Running the Server

### Development Mode (with auto-reload)
```bash
npm run dev
```

### Production Mode
```bash
npm start
```

The server will start on `http://localhost:5000`

## API Endpoints

### User Endpoints
- `POST /api/users/register` - Register new user
- `POST /api/users/login` - User login
- `POST /api/users/logout` - User logout
- `POST /api/users/refresh-token` - Refresh access token
- `GET /api/users/profile` - Get user profile
- `PUT /api/users/profile` - Update user profile
- `POST /api/users/change-password` - Change password

### Owner Endpoints
- `POST /api/owners/register` - Register new owner
- `POST /api/owners/login` - Owner login
- `GET /api/owners/profile` - Get owner profile
- `PUT /api/owners/profile` - Update owner profile
- `GET /api/owners/public-key` - Get owner's public key

### File Endpoints
- `POST /api/files/upload` - Upload encrypted file
- `GET /api/files/:fileId` - Download encrypted file
- `DELETE /api/files/:fileId` - Delete file

### Print Job Endpoints
- `GET /api/jobs/pending` - Get pending print jobs
- `POST /api/jobs/:jobId/start` - Start print job
- `POST /api/jobs/:jobId/complete` - Complete print job
- `GET /api/jobs/history` - Get job history
- `GET /api/jobs/:jobId/status` - Get job status

### Audit Endpoints
- `GET /api/audit/logs` - Get audit logs (admin only)
- `GET /api/audit/logs/:userId` - Get user's audit logs

## Security Features

### 1. **Encryption**
- AES-256-GCM for file encryption
- RSA-2048 for key encryption
- HTTPS/TLS for all communication

### 2. **Authentication**
- JWT with HS256 algorithm
- Access tokens (1 hour expiration)
- Refresh tokens (7 days expiration)
- Bcrypt password hashing (salt rounds: 10)

### 3. **Authorization**
- Role-based access control (RBAC)
- User isolation (can only access own files)
- Owner isolation (can only access assigned files)

### 4. **Rate Limiting**
- IP-based rate limiting
- Per-endpoint rate limits
- Configurable limits and time windows

### 5. **Input Validation**
- Type validation for all inputs
- Email format validation
- File size limits
- Content-type verification

### 6. **Audit Logging**
- All user actions logged
- Admin access logging
- File access logging
- Failed login attempts logged

## Database Schema

The database uses PostgreSQL with the following main tables:
- `users` - User accounts
- `owners` - Owner/printer operator accounts
- `files` - Encrypted file storage
- `print_jobs` - Print job records
- `audit_logs` - Activity audit trail
- `sessions` - Active sessions
- `encryption_keys` - Owner's RSA public keys

See `../database/schema.sql` for complete schema.

## Testing

### Run Tests
```bash
npm test
```

### Run Tests in Watch Mode
```bash
npm run test:watch
```

### Generate Coverage Report
```bash
npm test -- --coverage
```

## Deployment

### Production Checklist
- [ ] Set `NODE_ENV=production`
- [ ] Use strong, random JWT secrets
- [ ] Enable HTTPS/TLS
- [ ] Configure CORS for production domains
- [ ] Set up database backups
- [ ] Configure monitoring and logging
- [ ] Enable rate limiting
- [ ] Set up CI/CD pipeline

### Docker Deployment
```bash
docker build -t secure-print-backend .
docker run -p 5000:5000 --env-file .env secure-print-backend
```

## Troubleshooting

### Database Connection Error
- Verify PostgreSQL is running
- Check DATABASE_URL in .env
- Verify database user credentials
- Run: `psql -U user -d secure_print -c "SELECT 1"`

### JWT Token Errors
- Ensure JWT_SECRET is set and strong
- Check token expiration times
- Verify token format: `Bearer <token>`

### File Upload Errors
- Verify file size limits
- Check disk space
- Verify file permissions
- Check multer configuration

## Performance Optimization

### Implemented Features
- Response compression (gzip)
- Database query optimization
- Connection pooling
- Caching strategies
- Async/await for non-blocking operations

### Recommended Additions
- Redis caching for frequently accessed data
- Database indexing on frequently queried columns
- Query result pagination
- Lazy loading for large files
- CDN for static assets

## Monitoring & Logging

### Log Files
- Combined access logs (morgan)
- Error logs (winston)
- Audit logs (database)

### Recommended Monitoring
- Application performance monitoring (APM)
- Error tracking (Sentry)
- Log aggregation (ELK stack)
- Health checks

## Support & Maintenance

### Regular Tasks
- [ ] Review audit logs
- [ ] Update dependencies
- [ ] Rotate JWT secrets (quarterly)
- [ ] Backup database (daily)
- [ ] Monitor disk usage
- [ ] Review failed login attempts

### Emergency Procedures
- File data corruption: Restore from backup
- Security breach: Rotate all keys, audit logs
- Service outage: Check logs, restart services

## Contributing

1. Follow ESLint rules
2. Write tests for new features
3. Update documentation
4. Follow security best practices
5. Submit pull request

## License

Proprietary - All rights reserved
