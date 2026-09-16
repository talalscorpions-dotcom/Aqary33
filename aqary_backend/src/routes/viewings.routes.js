const express = require("express");
const router = express.Router();
const properties = require("../controllers/properties.controller");
const { authenticateToken } = require("../middleware/auth");
const asyncHandler = require("../utils/asyncHandler");

// PATCH /viewings/:id — host confirms/rejects, either party cancels.
// Ownership (host or requester) is checked inside the controller, since
// either role may legitimately update it.
router.patch("/:id", authenticateToken, asyncHandler(properties.updateViewing));

module.exports = router;
