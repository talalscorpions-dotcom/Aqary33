// Full Architecture Plan, Section 7 — Development & Building endpoints.
const { query } = require("../config/db");
const { assertOwnership } = require("../middleware/auth");

/**
 * GET /professionals?category=&type=&region=&city=
 * Directory search (BR-DEV-01, BR-DEV-02). Only verified professionals shown.
 */
async function listProfessionals(req, res) {
  const { type, region, city, page = 1, limit = 20 } = req.query;
  const conditions = ["verification_status = 'verified'"];
  const params = [];
  let i = 1;

  if (type) { conditions.push(`professional_type = $${i++}`); params.push(type); }
  if (region) { conditions.push(`region = $${i++}`); params.push(region); }
  if (city) { conditions.push(`city = $${i++}`); params.push(city); }

  const offset = (Number(page) - 1) * Number(limit);
  params.push(limit, offset);

  const result = await query(
    `SELECT id, professional_type, company_name, bio, region, city, rating, review_count
     FROM professionals WHERE ${conditions.join(" AND ")}
     ORDER BY rating DESC NULLS LAST LIMIT $${i++} OFFSET $${i++}`,
    params
  );
  return res.json({ results: result.rows, page: Number(page), limit: Number(limit) });
}

/**
 * GET /professionals/:id
 * Also logs a profile view, mirroring the property view pattern.
 */
async function getProfessional(req, res) {
  const { id } = req.params;
  const result = await query("SELECT * FROM professionals WHERE id = $1", [id]);
  if (result.rows.length === 0) return res.status(404).json({ error: "Professional not found." });

  await query("UPDATE professionals SET profile_view_count = profile_view_count + 1 WHERE id = $1", [id]);
  return res.json(result.rows[0]);
}

/**
 * PATCH /professionals/:id
 * BR-DEV-05 — a Professional edits only their own profile.
 */
async function updateProfessional(req, res) {
  const { id } = req.params;
  const existing = await query("SELECT user_id FROM professionals WHERE id = $1", [id]);
  if (existing.rows.length === 0) return res.status(404).json({ error: "Professional not found." });
  if (!assertOwnership(existing.rows[0].user_id, req, res)) return;

  const allowed = ["company_name", "bio", "region", "city"];
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

  const result = await query(`UPDATE professionals SET ${updates.join(", ")} WHERE id = $${i} RETURNING *`, params);
  return res.json(result.rows[0]);
}

/**
 * GET /professionals/:id/dashboard
 * BR-DEV-06 — the Professional's own engagement analytics.
 * Ownership enforced: a Professional may only view their own dashboard.
 */
async function getProfessionalDashboard(req, res) {
  const { id } = req.params;
  const result = await query(
    "SELECT user_id, profile_view_count, contact_count, rating, review_count FROM professionals WHERE id = $1",
    [id]
  );
  if (result.rows.length === 0) return res.status(404).json({ error: "Professional not found." });
  if (!assertOwnership(result.rows[0].user_id, req, res)) return;

  return res.json(result.rows[0]);
}

module.exports = { listProfessionals, getProfessional, updateProfessional, getProfessionalDashboard };
