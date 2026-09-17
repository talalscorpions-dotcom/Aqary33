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

/**
 * GET /admin/analytics/overview
 * The one call behind the Dashboard tab's stat cards — logins, leads, and
 * approvals all summarized together so the UI can render everything above
 * the fold from a single request. "Leads" here means any buyer/renter
 * action that asks a seller, developer, or service provider to follow up:
 * a scheduled property viewing (`viewings`) or a maintenance booking
 * request (`service_bookings`) — there's no separate "leads" table, these
 * two are what a real-estate lead actually is in this schema.
 */
async function getOverviewStats(req, res) {
  const [users, signups, sessions, properties, approvals, leads, contacts] = await Promise.all([
    query(`SELECT role, COUNT(*) AS count FROM users GROUP BY role`),
    query(
      `SELECT COUNT(*) FILTER (WHERE created_at::date = current_date) AS today,
              COUNT(*) FILTER (WHERE created_at > now() - INTERVAL '7 days') AS this_week
       FROM users`
    ),
    query(
      `SELECT COUNT(*) FILTER (WHERE opened_at::date = current_date) AS logins_today,
              COUNT(DISTINCT user_id) FILTER (WHERE opened_at > now() - INTERVAL '7 days') AS active_7d,
              COUNT(DISTINCT user_id) FILTER (WHERE opened_at > now() - INTERVAL '30 days') AS active_30d
       FROM app_sessions`
    ),
    query(
      `SELECT COUNT(*) AS total, COUNT(*) FILTER (WHERE verification_status = 'verified') AS verified
       FROM properties`
    ),
    query(`SELECT COUNT(*) AS pending FROM verification_queue WHERE status = 'pending'`),
    query(
      `SELECT COUNT(*) AS total,
              COUNT(*) FILTER (WHERE created_at::date = current_date) AS today,
              COUNT(*) FILTER (WHERE created_at > now() - INTERVAL '7 days') AS this_week,
              COUNT(*) FILTER (WHERE created_at > now() - INTERVAL '30 days') AS this_month,
              COUNT(*) FILTER (WHERE status = 'completed') AS closed
       FROM (
         SELECT created_at, status FROM viewings
         UNION ALL
         SELECT created_at, status FROM service_bookings
       ) all_leads`
    ),
    query(
      `SELECT COUNT(*) FILTER (WHERE interaction_type = 'contact_click') AS contact_clicks,
              COUNT(*) FILTER (WHERE interaction_type = 'phone_reveal') AS phone_reveals
       FROM property_interactions
       WHERE created_at > now() - INTERVAL '30 days'`
    ),
  ]);

  const leadsRow = leads.rows[0];
  const total = Number(leadsRow.total);
  const closed = Number(leadsRow.closed);

  return res.json({
    usersByRole: Object.fromEntries(users.rows.map((r) => [r.role, Number(r.count)])),
    newSignupsToday: Number(signups.rows[0].today),
    newSignupsThisWeek: Number(signups.rows[0].this_week),
    loginsToday: Number(sessions.rows[0].logins_today),
    activeUsers7d: Number(sessions.rows[0].active_7d),
    activeUsers30d: Number(sessions.rows[0].active_30d),
    totalProperties: Number(properties.rows[0].total),
    verifiedProperties: Number(properties.rows[0].verified),
    pendingApprovals: Number(approvals.rows[0].pending),
    leadsTotal: total,
    leadsToday: Number(leadsRow.today),
    leadsThisWeek: Number(leadsRow.this_week),
    leadsThisMonth: Number(leadsRow.this_month),
    leadsClosed: closed,
    leadsCloseRate: total > 0 ? Math.round((closed / total) * 1000) / 10 : 0,
    contactClicks30d: Number(contacts.rows[0].contact_clicks),
    phoneReveals30d: Number(contacts.rows[0].phone_reveals),
  });
}

/**
 * GET /admin/analytics/leads-timeseries?bucket=day|week|month&days=30
 * Leads created vs. closed per bucket — the "per day, week, month" trend
 * behind the Dashboard's lead chart.
 */
async function getLeadsTimeseries(req, res) {
  const { bucket = "day", days = "30" } = req.query;
  if (!["day", "week", "month"].includes(bucket)) {
    return res.status(400).json({ error: "bucket must be day, week, or month." });
  }
  const result = await query(
    `SELECT date_trunc($1, created_at) AS bucket,
            COUNT(*) AS created,
            COUNT(*) FILTER (WHERE status = 'completed') AS closed
     FROM (
       SELECT created_at, status FROM viewings
       UNION ALL
       SELECT created_at, status FROM service_bookings
     ) all_leads
     WHERE created_at > now() - INTERVAL '${Number(days)} days'
     GROUP BY bucket
     ORDER BY bucket`,
    [bucket]
  );
  // COUNT(*) comes back from pg as a string (bigint precision safety) —
  // convert here so the client can treat these as plain numbers.
  return res.json(
    result.rows.map((r) => ({
      bucket: r.bucket,
      created: Number(r.created),
      closed: Number(r.closed),
    }))
  );
}

/**
 * GET /admin/analytics/engagement?period=30
 * Breakdown of buyer-side interest signals (Business Development
 * Architecture, Section 5) — how many contact clicks, saves, etc.
 */
async function getEngagementStats(req, res) {
  const { period = "30" } = req.query;
  const result = await query(
    `SELECT COUNT(*) FILTER (WHERE interaction_type = 'contact_click') AS contact_clicks,
            COUNT(*) FILTER (WHERE interaction_type = 'phone_reveal') AS phone_reveals,
            COUNT(*) FILTER (WHERE interaction_type = 'schedule_click') AS schedule_clicks,
            COUNT(*) FILTER (WHERE interaction_type = 'save') AS saves,
            COUNT(*) FILTER (WHERE interaction_type = 'share') AS shares
     FROM property_interactions
     WHERE created_at > now() - INTERVAL '${Number(period)} days'`
  );
  const row = result.rows[0];
  return res.json({
    contactClicks: Number(row.contact_clicks),
    phoneReveals: Number(row.phone_reveals),
    scheduleClicks: Number(row.schedule_clicks),
    saves: Number(row.saves),
    shares: Number(row.shares),
  });
}

/**
 * GET /admin/leads?status=&limit=50
 * The real leads list behind the Leads tab — a scheduled viewing or a
 * maintenance booking request, whichever asked a seller/provider to
 * follow up with a buyer. Replaces what used to be hardcoded sample data.
 */
async function getLeads(req, res) {
  const { status, limit = 50 } = req.query;
  const params = [];
  let statusFilter = "";
  if (status) {
    params.push(status);
    statusFilter = `WHERE status = $${params.length}`;
  }
  params.push(Number(limit));

  const result = await query(
    `SELECT * FROM (
       SELECT v.id, 'viewing' AS lead_type, v.status, v.created_at,
              v.requested_date, v.requested_time,
              u.full_name AS requester_name, u.phone AS requester_phone, u.email AS requester_email,
              p.title AS subject_title
       FROM viewings v
       JOIN users u ON u.id = v.requester_id
       JOIN properties p ON p.id = v.property_id
       UNION ALL
       SELECT sb.id, 'service_booking' AS lead_type, sb.status, sb.created_at,
              sb.requested_date, NULL AS requested_time,
              u.full_name AS requester_name, u.phone AS requester_phone, u.email AS requester_email,
              COALESCE(spu.full_name, 'Service Provider') AS subject_title
       FROM service_bookings sb
       JOIN users u ON u.id = sb.requester_id
       JOIN service_providers sp ON sp.id = sb.provider_id
       JOIN users spu ON spu.id = sp.user_id
     ) all_leads
     ${statusFilter}
     ORDER BY created_at DESC
     LIMIT $${params.length}`,
    params
  );
  return res.json(result.rows);
}

module.exports = {
  getVerificationQueue, reviewSubmission, promoteUser,
  getActiveUsers, getTopVisitors, getListingClicks,
  getOverviewStats, getLeadsTimeseries, getEngagementStats, getLeads,
};
