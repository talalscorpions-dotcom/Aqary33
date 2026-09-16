// Full Architecture Plan — /users/me/* endpoints.
// Business Development Architecture document, Sections 3 and 4.
const { query } = require("../config/db");

/**
 * GET /users/me/activity
 * BR-DASH-01 — Buyer's saved/viewed/viewing-request summary.
 */
async function getMyActivity(req, res) {
  const userId = req.user.id;

  const [saved, viewedCount, viewings] = await Promise.all([
    query(
      `SELECT p.* FROM saved_properties sp JOIN properties p ON p.id = sp.property_id
       WHERE sp.user_id = $1 ORDER BY sp.created_at DESC`,
      [userId]
    ),
    query(
      `SELECT COUNT(DISTINCT property_id) AS viewed_count FROM property_views
       WHERE viewer_id = $1 AND viewed_at > now() - INTERVAL '30 days'`,
      [userId]
    ),
    query(
      `SELECT v.*, p.title, p.price FROM viewings v JOIN properties p ON p.id = v.property_id
       WHERE v.requester_id = $1 ORDER BY v.requested_date DESC`,
      [userId]
    ),
  ]);

  return res.json({
    savedProperties: saved.rows,
    propertiesViewedLast30Days: Number(viewedCount.rows[0].viewed_count),
    viewingRequests: viewings.rows,
  });
}

/**
 * GET /users/me/listings
 * BR-DASH-02 — Seller's own listings, with compact view/click counts.
 */
async function getMyListings(req, res) {
  const result = await query(
    `SELECT id, title, price, verification_status, view_count, click_count
     FROM properties WHERE owner_id = $1 ORDER BY created_at DESC`,
    [req.user.id]
  );
  return res.json(result.rows);
}

/**
 * GET /users/me/dashboard-summary?period=
 * BR-DASH-03 — Seller's Performance Dashboard top-line stats.
 * Works for Seller (properties) accounts. Professional accounts use
 * /professionals/:id/dashboard or /maintenance/providers/:id/dashboard
 * instead, per Section 6.2's two-data-source pattern.
 */
async function getMyDashboardSummary(req, res) {
  const { period = "30" } = req.query;
  const userId = req.user.id;

  const totals = await query(
    `SELECT COUNT(*) AS active_listings,
            COALESCE(SUM(view_count), 0) AS total_views,
            COALESCE(SUM(click_count), 0) AS total_clicks
     FROM properties WHERE owner_id = $1 AND verification_status = 'verified'`,
    [userId]
  );

  const topProperties = await query(
    `SELECT id, title, view_count, click_count FROM properties
     WHERE owner_id = $1 ORDER BY view_count DESC LIMIT 10`,
    [userId]
  );

  const dailyViews = await query(
    `SELECT DATE(pv.viewed_at) AS day, COUNT(*) AS views
     FROM property_views pv JOIN properties p ON p.id = pv.property_id
     WHERE p.owner_id = $1 AND pv.viewed_at > now() - INTERVAL '${Number(period)} days'
     GROUP BY DATE(pv.viewed_at) ORDER BY day`,
    [userId]
  );

  return res.json({
    ...totals.rows[0],
    topProperties: topProperties.rows,
    dailyViews: dailyViews.rows,
  });
}

module.exports = { getMyActivity, getMyListings, getMyDashboardSummary };
