# System Flow Diagrams & Visual Guides

## 1. Complete User Journey

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                          SECURE FILE PRINTING SYSTEM                            │
└─────────────────────────────────────────────────────────────────────────────────┘

STEP 1: USER UPLOADS FILE
┌──────────────────────────┐
│  User Mobile App         │
│                          │
│  1. Select File          │  ← User picks document.pdf
│  2. Generate AES-256 Key │  ← Generate random 256-bit key
│  3. Encrypt File         │  ← AES-256-GCM encryption
│  4. Encrypt Key with RSA │  ← Owner's public RSA key
│  5. Upload to Server     │  ← Send encrypted data
│                          │
└──────────────────────────┘
           │
           │ HTTPS POST /api/files/upload
           ▼
┌──────────────────────────┐
│  Backend Server          │
│                          │
│  1. Verify User          │  ← Check JWT token
│  2. Store Encrypted File │  ← Save to database
│  3. Store Encrypted Key  │  ← Save separately
│  4. Create Print Job     │  ← Status: PENDING
│  5. Send Job ID to User  │  ← User gets confirmation
│                          │
└──────────────────────────┘
           │
           │ Response: jobId, status: PENDING
           ▼
┌──────────────────────────┐
│  User Mobile App         │
│                          │
│  Display Confirmation:   │
│  ✓ File Uploaded        │
│  Job ID: abc123         │
│  Status: Pending        │
│                          │
└──────────────────────────┘


STEP 2: OWNER PRINTS FILE
┌──────────────────────────┐
│  Backend Server          │
│                          │
│  Owner polls for jobs    │  ← GET /api/owners/jobs/pending
│  (or receives notification)
│                          │
└──────────────────────────┘
           │
           │ Response: List of pending jobs
           ▼
┌──────────────────────────┐
│  Owner Windows App       │
│                          │
│  Display Pending Jobs:   │
│  - Document from User    │
│  - File Size: 1.2 MB    │
│                          │
│  Owner clicks "Print"    │
│                          │
└──────────────────────────┘
           │
           │ HTTPS GET /api/files/{fileId}
           ▼
┌──────────────────────────┐
│  Backend Server          │
│                          │
│  1. Verify Owner         │  ← Check JWT token
│  2. Fetch Encrypted File │
│  3. Fetch Encrypted Key  │
│  4. Send Both to Owner   │
│                          │
└──────────────────────────┘
           │
           │ Response: {encryptedFile, encryptedKey}
           ▼
┌──────────────────────────┐
│  Owner Windows App       │
│                          │
│  1. Decrypt Key with RSA │  ← Owner's private RSA key
│  2. Decrypt File with Key│  ← AES-256-GCM decryption
│  3. File now in memory   │  ← NEVER SAVED TO DISK
│  4. Send to Printer      │  ← Windows Print API
│  5. Wait for completion  │  ← Monitor print job
│                          │
└──────────────────────────┘
           │
           │ Print job completes
           ▼
┌──────────────────────────┐
│  Owner Windows App       │
│                          │
│  1. Shred decrypted data │  ← Overwrite with random
│  2. Clear memory         │  ← Delete all copies
│  3. Call server delete   │  ← Request file deletion
│                          │
└──────────────────────────┘
           │
           │ HTTPS POST /api/jobs/{jobId}/complete
           ▼
┌──────────────────────────┐
│  Backend Server          │
│                          │
│  1. Mark job COMPLETED   │
│  2. Delete encrypted file│
│  3. Delete encrypted key │
│  4. Shred database rows  │
│  5. Confirm to owner     │
│                          │
└──────────────────────────┘
           │
           │ Response: File deleted
           ▼
┌──────────────────────────┐
│  Owner Windows App       │
│                          │
│  Display Success:        │
│  ✓ File Printed         │
│  ✓ File Deleted         │
│  Job Complete           │
│                          │
└──────────────────────────┘


STEP 3: USER SEES CONFIRMATION
           │ Poll for status
           ▼
┌──────────────────────────┐
│  Backend Server          │
│                          │
│  GET /api/jobs/{jobId}   │  ← Status: COMPLETED
│                          │
└──────────────────────────┘
           │
           │ Response: status: COMPLETED
           ▼
┌──────────────────────────┐
│  User Mobile App         │
│                          │
│  Display Confirmation:   │
│  ✓ File Printed        │
│  ✓ File Deleted        │
│  Completed: 2:30 PM    │
│                          │
└──────────────────────────┘
```

---

## 2. Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     USER'S DEVICE (Secure)                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────┐                                          │
│  │  Original File   │                                          │
│  │  (plaintext)     │                                          │
│  │  "contract.pdf"  │                                          │
│  └────────┬─────────┘                                          │
│           │                                                     │
│           ▼                                                     │
│  ┌──────────────────────────────────┐                         │
│  │  Generate Random AES-256 Key     │                         │
│  │  (only in app memory, never saved)                         │
│  └────────┬──────────────────────────┘                         │
│           │                                                     │
│           ▼                                                     │
│  ┌──────────────────────────────────┐                         │
│  │  Encrypt with AES-256-GCM        │                         │
│  │  Output: Encrypted Binary Data   │                         │
│  └────────┬──────────────────────────┘                         │
│           │                                                     │
│           ├─────────────────────────────────────┐              │
│           │                                     │              │
│           ▼                                     ▼              │
│  ┌──────────────────┐            ┌──────────────────────┐    │
│  │ Encrypted File   │            │ AES-256 Symmetric    │    │
│  │                  │            │ Key (256 bits)       │    │
│  └────────┬─────────┘            └────────┬─────────────┘    │
│           │                               │                  │
│           │                      ┌────────▼─────────────┐    │
│           │                      │ Encrypt Key with     │    │
│           │                      │ Owner's RSA Public   │    │
│           │                      │ Key (RSA-2048)       │    │
│           │                      └────────┬─────────────┘    │
│           │                               │                  │
│           │                      ┌────────▼─────────────┐    │
│           │                      │ Encrypted Symmetric  │    │
│           │                      │ Key (256 bytes)      │    │
│           │                      └────────┬─────────────┘    │
│           │                               │                  │
│           └───────────────────────┬───────┘                  │
│                                   │                          │
└───────────────────────────────────┼──────────────────────────┘
                                    │
                  ┌─────────────────▼─────────────────┐
                  │  SEND TO SERVER OVER HTTPS/TLS   │
                  └─────────────────┬─────────────────┘
                                    │
                 ┌──────────────────▼──────────────────┐
                 │      SERVER DATABASE (Encrypted)   │
                 │                                    │
                 │  TABLE: files                      │
                 │  ├─ encrypted_file_data (BYTEA)   │
                 │  ├─ encrypted_symmetric_key        │
                 │  ├─ iv_vector                      │
                 │  └─ auth_tag                       │
                 │                                    │
                 └──────────────────┬──────────────────┘
                                    │
                  ┌─────────────────▼─────────────────┐
                  │  DOWNLOAD TO OWNER'S DEVICE       │
                  └─────────────────┬─────────────────┘
                                    │
┌───────────────────────────────────▼──────────────────────────┐
│               OWNER'S WINDOWS DEVICE (Secure)                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌────────────────────┐        ┌───────────────────────┐  │
│  │ Encrypted File     │        │ Encrypted Symmetric   │  │
│  │ (from server)      │        │ Key (from server)     │  │
│  └────────┬───────────┘        └───────┬───────────────┘  │
│           │                            │                  │
│           │                   ┌────────▼──────────────┐   │
│           │                   │ Decrypt Key with      │   │
│           │                   │ Owner's RSA Private   │   │
│           │                   │ Key (stored locally)  │   │
│           │                   └────────┬──────────────┘   │
│           │                            │                  │
│           │                   ┌────────▼──────────────┐   │
│           │                   │ AES-256 Symmetric     │   │
│           │                   │ Key (in memory only)  │   │
│           │                   └────────┬──────────────┘   │
│           │                            │                  │
│           └─────────────────┬──────────┘                  │
│                             │                             │
│                    ┌────────▼──────────┐                 │
│                    │ Decrypt File with  │                 │
│                    │ AES-256-GCM        │                 │
│                    └────────┬──────────┘                 │
│                             │                             │
│                    ┌────────▼──────────┐                 │
│                    │ Plain File in      │                 │
│                    │ Memory Only        │                 │
│                    │ (NOT on disk)      │                 │
│                    └────────┬──────────┘                 │
│                             │                             │
│                    ┌────────▼──────────┐                 │
│                    │ Send to Printer    │                 │
│                    │ (Windows Print API)│                 │
│                    └────────┬──────────┘                 │
│                             │                             │
│                    ┌────────▼──────────┐                 │
│                    │ Shred Memory       │                 │
│                    │ Delete from RAM    │                 │
│                    │ Overwrite 3x       │                 │
│                    └────────┬──────────┘                 │
│                             │                             │
│                    ┌────────▼──────────┐                 │
│                    │ Request Server     │                 │
│                    │ Delete File        │                 │
│                    └────────┬──────────┘                 │
│                             │                             │
└─────────────────────────────▼──────────────────────────────┘
                              │
                   ┌──────────▼──────────┐
                   │ SERVER DELETES      │
                   │ - Encrypted file    │
                   │ - Encrypted key     │
                   │ - All metadata      │
                   └──────────┬──────────┘
                              │
                              ▼
                   ┌──────────────────────┐
                   │  FILE COMPLETELY     │
                   │  GONE FROM SYSTEM    │
                   │  ✓ Not on server     │
                   │  ✓ Not on owner's PC │
                   │  ✓ Not in memory     │
                   └──────────────────────┘

KEY PRINCIPLE:
The original file is NEVER stored in plaintext anywhere except:
1. On user's device (user's responsibility)
2. Briefly in memory during decryption on owner's device
3. In printer's memory (transient, owner's responsibility)
```

---

## 3. Encryption Algorithm Flow

```
USER SIDE ENCRYPTION:
═══════════════════════════════════════════════════════════════

┌─────────────────────┐
│  Original File      │
│  "contract.pdf"     │
│  Size: 1.2 MB       │
└──────────┬──────────┘
           │
           ▼
┌──────────────────────────────────────┐
│  Step 1: Generate Symmetric Key      │
│  ┌────────────────────────────────┐  │
│  │ crypto.randomBytes(32)         │  │
│  │ Output: 256-bit random key     │  │
│  │ Used for: AES-256-GCM          │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────┐
│  Step 2: Generate IV (Nonce)         │
│  ┌────────────────────────────────┐  │
│  │ crypto.randomBytes(16)         │  │
│  │ Output: 128-bit IV              │  │
│  │ Must never be reused with key   │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────┐
│  Step 3: Encrypt File Content        │
│  ┌────────────────────────────────┐  │
│  │ createCipheriv('aes-256-gcm',   │  │
│  │   symmetricKey, iv)             │  │
│  │                                 │  │
│  │ Input: File data (1.2 MB)       │  │
│  │ Output: Encrypted data (1.2 MB) │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────┐
│  Step 4: Get Authentication Tag      │
│  ┌────────────────────────────────┐  │
│  │ cipher.getAuthTag()             │  │
│  │ Output: 128-bit auth tag        │  │
│  │ Prevents tampering              │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
           │
           ▼
    ┌──────┴──────┐
    │             │
    ▼             ▼
┌─────────────┐ ┌────────────────────┐
│ Encrypted   │ │ Symmetric Key      │
│ File Data   │ │ (256 bits)         │
│ (1.2 MB)    │ │ SAVE IN MEMORY!    │
└──────┬──────┘ └────────┬───────────┘
       │                 │
       │        ┌────────▼──────────┐
       │        │ Step 5: Encrypt   │
       │        │ Key with Owner's  │
       │        │ RSA Public Key    │
       │        │ (RSA-2048-OAEP)   │
       │        └────────┬──────────┘
       │                 │
       │                 ▼
       │        ┌──────────────────┐
       │        │ Encrypted Key    │
       │        │ (256 bytes)      │
       │        └────────┬─────────┘
       │                 │
       └────────┬────────┘
                │
                ▼
     ┌──────────────────────┐
     │  SEND TO SERVER:     │
     │                      │
     │  1. Encrypted file   │
     │  2. Encrypted key    │
     │  3. IV vector        │
     │  4. Auth tag         │
     │                      │
     │  Over HTTPS/TLS      │
     └──────────────────────┘


OWNER SIDE DECRYPTION:
═══════════════════════════════════════════════════════════════

┌──────────────────────┐
│ From Server:         │
│ - Encrypted file     │
│ - Encrypted key      │
│ - IV vector          │
│ - Auth tag           │
└──────────┬───────────┘
           │
           ▼
┌─────────────────────────────────────┐
│  Step 1: Get Private RSA Key        │
│  ┌──────────────────────────────┐   │
│  │ Load from secure storage     │   │
│  │ (encrypted on owner's device)│   │
│  │ May prompt for password      │   │
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│  Step 2: Decrypt Symmetric Key      │
│  ┌──────────────────────────────┐   │
│  │ privateDecrypt(              │   │
│  │   {                          │   │
│  │     key: privateKey,         │   │
│  │     padding: RSA_PKCS1_OAEP, │   │
│  │     oaepHash: 'sha256'       │   │
│  │   },                         │   │
│  │   encryptedKey               │   │
│  │ )                            │   │
│  │                              │   │
│  │ Output: 256-bit key          │   │
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘
           │
           ▼
    ┌──────┴────────────────────────┐
    │                               │
    ▼                               ▼
┌───────────────┐     ┌───────────────────┐
│ Decrypted Key │     │ Encrypted File    │
│ (in memory)   │     │ IV + Auth Tag     │
└───────┬───────┘     └────────┬──────────┘
        │                      │
        └──────┬───────────────┘
               │
               ▼
    ┌──────────────────────────┐
    │  Step 3: Decrypt File    │
    │  ┌────────────────────┐  │
    │  │ createDecipheriv(  │  │
    │  │   'aes-256-gcm',   │  │
    │  │   symmetricKey, iv)│  │
    │  │                    │  │
    │  │ setAuthTag(tag)    │  │
    │  │                    │  │
    │  │ Input: Encrypted   │  │
    │  │ Output: Plaintext  │  │
    │  └────────────────────┘  │
    └──────────┬───────────────┘
               │
               ▼
    ┌──────────────────────────┐
    │  Decrypted File          │
    │  (in memory only)        │
    │  NEVER saved to disk     │
    └──────────┬───────────────┘
               │
               ▼
    ┌──────────────────────────┐
    │  Send to Printer         │
    │  (Windows Print API)     │
    └──────────┬───────────────┘
               │
               ▼
    ┌──────────────────────────┐
    │  Shred Memory 3x         │
    │  (DoD Standard)          │
    │  - crypto.randomFill()   │
    │  - crypto.randomFill()   │
    │  - crypto.randomFill()   │
    │  - Clear all buffers     │
    └──────────┬───────────────┘
               │
               ▼
    ┌──────────────────────────┐
    │  DONE - File Gone        │
    │  ✓ Not in memory         │
    │  ✓ Not on disk           │
    │  ✓ Request server delete │
    └──────────────────────────┘
```

---

## 4. Security Layers

```
┌─────────────────────────────────────────────────────────────┐
│                  SECURITY ARCHITECTURE                      │
└─────────────────────────────────────────────────────────────┘

LAYER 1: TRANSPORT SECURITY
═══════════════════════════════════════════════════════════════
  ┌─────────────────────────────────────┐
  │  HTTPS/TLS 1.3                      │
  │  - 256-bit encryption               │
  │  - Certificate pinning in apps      │
  │  - Forward secrecy                  │
  │  - No man-in-the-middle attacks     │
  └─────────────────────────────────────┘


LAYER 2: APPLICATION AUTHENTICATION
═══════════════════════════════════════════════════════════════
  ┌─────────────────────────────────────┐
  │  JWT Tokens (HS256)                 │
  │  - 1 hour expiration (access)       │
  │  - 7 day expiration (refresh)       │
  │  - Signed with secret               │
  │  - Token verification on every call │
  │  - No token = 401 Unauthorized      │
  └─────────────────────────────────────┘


LAYER 3: PASSWORD SECURITY
═══════════════════════════════════════════════════════════════
  ┌─────────────────────────────────────┐
  │  Bcrypt Password Hashing            │
  │  - Salt rounds: 10                  │
  │  - Adaptive time cost               │
  │  - Resistant to rainbow tables      │
  │  - Passwords never stored plaintext │
  └─────────────────────────────────────┘


LAYER 4: FILE ENCRYPTION
═══════════════════════════════════════════════════════════════
  ┌─────────────────────────────────────┐
  │  AES-256-GCM Encryption             │
  │  - 256-bit symmetric key            │
  │  - Galois/Counter Mode (authenticated)
  │  - File authenticated (auth tag)    │
  │  - Tamper detection                 │
  │  - IV: 128-bit random per file      │
  │  - No IV reuse = security           │
  └─────────────────────────────────────┘


LAYER 5: KEY ENCRYPTION
═══════════════════════════════════════════════════════════════
  ┌─────────────────────────────────────┐
  │  RSA-2048 Key Encryption            │
  │  - 2048-bit asymmetric key          │
  │  - OAEP padding (probabilistic)     │
  │  - SHA-256 hash function            │
  │  - Secure key transport             │
  │  - Owner private key = access       │
  └─────────────────────────────────────┘


LAYER 6: ACCESS CONTROL
═══════════════════════════════════════════════════════════════
  ┌─────────────────────────────────────┐
  │  Role-Based Access Control (RBAC)   │
  │  - User role: limited permissions   │
  │  - Owner role: print permissions    │
  │  - User can only see own files      │
  │  - Owner can only see assigned jobs │
  │  - Admin role for system management │
  └─────────────────────────────────────┘


LAYER 7: RATE LIMITING
═══════════════════════════════════════════════════════════════
  ┌─────────────────────────────────────┐
  │  IP-Based Rate Limiting             │
  │  - 100 requests per 15 min per IP   │
  │  - Prevents brute force attacks     │
  │  - Prevents DDoS                    │
  │  - 429 Too Many Requests response   │
  └─────────────────────────────────────┘


LAYER 8: INPUT VALIDATION
═══════════════════════════════════════════════════════════════
  ┌─────────────────────────────────────┐
  │  Request Validation                 │
  │  - Type checking                    │
  │  - Length validation                │
  │  - Email format validation          │
  │  - File size limits                 │
  │  - MIME type checking               │
  │  - SQL injection prevention         │
  │  - XSS prevention                   │
  └─────────────────────────────────────┘


LAYER 9: AUDIT LOGGING
═══════════════════════════════════════════════════════════════
  ┌─────────────────────────────────────┐
  │  Comprehensive Audit Trail          │
  │  - All user actions logged          │
  │  - File access tracked              │
  │  - Failed logins logged             │
  │  - Admin actions logged             │
  │  - IP addresses recorded            │
  │  - Timestamps for all events        │
  │  - Retention: 1 year                │
  └─────────────────────────────────────┘


LAYER 10: SECURE DATA DELETION
═══════════════════════════════════════════════════════════════
  ┌─────────────────────────────────────┐
  │  DoD 5220.22-M Shredding            │
  │  - 3 passes of random overwrite     │
  │  - No file recovery possible        │
  │  - Applied to memory buffers        │
  │  - Applied after file deletion      │
  │  - Applied on app close             │
  └─────────────────────────────────────┘
```

---

## 5. Database Relationships

```
                          ┌─────────────────┐
                          │     USERS       │
                          ├─────────────────┤
                          │ id (PK)         │
                          │ email           │
                          │ password_hash   │
                          │ full_name       │
                          │ created_at      │
                          └────────┬────────┘
                                   │ 1:N
                                   │
                    ┌──────────────┴──────────────┐
                    │                             │
                    ▼ 1:N                         ▼ 1:N
        ┌──────────────────────┐      ┌──────────────────────┐
        │      FILES           │      │   PRINT_JOBS         │
        ├──────────────────────┤      ├──────────────────────┤
        │ id (PK)              │      │ id (PK)              │
        │ user_id (FK)◄────────┼──────┤ user_id (FK)         │
        │ owner_id (FK)        │      │ file_id (FK)         │
        │ encrypted_file_data  │      │ owner_id (FK)        │
        │ encrypted_sym_key    │      │ status               │
        │ file_name            │      │ printer_name         │
        │ file_size_bytes      │      │ pages_printed        │
        │ created_at           │      │ completed_at         │
        │ expires_at           │      └──────────┬───────────┘
        │ is_deleted           │                 │
        └──────────┬───────────┘                 │
                   │ 1:N                         │
                   │                             │
                   └────────────┬────────────────┘
                                │
                    ┌───────────┴────────────┐
                    │                        │
                    ▼                        ▼
        ┌──────────────────────┐  ┌──────────────────────┐
        │    AUDIT_LOGS        │  │     OWNERS           │
        ├──────────────────────┤  ├──────────────────────┤
        │ id (PK)              │  │ id (PK)              │
        │ user_id (FK)         │  │ email                │
        │ owner_id (FK)        │  │ password_hash        │
        │ action               │  │ public_key           │
        │ resource_type        │  │ full_name            │
        │ resource_id (FK)     │  │ created_at           │
        │ details (JSONB)      │  └──────────────────────┘
        │ created_at           │
        └──────────────────────┘

        ┌──────────────────────┐
        │    SESSIONS          │
        ├──────────────────────┤
        │ id (PK)              │
        │ user_id/owner_id (FK)│
        │ token_hash           │
        │ refresh_token_hash   │
        │ expires_at           │
        │ revoked_at           │
        └──────────────────────┘
```

---

**This completes the system design documentation!**

All diagrams, flows, and relationships have been documented for easy reference during implementation.
