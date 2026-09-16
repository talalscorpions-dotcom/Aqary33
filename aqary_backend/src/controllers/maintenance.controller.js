// Full Architecture Plan, Section 7 — Maintenance Service endpoints.
// Mirrors professionals.controller.js exactly, per Section 6.2 — one
// dashboard pattern, two data sources.
const { query } = require("../config/db");
const { assertOwnership } = require("../middleware/auth");

/**
 * GET /maintenance/providers?category=&region=&city=
 * BR-MAINT-01, BR-MAINT-02.
 */
async function listProviders(req, res) {
  const { category, region, city, page = 1, limit = 20 } = req.query;
  const conditions = ["sp.verification_status = 'verified'"];
  const params = [];
  let i = 1;

  if (category) { conditions.push(`sc.name ILIKE $${i++}`); params.push(category); }
  if (region) { conditions.push(`sp.region = $${i++}`); params.push(region); }
  if (city) { conditions.push(`sp.city = $${i++}`); params.push(city); }

  const offset = (Number(page) - 1) * Number(limit);
  params.push(limit, offset);

  const result = await query(
    `SELECT sp.id, sc.name AS category, sp.region, sp.city, sp.latitude, sp.longitude,
            sp.rating, sp.review_count
     FROM service_providers sp
     JOIN service_categories sc ON sc.id = sp.category_id
     WHERE ${conditions.join(" AND ")}
     ORDER BY sp.rating DESC NULLS LAST LIMIT $${i++} OFFSET $${i++}`,
    params
  );
  return res.json({ results: result.rows, page: Number(page), limit: Number(limit) });
}

async function getProvider(req, res) {
  const { id } = req.params;
  const result = await query(
    `SELECT sp.*, sc.name AS category FROM service_providers sp
     JOIN service_categories sc ON sc.id = sp.category_id WHERE sp.id = $1`,
    [id]
  );
  if (result.rows.length === 0) return res.status(404).json({ error: "Specialist not found." });

  await query("UPDATE service_providers SET profile_view_count = profile_view_count + 1 WHERE id = $1", [id]);
  return res.json(result.rows[0]);
}

/**
 * PATCH /maintenance/providers/:id
 * BR-MAINT-05 — a Professional edits only their own specialist profile.
 */
async function updateProvider(req, res) {
  const { id } = req.params;
  const existing = await query("SELECT user_id FROM service_providers WHERE id = $1", [id]);
  if (existing.rows.length === 0) return res.status(404).json({ error: "Specialist not found." });
  if (!assertOwnership(existing.rows[0].user_id, req, res)) return;

  const allowed = ["region", "city"];
  const updates = [];
  const params = [];
  let i = 1;
  for (const field of allowed) {
    if (req.body[field] !== undefined) {
      updates.push(`${field} = $${i++}`);
      params.push(req.body[field]);
    }
  }
  if (updates.length === 0) return res.status(400).json({ error: "No updatable fields provided." });
  params.push(id);

  const result = await query(`UPDATE service_providers SET ${updates.join(", ")} WHERE id = $${i} RETURNING *`, params);
  return res.json(result.rows[0]);
}

/**
 * POST /maintenance/bookings
 * BR-MAINT-04 — same request/confirm pattern as property viewings.
 */
async function createBooking(req, res) {
  const { providerId, requestedDate } = req.body;
  if (!providerId || !requestedDate) {
    return res.status(400).json({ error: "providerId and requestedDate are required." });
  }

  const result = await query(
    `INSERT INTO service_bookings (provider_id, requester_id, requested_date)
     VALUES ($1,$2,$3) RETURNING *`,
    [providerId, req.user.id, requestedDate]
  );
  await query("UPDATE service_providers SET booking_count = booking_count + 1 WHERE id = $1", [providerId]);

  return res.status(201).json(result.rows[0]);
}

/**
 * GET /maintenance/providers/:id/dashboard
 * BR-MAINT-06.
 */
async function getProviderDashboard(req, res) {
  const { id } = req.params;
  const result = await query(
    "SELECT user_id, profile_view_count, booking_count, rating, review_count FROM service_providers WHERE id = $1",
    [id]
  );
  if (result.rows.length === 0) return res.status(404).json({ error: "Specialist not found." });
  if (!assertOwnership(result.rows[0].user_id, req, res)) return;

  return res.json(result.rows[0]);
}

module.exports = { listProviders, getProvider, updateProvider, createBooking, getProviderDashboard };
