// Bootstraps the first admin account. Run once per environment — every
// other admin should be created via POST /admin/users/:id/promote by an
// existing admin, per README's "Admin Safety Note".
//
// Usage: npm run create-admin -- --email=you@example.com --phone=+96891234567
// Prompts for the password interactively so it never lands in shell
// history or a screenshot — the README's old approach (a plaintext SQL
// UPDATE with a hardcoded password) was fine for a private notebook, not
// for a script that could get committed to a public repo.
require("dotenv").config();
const readline = require("readline");
const bcrypt = require("bcryptjs");
const { pool, query } = require("../src/config/db");

function parseArgs() {
  const args = {};
  for (const arg of process.argv.slice(2)) {
    const match = arg.match(/^--([^=]+)=(.*)$/);
    if (match) args[match[1]] = match[2];
  }
  return args;
}

function promptHidden(question) {
  return new Promise((resolve) => {
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
    // readline has no built-in mask; muting output is good enough for a
    // one-off local setup script.
    const originalWrite = rl._writeToOutput.bind(rl);
    rl._writeToOutput = (str) => {
      if (str.includes(question)) originalWrite(str);
    };
    rl.question(question, (answer) => {
      rl.close();
      process.stdout.write("\n");
      resolve(answer);
    });
  });
}

async function main() {
  const { email, phone } = parseArgs();
  if (!email || !phone) {
    console.error("Usage: npm run create-admin -- --email=you@example.com --phone=+96891234567");
    process.exit(1);
  }

  const existing = await query("SELECT id FROM users WHERE email = $1", [email]);
  if (existing.rows.length > 0) {
    console.error(`A user with email ${email} already exists.`);
    process.exit(1);
  }

  const password = await promptHidden("Admin password: ");
  if (!password || password.length < 8) {
    console.error("Password must be at least 8 characters.");
    process.exit(1);
  }

  const passwordHash = await bcrypt.hash(password, 12);
  const result = await query(
    `INSERT INTO users (phone, email, password_hash, role, verification_status, mfa_enabled)
     VALUES ($1, $2, $3, 'admin', 'active', false)
     RETURNING id, email`,
    [phone, email, passwordHash]
  );

  console.log(`Admin account created: ${result.rows[0].email} (${result.rows[0].id})`);
  console.log("MFA is not enabled yet — call POST /auth/admin/mfa/enroll then");
  console.log("POST /auth/admin/mfa/confirm to finish setup before logging in.");
  await pool.end();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
