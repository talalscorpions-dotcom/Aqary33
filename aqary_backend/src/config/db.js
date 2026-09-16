// PostgreSQL connection pool.
// Full Architecture Plan, Section 5.1 — Amazon RDS, Bahrain region (me-south-1).
require("dotenv").config();
const { Pool } = require("pg");

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_SSL === "true" ? { rejectUnauthorized: false } : false,
});

pool.on("error", (err) => {
  // A connection outside a checked-out client failed — log and let the
  // process crash rather than run in a silently degraded state.
  console.error("Unexpected error on idle PostgreSQL client", err);
  process.exit(1);
});

module.exports = {
  pool,
  query: (text, params) => pool.query(text, params),
};
