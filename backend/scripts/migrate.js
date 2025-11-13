const fs = require("fs");
const path = require("path");
const { Pool } = require("pg");
require("dotenv").config();

async function runMigrations() {
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
  });

  const client = await pool.connect();

  try {
    const schemaPath = path.join(
      __dirname,
      "..",
      "..",
      "database",
      "schema.sql"
    );
    const sql = fs.readFileSync(schemaPath, "utf8");

    console.log("Running migrations from", schemaPath);

    // Start a transaction and ensure we rollback on any failure
    await client.query('BEGIN');
    try {
      await client.query(sql);
      await client.query('COMMIT');
      console.log("✓ Database schema created successfully");
    } catch (txError) {
      // Attempt to rollback the transaction; if rollback fails, log that as well
      try {
        await client.query('ROLLBACK');
        console.error('Transaction rolled back due to error.');
      } catch (rbError) {
        console.error('Rollback failed:', rbError);
      }
      // Re-throw so outer catch sets exit code and logs the original error
      throw txError;
    }
  } catch (error) {
    console.error("✗ Migration failed:", error);
    process.exitCode = 1;
  } finally {
    client.release();
    await pool.end();
  }
}

runMigrations();
