// ========================================
// DATABASE CONNECTION MODULE
// PostgreSQL Connection Pool
// ========================================

const { Pool } = require('pg');
require('dotenv').config();

// Create connection pool
const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'secure_print',
  max: 20,                    // Max connections in pool
  idleTimeoutMillis: 30000,   // Close idle connections after 30s
  connectionTimeoutMillis: 2000, // Timeout for connection attempt
});

// Log successful connection
pool.on('connect', () => {
  console.log('✅ Database pool connected');
});

// Log connection errors
pool.on('error', (err) => {
  console.error('❌ Unexpected error on idle client', err);
});

// Export query function
module.exports = {
  query: (text, params) => pool.query(text, params),
  pool: pool,
};
