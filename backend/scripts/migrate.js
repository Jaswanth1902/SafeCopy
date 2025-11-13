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
    await client.query(sql);

    console.log("✓ Database schema created successfully");
  } catch (error) {
    console.error("✗ Migration failed:", error);
    process.exitCode = 1;
  } finally {
    client.release();
    await pool.end();
  }
}

runMigrations();
