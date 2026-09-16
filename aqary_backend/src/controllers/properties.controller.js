// Full Architecture Plan, Section 7 — Properties endpoints.
const { v4: uuidv4 } = require("uuid");
const { query } = require("../config/db");
const { getUploadUrl } = require("../config/s3");
const { assertOwnership } = require("../middleware/auth");

/**
 * GET /properties?region=&city=&category=&listing_type=&property_type=&minPrice=&maxPrice=
 * The one filterable search endpoint behind every Properties screen (BR-PROP-01).
 * Only Verified listings are returned (BR-PROP-06).
 */
async function searchProperties(req, res) {
  const { region, city, category, listing_type, property_type, minPrice, maxPrice, page = 1, limit = 20 } = req.query;

  const conditions = ["verification_status = 'verified'"];
  const params = [];
  let i = 1;

  if (region) { conditions.push(`region = $${i++}`); params.push(region); }
  if (city) { conditions.push(`city = $${i++}`); params.push(city); }
  if (category) { conditions.push(`category = $${i++}`); params.push(category); }
  if (listing_type) { conditions.push(`listing_type = $${i++}`); params.push(listing_type); }
  if (property_type) { conditions.push(`property_type = $${i++}`); params.push(property_type); }
  if (minPrice) { conditions.push(`price >= $${i++}`); params.push(minPrice); }
  if (maxPrice) { conditions.push(`price <= $${i++}`); params.push(maxPrice); }

  const offset = (Number(page) - 1) * Number(limit);
  params.push(limit, offset);

  const sql = `
    SELECT id, category, listing_type, property_type, title, price, currency,
           region, city, location_detail, latitude, longitude, area_sqm,
           bedrooms, bathrooms, rating, review_count
    FROM properties
    WHERE ${conditions.join(" AND ")}
    ORDER BY created_at DESC
    LIMIT $${i++} OFFSET $${i++}
  `;
  const result = await query(sql, params);
  return res.json({ results: result.rows, page: Number(page), limit: Number(limit) });
}

/**
 * GET /properties/:id
 * Single listing detail, including media gallery and rating (BR-PROP-07 support).
 * Also logs a view (Business Development Architecture, property_views) unless
 * the viewer is the listing's own owner.
 */
async function getProperty(req, res) {
  const { id } = req.params;
  const propResult = await query("SELECT * FROM properties WHERE id = $1", [id]);
  if (propResult.rows.length === 0) {
    return res.status(404).json({ error: "Property not found." });
  }
  const property = propResult.rows[0];

  const mediaResult = await query(
    "SELECT id, media_type, url, thumbnail_url, duration_seconds FROM property_media WHERE property_id = $1 ORDER BY sort_order",
    [id]
  );

  // Log the view — deduplicated per user per 24h window, per the Business
  // Development Architecture document's metric definition.
  const viewerId = req.user ? req.user.id : null;
  if (!viewerId || viewerId !== property.owner_id) {
    const recentView = viewerId
      ? await query(
          `SELECT id FROM property_views
           WHERE property_id = $1 AND viewer_id = $2 AND viewed_at > now() - INTERVAL '24 hours'`,
          [id, viewerId]
        )
      : { rows: [] };
    if (recentView.rows.length === 0) {
      await query(
        "INSERT INTO property_views (property_id, viewer_id, source) VALUES ($1,$2,$3)",
        [id, viewerId, req.query.source || "search_results"]
      );
      await query("UPDATE properties SET view_count = view_count + 1 WHERE id = $1", [id]);
    }
  }

  return res.json({ ...property, media: mediaResult.rows });
}

/**
 * POST /properties
 * Seller submits a new listing; defaults to pending (BR-PROP-06, BR-VER-01).
 * requireRole(['seller']) is applied in the route; no ownership check
 * needed here since the row doesn't exist yet.
 */
async function createProperty(req, res) {
  const {
    category, listingType, propertyType, title, description, price, currency,
    region, city, locationDetail, latitude, longitude, areaSqm, bedrooms, bathrooms,
    titleDeedUrl,
  } = req.body;

  if (!category || !title || !price || !region || !city) {
    return res.status(400).json({ error: "category, title, price, region, and city are required." });
  }

  const result = await query(
    `INSERT INTO properties
       (owner_id, category, listing_type, property_type, title, description, price, currency,
        region, city, location_detail, latitude, longitude, area_sqm, bedrooms, bathrooms, title_deed_url)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17)
     RETURNING *`,
    [
      req.user.id, category, listingType, propertyType, title, description || null, price, currency || "OMR",
      region, city, locationDetail || null, latitude || null, longitude || null,
      areaSqm || null, bedrooms || null, bathrooms || null, titleDeedUrl || null,
    ]
  );
  const property = result.rows[0];

  await query(
    "INSERT INTO verification_queue (entity_type, entity_id, status) VALUES ('listing', $1, 'pending')",
    [property.id]
  );

  return res.status(201).json(property);
}

/**
 * PATCH /properties/:id
 * Seller edits their own listing. Two-layer check per Section 6.3:
 * requireRole(['seller']) in the route, resource ownership here.
 */
async function updateProperty(req, res) {
  const { id } = req.params;
  const existing = await query("SELECT owner_id FROM properties WHERE id = $1", [id]);
  if (existing.rows.length === 0) {
    return res.status(404).json({ error: "Property not found." });
  }
  if (!assertOwnership(existing.rows[0].owner_id, req, res)) return;

  const allowed = ["title", "description", "price", "bedrooms", "bathrooms", "location_detail"];
  const updates = [];
  const params = [];
  let i = 1;
  for (const field of allowed) {
    if (req.body[field] !== undefined) {
      updates.push(`${field} = $${i++}`);
      params.push(req.body[field]);
    }
  }
  if (updates.length === 0) {
    return res.status(400).json({ error: "No updatable fields provided." });
  }
  updates.push(`updated_at = now()`);
  params.push(id);

  const result = await query(
    `UPDATE properties SET ${updates.join(", ")} WHERE id = $${i} RETURNING *`,
    params
  );
  return res.json(result.rows[0]);
}

/**
 * POST /properties/:id/media/upload-url
 * Issues a pre-signed S3 URL for a photo or video (BR-PROP-03).
 */
async function getMediaUploadUrl(req, res) {
  const { id } = req.params;
  const { mediaType, contentType } = req.body; // mediaType: photo|video

  const existing = await query("SELECT owner_id FROM properties WHERE id = $1", [id]);
  if (existing.rows.length === 0) return res.status(404).json({ error: "Property not found." });
  if (!assertOwnership(existing.rows[0].owner_id, req, res)) return;

  const extension = contentType === "video/mp4" ? "mp4" : "jpg";
  const objectKey = `properties/${id}/${mediaType}-${uuidv4()}.${extension}`;
  const { uploadUrl, publicUrl } = await getUploadUrl("media", objectKey, contentType, 300);

  return res.json({ uploadUrl, publicUrl, expiresInSeconds: 300 });
}

/**
 * POST /properties/:id/media
 * Confirms an upload finished; saves the record (BR-PROP-03 limits enforced here).
 */
async function confirmMedia(req, res) {
  const { id } = req.params;
  const { mediaType, url, thumbnailUrl, durationSeconds } = req.body;

  const existing = await query("SELECT owner_id FROM properties WHERE id = $1", [id]);
  if (existing.rows.length === 0) return res.status(404).json({ error: "Property not found." });
  if (!assertOwnership(existing.rows[0].owner_id, req, res)) return;

  const countResult = await query(
    "SELECT media_type, COUNT(*) FROM property_media WHERE property_id = $1 GROUP BY media_type",
    [id]
  );
  const counts = Object.fromEntries(countResult.rows.map((r) => [r.media_type, Number(r.count)]));

  if (mediaType === "photo" && (counts.photo || 0) >= 20) {
    return res.status(400).json({ error: "Maximum of 20 photos per listing." });
  }
  if (mediaType === "video") {
    if ((counts.video || 0) >= 1) {
      return res.status(400).json({ error: "Only one video per listing." });
    }
    if (durationSeconds && durationSeconds > 90) {
      return res.status(400).json({ error: "Video must be 90 seconds or less." });
    }
  }

  const result = await query(
    `INSERT INTO property_media (property_id, media_type, url, thumbnail_url, duration_seconds)
     VALUES ($1,$2,$3,$4,$5) RETURNING *`,
    [id, mediaType, url, thumbnailUrl || null, durationSeconds || null]
  );
  return res.status(201).json(result.rows[0]);
}

/**
 * DELETE /properties/:id/media/:mediaId
 */
async function deleteMedia(req, res) {
  const { id, mediaId } = req.params;
  const existing = await query("SELECT owner_id FROM properties WHERE id = $1", [id]);
  if (existing.rows.length === 0) return res.status(404).json({ error: "Property not found." });
  if (!assertOwnership(existing.rows[0].owner_id, req, res)) return;

  await query("DELETE FROM property_media WHERE id = $1 AND property_id = $2", [mediaId, id]);
  return res.status(204).send();
}

/**
 * POST /properties/:id/viewings
 * Buyer/renter submits a scheduled viewing request (BR-PROP-04).
 */
async function requestViewing(req, res) {
  const { id } = req.params;
  const { requestedDate, requestedTime } = req.body;
  if (!requestedDate || !requestedTime) {
    return res.status(400).json({ error: "requestedDate and requestedTime are required." });
  }

  const propResult = await query("SELECT verification_status FROM properties WHERE id = $1", [id]);
  if (propResult.rows.length === 0) return res.status(404).json({ error: "Property not found." });
  if (propResult.rows[0].verification_status !== "verified") {
    return res.status(400).json({ error: "Viewings can only be scheduled on verified listings." });
  }

  const result = await query(
    `INSERT INTO viewings (property_id, requester_id, requested_date, requested_time)
     VALUES ($1,$2,$3,$4) RETURNING *`,
    [id, req.user.id, requestedDate, requestedTime]
  );

  await query(
    "INSERT INTO property_interactions (property_id, user_id, interaction_type) VALUES ($1,$2,'schedule_click')",
    [id, req.user.id]
  );

  return res.status(201).json(result.rows[0]);
}

/**
 * PATCH /viewings/:id
 * Host (the listing's owner) confirms, reschedules, or cancels.
 */
async function updateViewing(req, res) {
  const { id } = req.params;
  const { status } = req.body; // confirmed | rejected | completed | cancelled

  const viewingResult = await query(
    `SELECT v.*, p.owner_id FROM viewings v JOIN properties p ON p.id = v.property_id WHERE v.id = $1`,
    [id]
  );
  if (viewingResult.rows.length === 0) return res.status(404).json({ error: "Viewing not found." });
  const viewing = viewingResult.rows[0];

  const isHost = viewing.owner_id === req.user.id;
  const isRequester = viewing.requester_id === req.user.id;
  if (!isHost && !isRequester) {
    return res.status(403).json({ error: "You are not part of this viewing." });
  }

  const result = await query("UPDATE viewings SET status = $1 WHERE id = $2 RETURNING *", [status, id]);
  return res.json(result.rows[0]);
}

/**
 * POST /properties/:id/interact
 * Logs a click-type interaction (Business Development Architecture, Section 5).
 */
async function logInteraction(req, res) {
  const { id } = req.params;
  const { interactionType } = req.body; // contact_click | schedule_click | save | share | phone_reveal

  await query(
    "INSERT INTO property_interactions (property_id, user_id, interaction_type) VALUES ($1,$2,$3)",
    [id, req.user.id, interactionType]
  );
  if (["contact_click", "schedule_click", "phone_reveal"].includes(interactionType)) {
    await query("UPDATE properties SET click_count = click_count + 1 WHERE id = $1", [id]);
  }
  return res.status(201).json({ message: "Interaction logged." });
}

/**
 * POST /properties/:id/save  and  DELETE /properties/:id/save
 * Buyer's Saved list.
 */
async function saveProperty(req, res) {
  const { id } = req.params;
  await query(
    `INSERT INTO saved_properties (user_id, property_id) VALUES ($1,$2)
     ON CONFLICT (user_id, property_id) DO NOTHING`,
    [req.user.id, id]
  );
  await query("UPDATE properties SET save_count = save_count + 1 WHERE id = $1", [id]);
  return res.status(201).json({ message: "Saved." });
}

async function unsaveProperty(req, res) {
  const { id } = req.params;
  await query("DELETE FROM saved_properties WHERE user_id = $1 AND property_id = $2", [req.user.id, id]);
  await query("UPDATE properties SET save_count = GREATEST(save_count - 1, 0) WHERE id = $1", [id]);
  return res.status(204).send();
}

module.exports = {
  searchProperties, getProperty, createProperty, updateProperty,
  getMediaUploadUrl, confirmMedia, deleteMedia,
  requestViewing, updateViewing, logInteraction, saveProperty, unsaveProperty,
};
