// Role-based access control middleware.
// Full Architecture Plan, Section 6.3 — Middleware-Based Enforcement and Routing.
//
// Every protected route uses this chain:
//   authenticateToken  -> verifies the JWT, attaches req.user
//   requireRole([...]) -> rejects if req.user.role doesn't match
//   (the route handler itself performs any resource-ownership check)
const jwt = require("jsonwebtoken");

/**
 * Verifies the JWT from the Authorization header and attaches the
 * decoded payload (id, role) to req.user. Rejects with 401 if missing
 * or invalid — this must run before requireRole on every protected route.
 */
function authenticateToken(req, res, next) {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1]; // "Bearer <token>"

  if (!token) {
    return res.status(401).json({ error: "Missing authentication token." });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, payload) => {
    if (err) {
      return res.status(401).json({ error: "Invalid or expired token." });
    }
    req.user = payload; // { id, role, professionalCategory? }
    next();
  });
}

/**
 * Rejects with 403 unless req.user.role is one of the allowed roles.
 * Must run after authenticateToken. This is the role layer only —
 * resource-ownership checks (e.g. "is this your listing?") happen
 * separately, inside the route handler, per Section 6.3.
 */
function requireRole(allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ error: "Not authenticated." });
    }
    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ error: "Forbidden — insufficient role." });
    }
    next();
  };
}

/**
 * Resource-ownership helper — call this inside a route handler after
 * requireRole, once the resource has been fetched, per the pattern in
 * Section 6.3. Not a middleware itself, since it needs the fetched row.
 */
function assertOwnership(resourceOwnerId, req, res) {
  if (resourceOwnerId !== req.user.id) {
    res.status(403).json({ error: "You do not own this resource." });
    return false;
  }
  return true;
}

module.exports = { authenticateToken, requireRole, assertOwnership };
