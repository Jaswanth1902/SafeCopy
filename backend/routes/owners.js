const express = require("express");
const router = express.Router();
const db = require("../database");
const AuthService = require("../services/authService");
const { verifyToken, verifyRole } = require("../middleware/auth");

// ========================================
// SECURITY NOTE: Private Key Handling
// ========================================
// Private keys are NEVER generated or stored on the server.
// Owners MUST generate keypairs client-side and securely store private keys locally.
// The server only accepts and stores public keys.
// This prevents accidental exposure of private keys via logs, responses, or backups.
// ========================================

// POST /api/owners/register
// Requires client to generate RSA keypair and submit public key
router.post("/register", async (req, res) => {
  try {
    const { email, password, full_name, public_key } = req.body;

    // Validate required fields
    if (!email || !password) {
      return res.status(400).json({ error: "email and password required" });
    }
    if (!public_key) {
      return res.status(400).json({
        error: "public_key is required",
        message:
          "You must generate an RSA-2048 keypair client-side and submit the public key (PEM format)",
      });
    }

    if (!AuthService.validateEmail(email)) {
      return res.status(400).json({ error: "Invalid email format" });
    }

    // Validate public key format (basic check for PEM format)
    if (!public_key.startsWith("-----BEGIN PUBLIC KEY-----")) {
      return res.status(400).json({
        error: "invalid_public_key_format",
        message: "Public key must be in PEM format (SPKI)",
      });
    }

    const exists = await db.query("SELECT id FROM owners WHERE email = $1", [
      email,
    ]);
    if (exists.rows.length > 0) {
      return res.status(409).json({ error: "Owner already exists" });
    }

    const passwordHash = await AuthService.hashPassword(password);

    const insertQ = `
      INSERT INTO owners (email, password_hash, full_name, public_key)
      VALUES ($1, $2, $3, $4)
      RETURNING id, email, full_name, created_at
    `;

    const result = await db.query(insertQ, [
      email,
      passwordHash,
      full_name || null,
      public_key,
    ]);
    const owner = result.rows[0];

    const payload = { sub: owner.id, email: owner.email, role: "owner" };
    const accessToken = AuthService.generateAccessToken(payload);
    const refreshToken = AuthService.generateRefreshToken(payload);

    // Store session
    const hashedRefresh = AuthService.hashToken(refreshToken);
    const expiresAt = new Date(Date.now() + 7 * 24 * 3600 * 1000);
    await db.query(
      `INSERT INTO sessions (owner_id, token_hash, refresh_token_hash, expires_at, refresh_expires_at, is_valid)
       VALUES ($1, $2, $3, $4, $4, true)`,
      [owner.id, AuthService.hashToken(accessToken), hashedRefresh, expiresAt]
    );

    // SECURITY: Do NOT return any private key material
    res.status(201).json({
      success: true,
      message: "Owner registered successfully",
      accessToken,
      refreshToken,
      owner: { id: owner.id, email: owner.email, full_name: owner.full_name },
      note: "Your private key was generated and stored securely on your device. Keep it safe and never share it.",
    });
  } catch (error) {
    console.error("Owner register error:", error);
    const isDev = process.env.NODE_ENV === "development";
    res.status(500).json({
      error: true,
      message: "Owner registration failed",
      ...(isDev && { details: error.message }),
    });
  }
});

// POST /api/owners/login
router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: "email and password required" });
    }

    const result = await db.query(
      "SELECT id, email, password_hash, full_name FROM owners WHERE email = $1",
      [email]
    );
    if (result.rows.length === 0) {
      return res.status(401).json({ error: "Invalid credentials" });
    }

    const owner = result.rows[0];
    const ok = await AuthService.comparePassword(password, owner.password_hash);
    if (!ok) {
      return res.status(401).json({ error: "Invalid credentials" });
    }

    const payload = { sub: owner.id, email: owner.email, role: "owner" };
    const accessToken = AuthService.generateAccessToken(payload);
    const refreshToken = AuthService.generateRefreshToken(payload);

    const hashedRefresh = AuthService.hashToken(refreshToken);
    const expiresAt = new Date(Date.now() + 7 * 24 * 3600 * 1000);
    await db.query(
      `INSERT INTO sessions (owner_id, token_hash, refresh_token_hash, expires_at, refresh_expires_at, is_valid)
       VALUES ($1, $2, $3, $4, $4, true)`,
      [owner.id, AuthService.hashToken(accessToken), hashedRefresh, expiresAt]
    );

    res.json({
      success: true,
      accessToken,
      refreshToken,
      owner: { id: owner.id, email: owner.email, full_name: owner.full_name },
    });
  } catch (error) {
    console.error("Owner login error:", error);
    const isDev = process.env.NODE_ENV === "development";
    res.status(500).json({
      error: true,
      message: "Owner login failed",
      ...(isDev && { details: error.message }),
    });
  }
});

// GET /api/owners/public-key/:ownerId
// Retrieve public key for a specific owner (no auth required - keys are public)
router.get("/public-key/:ownerId", async (req, res) => {
  try {
    const { ownerId } = req.params;

    // Validate ownerId format
    if (!ownerId || ownerId.length < 5) {
      return res.status(400).json({ error: "Invalid owner ID" });
    }

    const result = await db.query(
      "SELECT public_key FROM owners WHERE id = $1",
      [ownerId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Owner not found" });
    }

    res.json({ success: true, public_key: result.rows[0].public_key });
  } catch (error) {
    console.error("Get public key error:", error);
    const isDev = process.env.NODE_ENV === "development";
    res.status(500).json({
      error: true,
      message: "Failed to fetch public key",
      ...(isDev && { details: error.message }),
    });
  }
});

// GET /api/owners/me (requires authentication)
// Get authenticated owner's profile (does NOT return private key)
router.get("/me", verifyToken, verifyRole(["owner"]), async (req, res) => {
  try {
    const ownerId = req.user.sub;

    const result = await db.query(
      "SELECT id, email, full_name, created_at FROM owners WHERE id = $1",
      [ownerId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Owner not found" });
    }

    res.json({ success: true, owner: result.rows[0] });
  } catch (error) {
    console.error("Get owner profile error:", error);
    const isDev = process.env.NODE_ENV === "development";
    res.status(500).json({
      error: true,
      message: "Failed to fetch owner profile",
      ...(isDev && { details: error.message }),
    });
  }
});

module.exports = router;
