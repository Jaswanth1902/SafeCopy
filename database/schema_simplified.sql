-- ========================================
-- SECURE FILE PRINTING SYSTEM
-- SIMPLIFIED DATABASE SCHEMA (NO AUTHENTICATION)
-- PostgreSQL
-- ========================================
-- This is the SIMPLIFIED version with only 1 table
-- No users, no owners, no authentication required
-- Just encrypted files that get uploaded and printed
-- ========================================

-- ========================================
-- 1. FILES TABLE (THE ONLY TABLE YOU NEED)
-- ========================================
CREATE TABLE files (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- File Information
  file_name VARCHAR(255) NOT NULL,           -- Original filename (e.g., "document.pdf")
  file_size_bytes BIGINT NOT NULL,           -- File size in bytes
  file_mime_type VARCHAR(100),               -- MIME type (e.g., "application/pdf")

  -- Encrypted Data
  encrypted_file_data BYTEA NOT NULL,        -- The encrypted file binary data
  
  -- Encryption Metadata (needed for decryption)
  iv_vector BYTEA NOT NULL,                  -- Initialization Vector (16 bytes)
  auth_tag BYTEA NOT NULL,                   -- Authentication Tag for GCM mode

  -- Status Tracking
  is_printed BOOLEAN DEFAULT false,          -- Has this file been printed?
  printed_at TIMESTAMP,                      -- When was it printed?
  
  -- Deletion Tracking
  is_deleted BOOLEAN DEFAULT false,          -- Has this file been deleted?
  deleted_at TIMESTAMP,                      -- When was it deleted?

  -- Timestamps
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for fast queries
CREATE INDEX idx_files_created_at ON files(created_at DESC);
CREATE INDEX idx_files_is_deleted ON files(is_deleted) WHERE is_deleted = false;
CREATE INDEX idx_files_is_printed ON files(is_printed) WHERE is_printed = false;
CREATE INDEX idx_files_not_deleted ON files(id) WHERE is_deleted = false;

-- ========================================
-- VIEW: Active Files (not deleted)
-- ========================================
CREATE VIEW active_files AS
SELECT 
  id,
  file_name,
  file_size_bytes,
  created_at,
  is_printed,
  printed_at,
  CASE 
    WHEN is_printed THEN 'PRINTED'
    ELSE 'WAITING'
  END as status
FROM files
WHERE is_deleted = false
ORDER BY created_at DESC;

-- ========================================
-- VIEW: Deleted Files (for audit)
-- ========================================
CREATE VIEW deleted_files AS
SELECT 
  id,
  file_name,
  file_size_bytes,
  created_at,
  deleted_at,
  EXTRACT(EPOCH FROM (deleted_at - created_at))::INT as seconds_until_delete
FROM files
WHERE is_deleted = true
ORDER BY deleted_at DESC;

-- ========================================
-- FUNCTION: Auto-delete files older than 24 hours
-- (Run this daily via cron or scheduled task)
-- ========================================
CREATE OR REPLACE FUNCTION auto_delete_old_files()
RETURNS void AS $$
BEGIN
  UPDATE files
  SET 
    is_deleted = true,
    deleted_at = NOW()
  WHERE 
    is_deleted = false
    AND created_at < NOW() - INTERVAL '24 hours';
  
  RAISE NOTICE 'Auto-deleted old files';
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- TRIGGER: Update updated_at timestamp
-- ========================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_files_updated_at BEFORE UPDATE ON files
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ========================================
-- INDEXES FOR PERFORMANCE
-- ========================================
-- Already created above, but here's a reference:
-- - idx_files_created_at: Fast sorting by upload time
-- - idx_files_is_deleted: Fast filtering of active files
-- - idx_files_is_printed: Fast filtering of printed files
-- - idx_files_not_deleted: Direct lookup of active file

-- ========================================
-- SAMPLE QUERIES
-- ========================================

-- Get all files waiting to print
-- SELECT * FROM active_files WHERE status = 'WAITING';

-- Get a specific file by ID
-- SELECT id, file_name, file_size_bytes, encrypted_file_data, iv_vector, auth_tag 
-- FROM files WHERE id = 'some-uuid' AND is_deleted = false;

-- Mark file as printed
-- UPDATE files SET is_printed = true, printed_at = NOW() WHERE id = 'some-uuid';

-- Soft delete file (mark as deleted, don't actually delete)
-- UPDATE files SET is_deleted = true, deleted_at = NOW() WHERE id = 'some-uuid';

-- Count statistics
-- SELECT 
--   COUNT(*) as total_files,
--   COUNT(*) FILTER (WHERE is_deleted = false) as active_files,
--   COUNT(*) FILTER (WHERE is_printed = true) as printed_files
-- FROM files;

-- ========================================
-- GRANTS (if using a separate database user)
-- ========================================
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO secure_print_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO secure_print_user;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO secure_print_user;
