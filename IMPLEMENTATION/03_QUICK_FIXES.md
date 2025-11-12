# 🚨 QUICK REFERENCE: Top 10 Fixes Needed

## Priority: DO THESE FIRST

### 1. ⚠️ AUTHENTICATION NOT APPLIED TO ROUTES

**Status:** CRITICAL - Security Breach  
**Files:** `backend/routes/files.js`

```javascript
// Currently all routes are OPEN:
router.post('/upload', upload.single('file'), async (req, res) => { ... })
router.get('/files', async (req, res) => { ... })
router.get('/print/:file_id', async (req, res) => { ... })
router.post('/delete/:file_id', async (req, res) => { ... })

// FIX: Import middleware and apply it
const { verifyToken } = require('../middleware/auth');

router.post('/upload', verifyToken, upload.single('file'), async (req, res) => {
  const userId = req.user.id;  // Now available from JWT
  // ... rest of implementation
});

router.get('/files', verifyToken, async (req, res) => {
  const userId = req.user.id;
  // ... add WHERE user_id = $1 to query
});

router.get('/print/:file_id', verifyToken, async (req, res) => {
  // ... verify file belongs to user
});

router.post('/delete/:file_id', verifyToken, async (req, res) => {
  // ... verify user/owner permissions
});
```

**Impact:** ANY user can upload/download/delete ANY file

---

### 2. 🚨 NO USER/OWNER VALIDATION IN QUERIES

**Status:** CRITICAL - Data Breach  
**Files:** `backend/routes/files.js`

```javascript
// BEFORE (Anyone can access any file):
const query = `SELECT * FROM files WHERE id = $1`;
const result = await db.query(query, [file_id]);

// AFTER (User can only access their files):
const query = `
  SELECT * FROM files 
  WHERE id = $1 AND user_id = $2
`;
const result = await db.query(query, [file_id, req.user.id]);

if (!result.rows.length) {
  return res.status(404).json({ error: "File not found" });
}
```

**Apply to:**

- GET /api/print/:id
- POST /api/delete/:id
- All other file queries

---

### 3. 📊 RATE LIMITING NOT ENABLED

**Status:** HIGH - DOS Vulnerability  
**File:** `backend/routes/files.js`

```javascript
const { rateLimit } = require('../middleware/auth');

// Add rate limiting to routes:
router.post('/upload',
  rateLimit(10, 60000),    // 10 uploads per minute per IP
  verifyToken,
  upload.single('file'),
  async (req, res) => { ... }
);

router.get('/files',
  rateLimit(30, 60000),    // 30 requests per minute
  verifyToken,
  async (req, res) => { ... }
);
```

**Why:** Without this, users can spam uploads/downloads

---

### 4. 🔑 NO JWT SECRET VALIDATION

**Status:** HIGH - Runtime Error Risk  
**File:** `backend/server.js`

```javascript
// Add at startup (before app.listen):
if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 32) {
  console.error('❌ FATAL: JWT_SECRET must be set and 32+ characters');
  process.exit(1);
}

if (!process.env.JWT_REFRESH_SECRET || process.env.JWT_REFRESH_SECRET.length < 32) {
  console.error('❌ FATAL: JWT_REFRESH_SECRET must be set and 32+ characters');
  process.exit(1);
}

console.log('✅ Environment validation passed');

app.listen(PORT, () => { ... });
```

---

### 5. ⚠️ ERROR MESSAGES LEAK STACK TRACES

**Status:** HIGH - Information Disclosure  
**File:** `backend/routes/files.js`

```javascript
// BEFORE (Dangerous):
catch (error) {
  console.error('Upload error:', error);
  res.status(500).json({
    error: true,
    message: error.message,  // Could show internal paths
    details: error.stack      // Shows implementation
  });
}

// AFTER (Safe):
catch (error) {
  console.error('Upload error:', error);
  const isDev = process.env.NODE_ENV === 'development';
  res.status(500).json({
    error: true,
    message: isDev ? error.message : 'Internal server error',
    requestId: new Date().getTime()  // For support tickets
  });
}
```

---

### 6. 📱 HARDCODED API URL IN FLUTTER

**Status:** HIGH - Non-functional on Real Devices  
**File:** `mobile_app/lib/main.dart` (line 121)

```dart
// BEFORE (Won't work on devices):
const String apiBaseUrl = 'http://localhost:5000';

// AFTER (Configurable):
// Create lib/config/app_config.dart
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000',  // dev default
  );
}

// Use in code:
final apiBaseUrl = AppConfig.apiBaseUrl;  // http://api.example.com on prod
```

---

### 7. 🔐 NO HTTPS ENFORCEMENT

**Status:** MEDIUM - Encryption Interception  
**File:** `backend/server.js`

```javascript
// Add before routes:
app.use((req, res, next) => {
  if (process.env.NODE_ENV === "production" && !req.secure) {
    return res.status(403).json({
      error: true,
      message: "HTTPS required",
    });
  }
  next();
});

// Also add HSTS headers (already have helmet, but double-check):
app.use(
  helmet({
    hsts: {
      maxAge: 31536000, // 1 year
      includeSubDomains: true,
      preload: true,
    },
  })
);
```

---

### 8. 🗄️ DATABASE CONSTRAINT ERROR

**Status:** HIGH - Schema Flaw  
**File:** `database/schema.sql`

```sql
-- BEFORE (Problems):
CREATE TABLE files (
  user_id UUID NOT NULL REFERENCES users(id),
  owner_id UUID NOT NULL REFERENCES owners(id),
  -- Both required, but file is either user-uploaded OR owner-uploaded
);

-- AFTER (Correct):
CREATE TABLE files (
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  owner_id UUID REFERENCES owners(id) ON DELETE SET NULL,
  encrypted_file_data BYTEA NOT NULL,
  -- ... other fields
  CONSTRAINT file_user_or_owner_check
    CHECK ((user_id IS NOT NULL) <> (owner_id IS NOT NULL))
);

-- Interpretation: Exactly one must be NOT NULL (XOR check)
```

---

### 9. 🧪 ZERO TEST COVERAGE

**Status:** CRITICAL - No Quality Assurance

**Create tests:**

```bash
# backend/tests/unit/services/encryptionService.test.js
describe('EncryptionService', () => {
  test('AES-256-GCM encryption should be reversible', () => {
    const data = Buffer.from('test data');
    const key = crypto.randomBytes(32);

    const encrypted = EncryptionService.encryptFileAES256(data);
    const decrypted = EncryptionService.decryptFileAES256(
      encrypted.encryptedData,
      encrypted.symmetricKey,
      encrypted.iv,
      encrypted.authTag
    );

    expect(decrypted).toEqual(data);
  });
});

# backend/tests/integration/files.routes.test.js
describe('POST /api/upload', () => {
  test('should reject request without auth token', async () => {
    const response = await request(app)
      .post('/api/upload')
      .send({ file_name: 'test.pdf' });

    expect(response.status).toBe(401);
  });

  test('should accept authenticated user with file', async () => {
    const token = generateTestToken();
    const response = await request(app)
      .post('/api/upload')
      .set('Authorization', `Bearer ${token}`)
      .attach('file', Buffer.from('test'), 'test.pdf');

    expect(response.status).toBe(201);
  });
});
```

**Minimum Coverage:**

- Auth service: 90%
- Encryption service: 95%
- File routes: 80%
- Database: 70%

---

### 10. 📋 NO INPUT VALIDATION

**Status:** MEDIUM - Data Integrity Issues  
**Files:** All route handlers

```javascript
// BEFORE (No validation):
if (!req.body.file_name) {
  return res.status(400).json({ error: 'file_name required' });
}

// AFTER (Comprehensive):
const validateFileUpload = (req, res, next) => {
  const { file_name, iv_vector, auth_tag } = req.body;

  // File name validation
  if (!file_name) {
    return res.status(400).json({ error: 'file_name required' });
  }
  if (file_name.length > 255) {
    return res.status(400).json({ error: 'file_name too long' });
  }
  if (!/^[\w\s.-]+$/.test(file_name)) {
    return res.status(400).json({ error: 'file_name has invalid characters' });
  }

  // IV validation
  if (!iv_vector) {
    return res.status(400).json({ error: 'iv_vector required' });
  }
  try {
    const buf = Buffer.from(iv_vector, 'base64');
    if (buf.length !== 16) {
      return res.status(400).json({ error: 'iv_vector must be 16 bytes (base64)' });
    }
  } catch (e) {
    return res.status(400).json({ error: 'iv_vector must be valid base64' });
  }

  // Auth tag validation
  if (!auth_tag) {
    return res.status(400).json({ error: 'auth_tag required' });
  }
  try {
    const buf = Buffer.from(auth_tag, 'base64');
    if (buf.length !== 16) {
      return res.status(400).json({ error: 'auth_tag must be 16 bytes (base64)' });
    }
  } catch (e) {
    return res.status(400).json({ error: 'auth_tag must be valid base64' });
  }

  // File size validation
  if (!req.file || req.file.size === 0) {
    return res.status(400).json({ error: 'no file provided' });
  }
  if (req.file.size > 500 * 1024 * 1024) {
    return res.status(413).json({ error: 'file too large (max 500MB)' });
  }

  next();
};

// Use in routes:
router.post('/upload',
  rateLimit(10, 60000),
  verifyToken,
  validateFileUpload,
  upload.single('file'),
  async (req, res) => { ... }
);
```

---

## 🎯 IMPLEMENTATION ORDER

```
Week 1: CRITICAL FIXES
1. ✅ Add verifyToken to all routes (1-2 hours)
2. ✅ Add user_id validation to queries (1-2 hours)
3. ✅ Enable rate limiting (1 hour)
4. ✅ Add JWT secret validation (30 min)
5. ✅ Fix error message leaking (1 hour)

Week 2: HIGH PRIORITY
6. ✅ Fix Flutter hardcoded URL (30 min)
7. ✅ Enforce HTTPS (30 min)
8. ✅ Fix database schema (1 hour)
9. ✅ Add comprehensive input validation (3-4 hours)
10. ✅ Add structured logging (2-3 hours)

Week 3: TESTING & QUALITY
11. ✅ Write unit tests (8-10 hours)
12. ✅ Write integration tests (8-10 hours)
13. ✅ Write security tests (4-6 hours)

Total: ~3-4 weeks to production-ready
```

---

## 📊 BEFORE/AFTER SECURITY SCORE

```
BEFORE CODE REVIEW:
Authentication:     ❌ 0/10   (No auth on routes)
Authorization:      ❌ 0/10   (No user validation)
Encryption:         ✅ 9/10   (Well implemented)
Input Validation:   ⚠️ 2/10   (Minimal)
Error Handling:     ⚠️ 4/10   (Basic try-catch)
Testing:            ❌ 0/10   (No tests)
OVERALL:            ⚠️ 2.5/10  (BLOCKED FOR PRODUCTION)

AFTER FIXES:
Authentication:     ✅ 9/10   (JWT on all routes)
Authorization:      ✅ 8/10   (User validation)
Encryption:         ✅ 9/10   (Already good)
Input Validation:   ✅ 8/10   (Comprehensive)
Error Handling:     ✅ 8/10   (Proper error responses)
Testing:            ✅ 7/10   (50%+ coverage)
OVERALL:            ✅ 8.2/10  (READY FOR PRODUCTION)
```

---

**For full details, see:** `CODE_REVIEW.md`
