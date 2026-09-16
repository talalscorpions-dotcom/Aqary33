const express = require("express");
const router = express.Router();
const users = require("../controllers/users.controller");
const { authenticateToken, requireRole } = require("../middleware/auth");
const asyncHandler = require("../utils/asyncHandler");

router.get("/me/activity", authenticateToken, requireRole(["buyer"]), asyncHandler(users.getMyActivity));
router.get("/me/listings", authenticateToken, requireRole(["seller"]), asyncHandler(users.getMyListings));
router.get("/me/dashboard-summary", authenticateToken, requireRole(["seller"]), asyncHandler(users.getMyDashboardSummary));

module.exports = router;
