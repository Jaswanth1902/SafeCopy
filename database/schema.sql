-- ========================================
-- Secure File Printing System
-- PostgreSQL Database Schema
-- ========================================

-- ========================================
-- 1. USERS TABLE (File Uploaders)
-- ========================================
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(255),
  phone VARCHAR(20),
  organization VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_login TIMESTAMP,
  is_active BOOLEAN DEFAULT true
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at);

-- ========================================
-- 2. OWNERS TABLE (Print Shop Operators)
-- ========================================
CREATE TABLE owners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(255),
  phone VARCHAR(20),
  organization VARCHAR(255),
  public_key TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_login TIMESTAMP,
  is_active BOOLEAN DEFAULT true
);

CREATE INDEX idx_owners_email ON owners(email);
CREATE INDEX idx_owners_created_at ON owners(created_at);

-- ========================================
-- 3. FILES TABLE (Encrypted Files)
-- ========================================
CREATE TABLE files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL REFERENCES owners(id),
  encrypted_file_data BYTEA NOT NULL,
  encrypted_symmetric_key BYTEA NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  file_size_bytes BIGINT NOT NULL,
  file_mime_type VARCHAR(100),
  original_file_hash VARCHAR(64),
  iv_vector BYTEA NOT NULL,
  auth_tag BYTEA,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP,
  is_deleted BOOLEAN DEFAULT false,
  deleted_at TIMESTAMP
);

CREATE INDEX idx_files_user_id ON files(user_id);
CREATE INDEX idx_files_owner_id ON files(owner_id);
CREATE INDEX idx_files_created_at ON files(created_at);
CREATE INDEX idx_files_expires_at ON files(expires_at) WHERE is_deleted = false;

-- ========================================
-- 4. PRINT JOBS TABLE
-- ========================================
CREATE TABLE print_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  file_id UUID NOT NULL REFERENCES files(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL REFERENCES owners(id) ON DELETE CASCADE,
  status VARCHAR(50) DEFAULT 'PENDING',
  -- PENDING, IN_PROGRESS, PRINTING, COMPLETED, FAILED, CANCELLED
  printer_name VARCHAR(255),
  pages_printed INT DEFAULT 0,
  print_timestamp TIMESTAMP,
  error_message TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  failure_reason TEXT
);

CREATE INDEX idx_print_jobs_file_id ON print_jobs(file_id);
CREATE INDEX idx_print_jobs_owner_id ON print_jobs(owner_id);
CREATE INDEX idx_print_jobs_user_id ON print_jobs(user_id);
CREATE INDEX idx_print_jobs_status ON print_jobs(status);
CREATE INDEX idx_print_jobs_created_at ON print_jobs(created_at);

-- ========================================
-- 5. AUDIT LOG TABLE
-- ========================================
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  owner_id UUID REFERENCES owners(id) ON DELETE SET NULL,
  action VARCHAR(100) NOT NULL,
  -- UPLOAD, DOWNLOAD, PRINT, DELETE, LOGIN, etc.
  resource_type VARCHAR(50),
  -- FILE, PRINT_JOB, USER, OWNER
  resource_id UUID,
  details JSONB,
  ip_address VARCHAR(45),
  user_agent TEXT,
  success BOOLEAN DEFAULT true,
  error_message TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_owner_id ON audit_logs(owner_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_resource_id ON audit_logs(resource_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);

-- ========================================
-- 6. SESSIONS TABLE
-- ========================================
CREATE TABLE sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  owner_id UUID REFERENCES owners(id) ON DELETE CASCADE,
  token_hash VARCHAR(255) NOT NULL UNIQUE,
  refresh_token_hash VARCHAR(255) NOT NULL UNIQUE,
  expires_at TIMESTAMP NOT NULL,
  refresh_expires_at TIMESTAMP NOT NULL,
  ip_address VARCHAR(45),
  user_agent TEXT,
  is_valid BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  revoked_at TIMESTAMP
);

CREATE INDEX idx_sessions_user_id ON sessions(user_id);
CREATE INDEX idx_sessions_owner_id ON sessions(owner_id);
CREATE INDEX idx_sessions_token_hash ON sessions(token_hash);
CREATE INDEX idx_sessions_expires_at ON sessions(expires_at);

-- ========================================
-- 7. ENCRYPTION KEYS TABLE
-- ========================================
CREATE TABLE encryption_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES owners(id) ON DELETE CASCADE,
  public_key TEXT NOT NULL,
  key_version INT DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  rotated_at TIMESTAMP,
  is_active BOOLEAN DEFAULT true
);

CREATE INDEX idx_encryption_keys_owner_id ON encryption_keys(owner_id);
CREATE INDEX idx_encryption_keys_is_active ON encryption_keys(is_active);

-- ========================================
-- 8. DEVICE REGISTRATION TABLE
-- ========================================
CREATE TABLE device_registrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  owner_id UUID REFERENCES owners(id) ON DELETE CASCADE,
  device_id VARCHAR(255) NOT NULL,
  device_name VARCHAR(255),
  device_type VARCHAR(50),
  -- MOBILE, DESKTOP, WEB
  os_version VARCHAR(100),
  app_version VARCHAR(50),
  certificate_hash VARCHAR(255),
  last_used TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  is_trusted BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_device_registrations_user_id ON device_registrations(user_id);
CREATE INDEX idx_device_registrations_owner_id ON device_registrations(owner_id);
CREATE INDEX idx_device_registrations_device_id ON device_registrations(device_id);

-- ========================================
-- 9. RATE LIMIT TABLE
-- ========================================
CREATE TABLE rate_limits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  owner_id UUID REFERENCES owners(id) ON DELETE CASCADE,
  endpoint VARCHAR(255) NOT NULL,
  request_count INT DEFAULT 1,
  window_start TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  window_end TIMESTAMP NOT NULL
);

CREATE INDEX idx_rate_limits_user_id ON rate_limits(user_id);
CREATE INDEX idx_rate_limits_owner_id ON rate_limits(owner_id);
CREATE INDEX idx_rate_limits_endpoint ON rate_limits(endpoint);
CREATE INDEX idx_rate_limits_window_end ON rate_limits(window_end);

-- ========================================
-- 10. VIEWS FOR REPORTING
-- ========================================

-- View: User Print Statistics
CREATE VIEW user_print_stats AS
SELECT
  u.id,
  u.email,
  u.full_name,
  COUNT(DISTINCT f.id) as total_files_uploaded,
  COUNT(DISTINCT pj.id) as total_print_jobs,
  COUNT(CASE WHEN pj.status = 'COMPLETED' THEN 1 END) as completed_jobs,
  SUM(f.file_size_bytes) / 1024 / 1024 as total_size_mb,
  MAX(pj.created_at) as last_print_job
FROM users u
LEFT JOIN files f ON u.id = f.user_id
LEFT JOIN print_jobs pj ON f.id = pj.file_id
GROUP BY u.id, u.email, u.full_name;

-- View: Owner Printer Statistics
CREATE VIEW owner_print_stats AS
SELECT
  o.id,
  o.email,
  o.full_name,
  COUNT(DISTINCT pj.id) as total_jobs_printed,
  COUNT(CASE WHEN pj.status = 'COMPLETED' THEN 1 END) as completed_jobs,
  COUNT(CASE WHEN pj.status = 'FAILED' THEN 1 END) as failed_jobs,
  SUM(pj.pages_printed) as total_pages_printed,
  AVG(EXTRACT(EPOCH FROM (pj.completed_at - pj.started_at))) as avg_job_duration_seconds,
  MAX(pj.completed_at) as last_job_completed
FROM owners o
LEFT JOIN print_jobs pj ON o.id = pj.owner_id
GROUP BY o.id, o.email, o.full_name;

-- ========================================
-- 11. TRIGGER FOR AUTO-DELETE EXPIRED FILES
-- ========================================

CREATE OR REPLACE FUNCTION delete_expired_files()
RETURNS void AS $$
BEGIN
  UPDATE files
  SET is_deleted = true, deleted_at = CURRENT_TIMESTAMP
  WHERE expires_at < CURRENT_TIMESTAMP AND is_deleted = false;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- 12. TRIGGER FOR UPDATED_AT TIMESTAMPS
-- ========================================

CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_updated_at BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER owners_updated_at BEFORE UPDATE ON owners
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- ========================================
-- 13. PERMISSIONS (Optional - for multi-tenant)
-- ========================================

-- Only users and owners can see their own data
-- Implement row-level security policies in application layer

-- ========================================
-- INITIAL DATA SEED (Optional)
-- ========================================

-- You can add initial test data here
-- INSERT INTO users (email, password_hash, full_name) VALUES ...
-- INSERT INTO owners (email, password_hash, full_name, public_key) VALUES ...
