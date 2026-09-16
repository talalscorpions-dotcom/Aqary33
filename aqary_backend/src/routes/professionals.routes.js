const express = require("express");
const router = express.Router();
const professionals = require("../controllers/professionals.controller");
const { authenticateToken, requireRole } = require("../middleware/auth");
const asyncHandler = require("../utils/asyncHandler");

router.get("/", asyncHandler(professionals.listProfessionals));
router.get("/:id", asyncHandler(professionals.getProfessional));
router.get("/:id/dashboard", authenticateToken, requireRole(["professional"]), asyncHandler(professionals.getProfessionalDashboard));
router.patch("/:id", authenticateToken, requireRole(["professional"]), asyncHandler(professionals.updateProfessional));

module.exports = router;
