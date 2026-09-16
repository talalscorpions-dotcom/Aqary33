// Runs every .sql file in this folder, in filename order.
// Usage: npm run migrate
require("dotenv").config();
const fs = require("fs");
const path = require("path");
const { pool } = require("../config/db");

async function run() {
  const dir = __dirname;
  const files = fs.readdirSync(dir).filter((f) => f.endsWith(".sql")).sort();

  if (files.length === 0) {
    console.log("No .sql migration files found in", dir);
    process.exit(0);
  }

  for (const file of files) {
    const sql = fs.readFileSync(path.join(dir, file), "utf8");
    console.log(`Running migration: ${file}`);
    try {
      await pool.query(sql);
      console.log(`  ✓ ${file} applied`);
    } catch (err) {
      console.error(`  ✗ ${file} failed:`, err.message);
      process.exit(1);
    }
  }

  console.log("All migrations applied successfully.");
  await pool.end();
}

run();
