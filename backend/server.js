// Backend Main Server
// Secure File Printing System - Express API Server

require("dotenv").config();
const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const morgan = require("morgan");
const compression = require("compression");

// ========================================
// CONFIGURATION VALIDATION
// ========================================

// Validate critical environment variables at startup
const requiredEnvVars = ["JWT_SECRET"];
for (const envVar of requiredEnvVars) {
  if (!process.env[envVar]) {
    throw new Error(`Critical: ${envVar} environment variable is not set`);
  }
  if (envVar === "JWT_SECRET" && process.env[envVar].length < 32) {
    throw new Error("Critical: JWT_SECRET must be at least 32 characters");
  }
}

// Validate CORS origin in production
if (process.env.NODE_ENV === "production" && !process.env.CORS_ORIGIN) {
  throw new Error(
    "Critical: CORS_ORIGIN must be set in production environment"
  );
}

// Initialize Express App
const app = express();

// ========================================
// MIDDLEWARE
// ========================================

// Security Headers
app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        scriptSrc: ["'self'"],
        imgSrc: ["'self'", "data:", "https:"],
      },
    },
    hsts: {
      maxAge: 31536000, // 1 year
      includeSubDomains: true,
      preload: true,
    },
  })
);

// CORS Configuration
app.use(
  cors({
    origin: process.env.CORS_ORIGIN || "http://localhost:3000",
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);

// HTTPS Enforcement (production only)
if (process.env.NODE_ENV === "production") {
  app.use((req, res, next) => {
    if (!req.secure && req.get("x-forwarded-proto") !== "https") {
      return res.status(403).json({
        error: true,
        statusCode: 403,
        message: "HTTPS is required",
      });
    }
    next();
  });
}

// Body Parser
app.use(express.json({ limit: "100mb" }));
app.use(express.urlencoded({ limit: "100mb", extended: true }));

// Compression
app.use(compression());

// Logging
app.use(morgan("combined"));

// ========================================
// ERROR HANDLING MIDDLEWARE
// ========================================

app.use((err, req, res, _next) => {
  console.error("Error:", err);

  const statusCode = err.statusCode || 500;
  const message = err.message || "Internal Server Error";

  res.status(statusCode).json({
    error: true,
    statusCode,
    message,
    timestamp: new Date().toISOString(),
  });
});

// ========================================
// ROUTES
// ========================================

// Health Check
app.get("/health", (req, res) => {
  res.json({
    status: "OK",
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV,
  });
});

// API Routes
app.use("/api", require("./routes/files"));

// Auth and Owner Routes
app.use("/api/auth", require("./routes/auth"));
app.use("/api/owners", require("./routes/owners"));

// Alternative route structure (for future expansion)
// app.use('/api/users', require('./routes/users'));
// app.use('/api/owners', require('./routes/owners'));
// app.use('/api/jobs', require('./routes/jobs'));
// app.use('/api/audit', require('./routes/audit'));

// ========================================
// 404 HANDLER
// ========================================

app.use((req, res) => {
  res.status(404).json({
    error: true,
    statusCode: 404,
    message: "Endpoint not found",
    path: req.path,
  });
});

// ========================================
// SERVER STARTUP
// ========================================

const PORT = process.env.PORT || 5000;

// Only start the server if this file is run directly
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`\n${"=".repeat(50)}`);
    console.log(`Secure File Printing System - API Server`);
    console.log(`Server running on http://localhost:${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || "development"}`);
    console.log(`${"=".repeat(50)}\n`);
  });
}

module.exports = app;
