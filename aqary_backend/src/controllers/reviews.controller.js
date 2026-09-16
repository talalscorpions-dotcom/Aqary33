// Full Architecture Plan — shared reviews across property, seller,
// professional, and service_provider entities (BR-PROP-05, BR-DEV-03,
// BR-MAINT-03). One review per user per entity, enforced by the
// database's UNIQUE constraint (Business Development Architecture, Section 6).
const { query } = require("../config/db");

const ENTITY_TABLE = {
  property: "properties",
  professional: "professionals",
  service_provider: "service_providers",
  // "seller" reviews live against the users table itself — handled separately below.
};

/**
 * POST /reviews
 * body: { entityType, entityId, stars, comment }
 */
async function createReview(req, res) {
  const { entityType, entityId, stars, comment } = req.body;

  if (!["property", "seller", "professional", "service_provider"].includes(entityType)) {
    return res.status(400).json({ error: "Invalid entityType." });
  }
  if (!stars || stars < 1 || stars > 5) {
    return res.status(400).json({ error: "stars must be between 1 and 5." });
  }

  try {
    const result = await query(
      `INSERT INTO reviews (entity_type, entity_id, reviewer_id, stars, comment)
       VALUES ($1,$2,$3,$4,$5) RETURNING *`,
      [entityType, entityId, req.user.id, stars, comment || null]
    );

    await recalculateRating(entityType, entityId);

    // A low rating with a comment routes into the admin queue for review,
    // per BR-VER-04 — a trust signal, not only a UX one.
    if (stars <= 2 && comment) {
      await query(
        `INSERT INTO verification_queue (entity_type, entity_id, status)
         VALUES ($1, $2, 'pending')
         ON CONFLICT DO NOTHING`,
        [entityType === "property" ? "listing" : entityType, entityId]
      );
    }

    return res.status(201).json(result.rows[0]);
  } catch (err) {
    if (err.code === "23505") { // unique_violation
      return res.status(409).json({ error: "You have already reviewed this." });
    }
    throw err;
  }
}

/**
 * GET /reviews?entityType=&entityId=
 */
async function getReviews(req, res) {
  const { entityType, entityId } = req.query;
  const result = await query(
    `SELECT r.*, u.full_name AS reviewer_name FROM reviews r
     JOIN users u ON u.id = r.reviewer_id
     WHERE r.entity_type = $1 AND r.entity_id = $2
     ORDER BY r.created_at DESC`,
    [entityType, entityId]
  );
  return res.json(result.rows);
}

/**
 * Recomputes and writes the denormalised rating/review_count on the
 * entity's own table, so a card never has to aggregate reviews live.
 * Full Architecture Plan, Section 5.2 note on denormalisation.
 */
async function recalculateRating(entityType, entityId) {
  const table = ENTITY_TABLE[entityType];
  if (!table) return; // "seller" ratings live on users; extend here if needed.

  const agg = await query(
    "SELECT AVG(stars)::numeric(2,1) AS avg_rating, COUNT(*) AS cnt FROM reviews WHERE entity_type = $1 AND entity_id = $2",
    [entityType, entityId]
  );
  const { avg_rating, cnt } = agg.rows[0];
  await query(`UPDATE ${table} SET rating = $1, review_count = $2 WHERE id = $3`, [avg_rating, cnt, entityId]);
}

module.exports = { createReview, getReviews };
