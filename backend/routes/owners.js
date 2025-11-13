const express = require("express");
const router = express.Router();
const db = require("../database");
const AuthService = require("../services/authService");
const crypto = require("crypto");

// POST /api/owners/register
router.post("/register", async (req, res) => {
  try {
    const { email, password, full_name } = req.body;
    if (!email || !password)
      return res.status(400).json({ error: "email and password required" });
    if (!AuthService.validateEmail(email))
      return res.status(400).json({ error: "Invalid email" });

    const exists = await db.query("SELECT id FROM owners WHERE email = $1", [
      email,
    ]);
    if (exists.rows.length > 0)
      return res.status(409).json({ error: "Owner already exists" });

    const passwordHash = await AuthService.hashPassword(password);

    // Generate RSA keypair for owner
    const { publicKey, privateKey } = crypto.generateKeyPairSync("rsa", {
      modulusLength: 2048,
      publicKeyEncoding: { type: "spki", format: "pem" },
      privateKeyEncoding: { type: "pkcs8", format: "pem" },
    });

    const insertQ = `
      INSERT INTO owners (email, password_hash, full_name, public_key)
      VALUES ($1, $2, $3, $4)
      RETURNING id, email, full_name, created_at
    `;

    const result = await db.query(insertQ, [
      email,
      passwordHash,
      full_name || null,
      publicKey,
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

    // IMPORTANT: Return private key in response once (owner must save it securely)
    res
      .status(201)
      .json({
        success: true,
        accessToken,
        refreshToken,
        owner: { id: owner.id, email: owner.email, full_name: owner.full_name },
        privateKey,
      });
  } catch (error) {
    console.error("Owner register error:", error);
    res
      .status(500)
      .json({
        error: true,
        message: "Owner registration failed",
        details: error.message,
      });
  }
});

// POST /api/owners/login
router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password)
      return res.status(400).json({ error: "email and password required" });

    const result = await db.query(
      "SELECT id, email, password_hash, full_name FROM owners WHERE email = $1",
      [email]
    );
    if (result.rows.length === 0)
      return res.status(401).json({ error: "Invalid credentials" });

    const owner = result.rows[0];
    const ok = await AuthService.comparePassword(password, owner.password_hash);
    if (!ok) return res.status(401).json({ error: "Invalid credentials" });

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
    res
      .status(500)
      .json({
        error: true,
        message: "Owner login failed",
        details: error.message,
      });
  }
});

// GET /api/owners/public-key (requires owner id from token in future)
router.get("/public-key/:ownerId", async (req, res) => {
  try {
    const { ownerId } = req.params;
    const result = await db.query(
      "SELECT public_key FROM owners WHERE id = $1",
      [ownerId]
    );
    if (result.rows.length === 0)
      return res.status(404).json({ error: "Owner not found" });
    res.json({ success: true, public_key: result.rows[0].public_key });
  } catch (error) {
    console.error("Get public key error:", error);
    res
      .status(500)
      .json({
        error: true,
        message: "Failed to fetch public key",
        details: error.message,
      });
  }
});

module.exports = router;
