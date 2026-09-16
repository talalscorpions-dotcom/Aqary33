const express = require("express");
const router = express.Router();
const maintenance = require("../controllers/maintenance.controller");
const { authenticateToken, requireRole } = require("../middleware/auth");
const asyncHandler = require("../utils/asyncHandler");

router.get("/providers", asyncHandler(maintenance.listProviders));
router.get("/providers/:id", asyncHandler(maintenance.getProvider));
router.get("/providers/:id/dashboard", authenticateToken, requireRole(["professional"]), asyncHandler(maintenance.getProviderDashboard));
router.patch("/providers/:id", authenticateToken, requireRole(["professional"]), asyncHandler(maintenance.updateProvider));
router.post("/bookings", authenticateToken, requireRole(["buyer"]), asyncHandler(maintenance.createBooking));

module.exports = router;
