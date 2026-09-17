// Full Architecture Plan, Section 6 — Authentication, Roles & Access Control.
const bcrypt = require("bcryptjs");
const crypto = require("crypto");
const { authenticator } = require("otplib");
const { query } = require("../config/db");
const { signUserToken, signAdminToken } = require("../utils/jwt");

const SALT_ROUNDS = 12;

/**
 * POST /auth/sign-up
 * Handles all four sign-up paths from the role picker (BR-AUTH-09, BR-AUTH-11):
 *   - buyer:        no extra fields
 *   - seller:       requires agentLicenceUrl + photoIdUrl -> pending review
 *   - professional: requires category (development_building|maintenance_service),
 *                   type, licenceUrl + photoIdUrl -> pending review,
 *                   and writes a row into professionals or service_providers
 *                   depending on category (Section 6.2).
 * Admin is never created here — see BR-AUTH-03 / promoteUser below.
 */
async function signUp(req, res) {
  const {
    role, phone, email, password, fullName,
    agentLicenceUrl, photoIdUrl,
    professionalCategory, professionalType, professionalLicenceUrl,
    region, city, companyName,
  } = req.body;

  if (!["buyer", "seller", "professional"].includes(role)) {
    return res.status(400).json({ error: "role must be buyer, seller, or professional." });
  }
  if (!email || !password || !phone) {
    return res.status(400).json({ error: "phone, email, and password are required." });
  }

  const existing = await query("SELECT id FROM users WHERE email = $1", [email]);
  if (existing.rows.length > 0) {
    return res.status(409).json({ error: "An account with this email already exists." });
  }

  const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);
  const verificationStatus = role === "buyer" ? "active" : "pending";

  const userResult = await query(
    `INSERT INTO users
       (phone, email, password_hash, role, full_name, agent_licence_url,
        professional_licence_url, photo_id_url, verification_status)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
     RETURNING id, email, role, verification_status`,
    [
      phone, email, passwordHash, role, fullName || null,
      role === "seller" ? agentLicenceUrl : null,
      role === "professional" ? professionalLicenceUrl : null,
      photoIdUrl || null,
      verificationStatus,
    ]
  );
  const user = userResult.rows[0];

  // Professional accounts also get a row in the category-specific table,
  // per BR-AUTH-11 and Full Architecture Plan Section 6.2.
  if (role === "professional") {
    if (!["development_building", "maintenance_service"].includes(professionalCategory)) {
      return res.status(400).json({ error: "professionalCategory must be development_building or maintenance_service." });
    }
    if (professionalCategory === "development_building") {
      await query(
        `INSERT INTO professionals (user_id, professional_type, company_name, licence_number, region, city)
         VALUES ($1,$2,$3,$4,$5,$6)`,
        [user.id, professionalType, companyName || null, professionalLicenceUrl || null, region || null, city || null]
      );
    } else {
      const categoryRow = await query("SELECT id FROM service_categories WHERE name ILIKE $1", [professionalType]);
      if (categoryRow.rows.length === 0) {
        return res.status(400).json({ error: `Unknown maintenance category: ${professionalType}` });
      }
      await query(
        `INSERT INTO service_providers (user_id, category_id, licence_number, region, city)
         VALUES ($1,$2,$3,$4,$5)`,
        [user.id, categoryRow.rows[0].id, professionalLicenceUrl || null, region || null, city || null]
      );
    }
  }

  // Every non-buyer submission enters the shared verification queue (BR-VER-01).
  if (role !== "buyer") {
    await query(
      `INSERT INTO verification_queue (entity_type, entity_id, status)
       VALUES ($1, $2, 'pending')`,
      [role === "seller" ? "seller" : "professional", user.id]
    );
  }

  return res.status(201).json({ user, message: verificationStatus === "pending" ? "Account created — pending verification." : "Account created." });
}

/**
 * POST /auth/log-in
 * Unchanged endpoint shape, but the token now carries role, so the
 * Flutter routing guard (Section 6.3) can send the user to the right
 * home screen without a second lookup.
 */
async function logIn(req, res) {
  const { email, password } = req.body;
  const result = await query("SELECT * FROM users WHERE email = $1", [email]);
  const user = result.rows[0];

  if (!user || !(await bcrypt.compare(password, user.password_hash))) {
    return res.status(401).json({ error: "Invalid email or password." });
  }
  if (user.role === "admin") {
    return res.status(403).json({ error: "Admin accounts must use /auth/admin/log-in." });
  }

  const token = signUserToken(user);
  await query(
    "INSERT INTO app_sessions (user_id, role, device) VALUES ($1,$2,$3)",
    [user.id, user.role, req.body.device || null]
  );
  return res.json({
    token,
    user: { id: user.id, email: user.email, role: user.role, verificationStatus: user.verification_status },
  });
}

/**
 * POST /auth/admin/log-in
 * Separate endpoint enforcing MFA before issuing a token — Section 6.5.
 * A compromised buyer/seller/professional credential can never reach
 * admin functions, since it was never issued through this path.
 */
async function adminLogIn(req, res) {
  const { email, password, mfaCode } = req.body;
  const result = await query("SELECT * FROM users WHERE email = $1 AND role = 'admin'", [email]);
  const user = result.rows[0];

  if (!user || !(await bcrypt.compare(password, user.password_hash))) {
    return res.status(401).json({ error: "Invalid email or password." });
  }
  if (!user.mfa_enabled || !user.mfa_secret) {
    return res.status(500).json({ error: "Admin account is missing MFA setup — contact another admin." });
  }
  const validCode = authenticator.check(mfaCode || "", user.mfa_secret);
  if (!validCode) {
    return res.status(401).json({ error: "Invalid MFA code." });
  }

  const token = signAdminToken(user);
  await query(
    "INSERT INTO app_sessions (user_id, role, device) VALUES ($1,'admin',$2)",
    [user.id, req.body.device || null]
  );
  return res.json({ token, user: { id: user.id, email: user.email, role: "admin" } });
}

/**
 * POST /auth/admin/mfa/enroll
 * First-time MFA setup for an admin account bootstrapped by
 * scripts/create-admin.js (which creates the row with mfa_enabled=false,
 * mfa_secret=NULL). Gated on the account's own password rather than an
 * admin JWT, since a not-yet-enrolled admin can never obtain one — see
 * adminLogIn's mfa_enabled check. Re-enrolling an already-active account
 * is refused so a leaked password alone can't silently take over MFA.
 */
async function adminMfaEnroll(req, res) {
  const { email, password } = req.body;
  const result = await query("SELECT * FROM users WHERE email = $1 AND role = 'admin'", [email]);
  const user = result.rows[0];

  if (!user || !(await bcrypt.compare(password, user.password_hash))) {
    return res.status(401).json({ error: "Invalid email or password." });
  }
  if (user.mfa_enabled) {
    return res.status(409).json({ error: "MFA is already enabled for this account." });
  }

  const secret = authenticator.generateSecret();
  await query("UPDATE users SET mfa_secret = $1 WHERE id = $2", [secret, user.id]);

  const otpauthUrl = authenticator.keyuri(email, "AQARY Admin", secret);
  return res.json({ secret, otpauthUrl });
}

/**
 * POST /auth/admin/mfa/confirm
 * Proves the admin actually captured the secret from /enroll into an
 * authenticator app before mfa_enabled flips on and admin login unlocks.
 */
async function adminMfaConfirm(req, res) {
  const { email, mfaCode } = req.body;
  const result = await query("SELECT * FROM users WHERE email = $1 AND role = 'admin'", [email]);
  const user = result.rows[0];

  if (!user || !user.mfa_secret) {
    return res.status(400).json({ error: "Call /auth/admin/mfa/enroll first." });
  }
  if (user.mfa_enabled) {
    return res.status(409).json({ error: "MFA is already enabled for this account." });
  }
  if (!authenticator.check(mfaCode || "", user.mfa_secret)) {
    return res.status(401).json({ error: "Invalid MFA code." });
  }

  await query("UPDATE users SET mfa_enabled = true WHERE id = $1", [user.id]);
  return res.json({ message: "MFA enabled. You can now log in." });
}

/**
 * POST /auth/forgot-password
 * BR-AUTH-12 — identical response whether or not the account exists,
 * so the endpoint can't be used to discover registered emails/phones.
 */
async function forgotPassword(req, res) {
  const { emailOrPhone } = req.body;
  const generic = { message: "If an account matches, a reset link has been sent." };

  const result = await query("SELECT id FROM users WHERE email = $1 OR phone = $1", [emailOrPhone]);
  if (result.rows.length === 0) {
    return res.json(generic); // deliberately identical to the "found" path
  }

  const userId = result.rows[0].id;
  const rawToken = crypto.randomBytes(32).toString("hex");
  const tokenHash = crypto.createHash("sha256").update(rawToken).digest("hex");
  const expiresAt = new Date(Date.now() + 30 * 60 * 1000); // 30 minutes, per BR-AUTH-12

  await query(
    `INSERT INTO password_reset_tokens (user_id, token_hash, expires_at) VALUES ($1,$2,$3)`,
    [userId, tokenHash, expiresAt]
  );

  // TODO: wire up a real email/SMS provider. Logged here for development only.
  const resetLink = `${process.env.RESET_PASSWORD_BASE_URL}?token=${rawToken}`;
  console.log(`[dev] Password reset link for ${emailOrPhone}: ${resetLink}`);

  return res.json(generic);
}

/**
 * POST /auth/reset-password
 * Consumes a valid, unexpired, unused token and sets a new password.
 */
async function resetPassword(req, res) {
  const { token, newPassword } = req.body;
  if (!token || !newPassword) {
    return res.status(400).json({ error: "token and newPassword are required." });
  }
  const tokenHash = crypto.createHash("sha256").update(token).digest("hex");

  const result = await query(
    `SELECT * FROM password_reset_tokens
     WHERE token_hash = $1 AND used_at IS NULL AND expires_at > now()`,
    [tokenHash]
  );
  if (result.rows.length === 0) {
    return res.status(400).json({ error: "This reset link is invalid or has expired." });
  }
  const resetRow = result.rows[0];

  const passwordHash = await bcrypt.hash(newPassword, SALT_ROUNDS);
  await query("UPDATE users SET password_hash = $1 WHERE id = $2", [passwordHash, resetRow.user_id]);
  await query("UPDATE password_reset_tokens SET used_at = now() WHERE id = $1", [resetRow.id]);

  return res.json({ message: "Password updated. You can now log in." });
}

module.exports = { signUp, logIn, adminLogIn, adminMfaEnroll, adminMfaConfirm, forgotPassword, resetPassword };
