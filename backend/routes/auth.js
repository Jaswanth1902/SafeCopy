const express = require("express");
const router = express.Router();
const db = require("../database");
const AuthService = require("../services/authService");

// POST /api/auth/register
router.post("/register", async (req, res) => {
  try {
    const { email, password, full_name } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: "email and password required" });
    }

    if (!AuthService.validateEmail(email)) {
      return res.status(400).json({ error: "Invalid email format" });
    }

    const { isValid, errors } = AuthService.validatePassword(password);
    if (!isValid) {
      return res.status(400).json({ error: "Weak password", details: errors });
    }

    // Check existing user
    const exists = await db.query("SELECT id FROM users WHERE email = $1", [
      email,
    ]);
    if (exists.rows.length > 0) {
      return res.status(409).json({ error: "User already exists" });
    }

    const passwordHash = await AuthService.hashPassword(password);

    const insertQ = `
      INSERT INTO users (email, password_hash, full_name)
      VALUES ($1, $2, $3)
      RETURNING id, email, full_name, created_at
    `;

    const result = await db.query(insertQ, [
      email,
      passwordHash,
      full_name || null,
    ]);
    const user = result.rows[0];

    const payload = { sub: user.id, email: user.email, role: "user" };
    const accessToken = AuthService.generateAccessToken(payload);
    const refreshToken = AuthService.generateRefreshToken(payload);

    // Store hashed refresh token in sessions table
    const hashedRefresh = AuthService.hashToken(refreshToken);
    const expiresAt = new Date(Date.now() + 7 * 24 * 3600 * 1000); // 7 days
    await db.query(
      `INSERT INTO sessions (user_id, token_hash, refresh_token_hash, expires_at, refresh_expires_at, is_valid)
       VALUES ($1, $2, $3, $4, $4, true)`,
      [user.id, AuthService.hashToken(accessToken), hashedRefresh, expiresAt]
    );

    res
      .status(201)
      .json({
        success: true,
        accessToken,
        refreshToken,
        user: { id: user.id, email: user.email, full_name: user.full_name },
      });
  } catch (error) {
    console.error("Auth register error:", error);
    res
      .status(500)
      .json({
        error: true,
        message: "Registration failed",
        details: error.message,
      });
  }
});

// POST /api/auth/login
router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password)
      return res.status(400).json({ error: "email and password required" });

    const q = `SELECT id, email, password_hash, full_name FROM users WHERE email = $1`;
    const result = await db.query(q, [email]);
    if (result.rows.length === 0)
      return res.status(401).json({ error: "Invalid credentials" });

    const user = result.rows[0];
    const ok = await AuthService.comparePassword(password, user.password_hash);
    if (!ok) return res.status(401).json({ error: "Invalid credentials" });

    const payload = { sub: user.id, email: user.email, role: "user" };
    const accessToken = AuthService.generateAccessToken(payload);
    const refreshToken = AuthService.generateRefreshToken(payload);

    // Store session
    const hashedRefresh = AuthService.hashToken(refreshToken);
    const expiresAt = new Date(Date.now() + 7 * 24 * 3600 * 1000);
    await db.query(
      `INSERT INTO sessions (user_id, token_hash, refresh_token_hash, expires_at, refresh_expires_at, is_valid)
       VALUES ($1, $2, $3, $4, $4, true)`,
      [user.id, AuthService.hashToken(accessToken), hashedRefresh, expiresAt]
    );

    res.json({
      success: true,
      accessToken,
      refreshToken,
      user: { id: user.id, email: user.email, full_name: user.full_name },
    });
  } catch (error) {
    console.error("Auth login error:", error);
    res
      .status(500)
      .json({ error: true, message: "Login failed", details: error.message });
  }
});

// POST /api/auth/refresh-token
router.post("/refresh-token", async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken)
      return res.status(400).json({ error: "refreshToken required" });

    let payload;
    try {
      payload = AuthService.verifyRefreshToken(refreshToken);
    } catch (err) {
      return res.status(401).json({ error: "Invalid refresh token" });
    }

    // Check sessions table for hashed refresh token
    const hashed = AuthService.hashToken(refreshToken);
    const q =
      "SELECT user_id FROM sessions WHERE refresh_token_hash = $1 AND is_valid = true LIMIT 1";
    const r = await db.query(q, [hashed]);
    if (r.rows.length === 0)
      return res.status(401).json({ error: "Refresh token not recognized" });

    const userId = r.rows[0].user_id;
    const newPayload = {
      sub: userId,
      email: payload.email,
      role: payload.role || "user",
    };
    const accessToken = AuthService.generateAccessToken(newPayload);
    const newRefresh = AuthService.generateRefreshToken(newPayload);

    // Update session with new refresh token hash
    await db.query(
      "UPDATE sessions SET refresh_token_hash = $1, token_hash = $2 WHERE user_id = $3",
      [
        AuthService.hashToken(newRefresh),
        AuthService.hashToken(accessToken),
        userId,
      ]
    );

    res.json({ success: true, accessToken, refreshToken: newRefresh });
  } catch (error) {
    console.error("Refresh token error:", error);
    res
      .status(500)
      .json({
        error: true,
        message: "Could not refresh token",
        details: error.message,
      });
  }
});

// POST /api/auth/logout
router.post("/logout", async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken)
      return res.status(400).json({ error: "refreshToken required" });

    const hashed = AuthService.hashToken(refreshToken);
    await db.query(
      "UPDATE sessions SET is_valid = false, revoked_at = NOW() WHERE refresh_token_hash = $1",
      [hashed]
    );

    res.json({ success: true, message: "Logged out" });
  } catch (error) {
    console.error("Logout error:", error);
    res
      .status(500)
      .json({ error: true, message: "Logout failed", details: error.message });
  }
});

module.exports = router;
