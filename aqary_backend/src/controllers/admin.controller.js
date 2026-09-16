// Full Architecture Plan, Section 6.5 — Admin-Specific Controls.
// Every function here must be mounted behind requireRole(['admin']) in
// the route file — there is no additional ownership check for Admin,
// since the role itself is the boundary (least-privilege on write scope
// is enforced by which functions exist here, not by a second check).
const { query } = require("../config/db");

/**
 * GET /admin/verification-queue?status=&type=
 * BR-VER-01 — every new listing, seller, and professional submission.
 */
async function getVerificationQueue(req, res) {
  const { status = "pending", type } = req.query;
  const conditions = ["vq.status = $1"];
  const params = [status];
  let i = 2;

  if (type) { conditions.push(`vq.entity_type = $${i++}`); params.push(type); }

  const result = await query(
    `SELECT vq.* FROM verification_queue vq WHERE ${conditions.join(" AND ")} ORDER BY vq.created_at ASC`,
    params
  );
  return res.json(result.rows);
}

/**
 * PATCH /admin/verification-queue/:id
 * BR-VER-02 — approve or reject; a reason is required for rejection.
 * BR-VER-03 — for listings with video, the client must confirm the
 * video was viewed before this can be called with status=approved
 * (videoViewed flag passed from the app; enforced here, not just in UI).
 */
async function reviewSubmission(req, res) {
  const { id } = req.params;
  const { status, reason, videoViewed } = req.body; // status: approved | rejected

  if (!["approved", "rejected"].includes(status)) {
    return res.status(400).json({ error: "status must be approved or rejected." });
  }
  if (status === "rejected" && !reason) {
    return res.status(400).json({ error: "A reason is required to reject a submission." });
  }

  const queueResult = await query("SELECT * FROM verification_queue WHERE id = $1", [id]);
  if (queueResult.rows.length === 0) return res.status(404).json({ error: "Queue entry not found." });
  const entry = queueResult.rows[0];

  if (entry.entity_type === "listing" && status === "approved") {
    const mediaResult = await query(
      "SELECT 1 FROM property_media WHERE property_id = $1 AND media_type = 'video' LIMIT 1",
      [entry.entity_id]
    );
    if (mediaResult.rows.length > 0 && !videoViewed) {
      return res.status(400).json({ error: "This listing includes video — confirm videoViewed before approving (BR-VER-03)." });
    }
  }

  await query(
    "UPDATE verification_queue SET status = $1, reviewed_by = $2, reviewed_at = now() WHERE id = $3",
    [status, req.user.id, id]
  );

  const newStatus = status === "approved" ? "verified" : "rejected";
  const targetTable = {
    listing: "properties",
    seller: "users",
    professional: "professionals", // Note: also check service_providers if not found (Section 6.2)
  }[entry.entity_type];

  if (entry.entity_type === "professional") {
    const inDev = await query("UPDATE professionals SET verification_status = $1 WHERE id = $2 RETURNING id", [newStatus, entry.entity_id]);
    if (inDev.rows.length === 0) {
      await query("UPDATE service_providers SET verification_status = $1 WHERE id = $2", [newStatus, entry.entity_id]);
    }
  } else if (targetTable) {
    await query(`UPDATE ${targetTable} SET verification_status = $1 WHERE id = $2`, [newStatus, entry.entity_id]);
  }

  return res.json({ message: `Submission ${status}.`, entityType: entry.entity_type, entityId: entry.entity_id });
}

/**
 * POST /admin/users/:id/promote
 * Admin-only; grants the admin role to an existing account.
 * This is the single highest-risk endpoint in the platform (Section 6.5) —
 * it is already behind requireRole(['admin']) in the route, meaning only
 * an existing admin token can ever reach this function.
 */
async function promoteUser(req, res) {
  const { id } = req.params;
  const result = await query(
    "UPDATE users SET role = 'admin' WHERE id = $1 RETURNING id, email, role",
    [id]
  );
  if (result.rows.length === 0) return res.status(404).json({ error: "User not found." });

  console.warn(`[security] User ${id} promoted to admin by ${req.user.id} at ${new Date().toISOString()}`);
  return res.json(result.rows[0]);
}

/**
 * GET /admin/analytics/active-users?role=&period=
 */
async function getActiveUsers(req, res) {
  const { role, period = "30" } = req.query;
  const conditions = [`opened_at > now() - INTERVAL '${Number(period)} days'`];
  const params = [];
  if (role) {
    conditions.push(`role = $1`);
    params.push(role);
  }
  const result = await query(
    `SELECT role, COUNT(DISTINCT user_id) AS active_users
     FROM app_sessions WHERE ${conditions.join(" AND ")} GROUP BY role`,
    params
  );
  return res.json(result.rows);
}

/**
 * GET /admin/analytics/top-visitors?period=&limit=10
 * Admin excluded from the ranking, per Section 1.4 of the Dashboard/Auth
 * roadmap document — admin logins are operational, not engagement.
 */
async function getTopVisitors(req, res) {
  const { period = "30", limit = 10 } = req.query;
  const result = await query(
    `SELECT u.id, u.full_name, u.role, COUNT(s.id) AS session_count
     FROM app_sessions s
     JOIN users u ON u.id = s.user_id
     WHERE s.opened_at > now() - INTERVAL '${Number(period)} days' AND u.role != 'admin'
     GROUP BY u.id, u.full_name, u.role
     ORDER BY session_count DESC
     LIMIT $1`,
    [limit]
  );
  return res.json(result.rows);
}

/**
 * GET /admin/analytics/listing-clicks?period=&sort=
 * Platform-wide click ranking, independent of which seller owns each listing.
 */
async function getListingClicks(req, res) {
  const { limit = 20 } = req.query;
  const result = await query(
    `SELECT id, title, owner_id, view_count, click_count
     FROM properties ORDER BY click_count DESC LIMIT $1`,
    [limit]
  );
  return res.json(result.rows);
}

module.exports = {
  getVerificationQueue, reviewSubmission, promoteUser,
  getActiveUsers, getTopVisitors, getListingClicks,
};
