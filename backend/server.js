// Backend Main Server
// Secure File Printing System - Express API Server

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');

// Initialize Express App
const app = express();

// ========================================
// MIDDLEWARE
// ========================================

// Security Headers
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", 'data:', 'https:'],
    },
  },
  hsts: {
    maxAge: 31536000, // 1 year
    includeSubDomains: true,
    preload: true,
  },
}));

// CORS Configuration
app.use(cors({
  origin: process.env.CORS_ORIGIN || 'http://localhost:3000',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Body Parser
app.use(express.json({ limit: '100mb' }));
app.use(express.urlencoded({ limit: '100mb', extended: true }));

// Compression
app.use(compression());

// Logging
app.use(morgan('combined'));

// ========================================
// ERROR HANDLING MIDDLEWARE
// ========================================

app.use((err, req, res, next) => {
  console.error('Error:', err);
  
  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal Server Error';
  
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
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV,
  });
});

// API Routes
app.use('/api', require('./routes/files'));

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
    message: 'Endpoint not found',
    path: req.path,
  });
});

// ========================================
// SERVER STARTUP
// ========================================

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`\n${'='.repeat(50)}`);
  console.log(`Secure File Printing System - API Server`);
  console.log(`Server running on http://localhost:${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`${'='.repeat(50)}\n`);
});

module.exports = app;
