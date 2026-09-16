const jwt = require("jsonwebtoken");

function signUserToken(user) {
  return jwt.sign(
    { id: user.id, role: user.role, email: user.email },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || "7d" }
  );
}

function signAdminToken(user) {
  // Shorter-lived than a regular session token, per Full Architecture
  // Plan Section 6.5 — least-privilege, tighter blast radius if leaked.
  return jwt.sign(
    { id: user.id, role: "admin", email: user.email },
    process.env.JWT_SECRET,
    { expiresIn: process.env.ADMIN_JWT_EXPIRES_IN || "1h" }
  );
}

module.exports = { signUserToken, signAdminToken };
