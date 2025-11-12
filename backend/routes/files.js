// ========================================
// SECURE FILE PRINTING SYSTEM - FILE ROUTES
// POST /api/upload - Upload encrypted file
// GET /api/files - List all uploaded files
// GET /api/print/:id - Download file for printing
// POST /api/delete/:id - Delete file after printing
// ========================================

const express = require('express');
const router = express.Router();
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');
const db = require('../database');

// Configure multer for file uploads (store in memory, then save to DB)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 500 * 1024 * 1024, // 500MB max
  },
});

// ========================================
// 1. POST /api/upload
// Upload encrypted file from mobile app
// ========================================
router.post('/upload', upload.single('file'), async (req, res) => {
  try {
    // Validate request
    if (!req.file) {
      return res.status(400).json({ error: 'No file provided' });
    }

    if (!req.body.file_name) {
      return res.status(400).json({ error: 'file_name is required' });
    }

    if (!req.body.iv_vector) {
      return res.status(400).json({ error: 'iv_vector is required' });
    }

    if (!req.body.auth_tag) {
      return res.status(400).json({ error: 'auth_tag is required' });
    }

    // Generate unique file ID
    const fileId = uuidv4();

    // Convert base64 strings to Buffer
    const ivBuffer = Buffer.from(req.body.iv_vector, 'base64');
    const authTagBuffer = Buffer.from(req.body.auth_tag, 'base64');

    // Insert into database
    const query = `
      INSERT INTO files (
        id, 
        file_name, 
        encrypted_file_data, 
        file_size_bytes, 
        file_mime_type, 
        iv_vector, 
        auth_tag,
        created_at,
        is_deleted
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), false)
      RETURNING id, file_name, file_size_bytes, created_at
    `;

    const result = await db.query(query, [
      fileId,
      req.body.file_name,
      req.file.buffer,           // Encrypted file data (binary)
      req.file.size,             // File size in bytes
      req.file.mimetype || 'application/octet-stream',
      ivBuffer,                  // IV vector (binary)
      authTagBuffer,             // Auth tag (binary)
    ]);

    const uploadedFile = result.rows[0];

    // Log successful upload
    console.log(`✅ File uploaded: ${fileId}`);
    console.log(`   Name: ${uploadedFile.file_name}`);
    console.log(`   Size: ${uploadedFile.file_size_bytes} bytes`);
    console.log(`   Time: ${uploadedFile.created_at}`);

    res.status(201).json({
      success: true,
      file_id: uploadedFile.id,
      file_name: uploadedFile.file_name,
      file_size_bytes: uploadedFile.file_size_bytes,
      uploaded_at: uploadedFile.created_at.toISOString(),
      message: 'File uploaded successfully. Share the file_id with the owner.',
    });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({
      error: true,
      message: 'Failed to upload file',
      details: error.message,
    });
  }
});

// ========================================
// 2. GET /api/files
// List all uploaded files waiting to be printed
// ========================================
router.get('/files', async (req, res) => {
  try {
    const query = `
      SELECT 
        id,
        file_name,
        file_size_bytes,
        created_at,
        is_printed,
        printed_at
      FROM files
      WHERE is_deleted = false
      ORDER BY created_at DESC
      LIMIT 100
    `;

    const result = await db.query(query);

    const files = result.rows.map(row => ({
      file_id: row.id,
      file_name: row.file_name,
      file_size_bytes: row.file_size_bytes,
      uploaded_at: row.created_at.toISOString(),
      is_printed: row.is_printed || false,
      printed_at: row.printed_at ? row.printed_at.toISOString() : null,
      status: row.is_printed ? 'PRINTED_AND_DELETED' : 'WAITING_TO_PRINT',
    }));

    console.log(`✅ Listed ${files.length} files`);

    res.json({
      success: true,
      count: files.length,
      files: files,
      message: `${files.length} file(s) waiting to be printed`,
    });
  } catch (error) {
    console.error('List files error:', error);
    res.status(500).json({
      error: true,
      message: 'Failed to list files',
      details: error.message,
    });
  }
});

// ========================================
// 3. GET /api/print/:file_id
// Download encrypted file for printing
// Owner receives encrypted file + IV + Auth Tag
// Owner must decrypt client-side before printing
// ========================================
router.get('/print/:file_id', async (req, res) => {
  try {
    const { file_id } = req.params;

    // Validate file_id format
    if (!file_id || file_id.length < 5) {
      return res.status(400).json({ error: 'Invalid file_id' });
    }

    // Query database for encrypted file
    const query = `
      SELECT 
        id,
        file_name,
        encrypted_file_data,
        file_size_bytes,
        iv_vector,
        auth_tag,
        created_at,
        is_printed
      FROM files
      WHERE id = $1 AND is_deleted = false
    `;

    const result = await db.query(query, [file_id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: true,
        message: 'File not found or already deleted',
        file_id: file_id,
      });
    }

    const file = result.rows[0];

    console.log(`✅ File downloaded for printing: ${file_id}`);
    console.log(`   Name: ${file.file_name}`);
    console.log(`   Size: ${file.file_size_bytes} bytes`);
    console.log(`   Status: ${file.is_printed ? 'Already printed' : 'Ready to print'}`);

    // Return encrypted file with IV and auth tag
    // Client must decrypt before printing
    res.json({
      success: true,
      file_id: file.id,
      file_name: file.file_name,
      file_size_bytes: file.file_size_bytes,
      uploaded_at: file.created_at.toISOString(),
      is_printed: file.is_printed || false,
      // Client receives encrypted data as base64
      encrypted_file_data: file.encrypted_file_data.toString('base64'),
      iv_vector: file.iv_vector.toString('base64'),
      auth_tag: file.auth_tag.toString('base64'),
      // Instructions for client
      message: 'Decrypt this file on your PC before printing',
      decryption_instructions: {
        step1: 'Receive the encrypted_file_data, iv_vector, and auth_tag',
        step2: 'You must have the decryption key (shared by uploader)',
        step3: 'Call decryptFileAES256(encrypted_file_data, key, iv_vector, auth_tag)',
        step4: 'Decryption happens ONLY in memory (never touches disk)',
        step5: 'Send decrypted data to printer',
        step6: 'Call DELETE /api/delete/{file_id} to auto-delete',
      },
    });
  } catch (error) {
    console.error('Print download error:', error);
    res.status(500).json({
      error: true,
      message: 'Failed to download file for printing',
      details: error.message,
    });
  }
});

// ========================================
// 4. POST /api/delete/:file_id
// Delete file after printing
// Owner calls this AFTER printing is complete
// File is permanently deleted from database
// ========================================
router.post('/delete/:file_id', async (req, res) => {
  try {
    const { file_id } = req.params;

    // Validate file_id format
    if (!file_id || file_id.length < 5) {
      return res.status(400).json({ error: 'Invalid file_id' });
    }

    // Check if file exists
    const checkQuery = `
      SELECT id, file_name, is_deleted
      FROM files
      WHERE id = $1
    `;

    const checkResult = await db.query(checkQuery, [file_id]);

    if (checkResult.rows.length === 0) {
      return res.status(404).json({
        error: true,
        message: 'File not found',
        file_id: file_id,
      });
    }

    const file = checkResult.rows[0];

    if (file.is_deleted) {
      return res.status(400).json({
        error: true,
        message: 'File already deleted',
        file_id: file_id,
      });
    }

    // Delete file (mark as deleted + set deleted_at timestamp)
    const deleteQuery = `
      UPDATE files
      SET 
        is_deleted = true,
        deleted_at = NOW(),
        is_printed = true,
        printed_at = NOW()
      WHERE id = $1
      RETURNING id, file_name, deleted_at
    `;

    const deleteResult = await db.query(deleteQuery, [file_id]);
    const deletedFile = deleteResult.rows[0];

    console.log(`✅ File deleted: ${file_id}`);
    console.log(`   Name: ${deletedFile.file_name}`);
    console.log(`   Deleted at: ${deletedFile.deleted_at}`);

    res.json({
      success: true,
      file_id: deletedFile.id,
      file_name: deletedFile.file_name,
      status: 'DELETED',
      deleted_at: deletedFile.deleted_at.toISOString(),
      message: 'File has been permanently deleted from server',
    });
  } catch (error) {
    console.error('Delete error:', error);
    res.status(500).json({
      error: true,
      message: 'Failed to delete file',
      details: error.message,
    });
  }
});

// ========================================
// EXPORT ROUTER
// ========================================

module.exports = router;
