const express = require("express");
const router = express.Router();
const admin = require("../controllers/admin.controller");
const { authenticateToken, requireRole } = require("../middleware/auth");
const asyncHandler = require("../utils/asyncHandler");

// Every route here requires an admin-role token. Section 6.5: the
// promote endpoint is the highest-risk one — it still only requires
// requireRole(['admin']), same as the rest, which is the point: only
// an existing admin token can ever create another admin.
router.use(authenticateToken, requireRole(["admin"]));

router.get("/verification-queue", asyncHandler(admin.getVerificationQueue));
router.patch("/verification-queue/:id", asyncHandler(admin.reviewSubmission));
router.post("/users/:id/promote", asyncHandler(admin.promoteUser));
router.get("/analytics/active-users", asyncHandler(admin.getActiveUsers));
router.get("/analytics/top-visitors", asyncHandler(admin.getTopVisitors));
router.get("/analytics/listing-clicks", asyncHandler(admin.getListingClicks));
router.get("/analytics/overview", asyncHandler(admin.getOverviewStats));
router.get("/analytics/leads-timeseries", asyncHandler(admin.getLeadsTimeseries));
router.get("/analytics/engagement", asyncHandler(admin.getEngagementStats));
router.get("/leads", asyncHandler(admin.getLeads));

module.exports = router;
