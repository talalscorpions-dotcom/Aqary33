const express = require("express");
const router = express.Router();
const properties = require("../controllers/properties.controller");
const { authenticateToken, requireRole } = require("../middleware/auth");
const asyncHandler = require("../utils/asyncHandler");

// Optional auth: search/detail work for logged-out browsing too, but we
// still want req.user set when a token IS present (for save/view logic).
const optionalAuth = (req, res, next) => {
  if (!req.headers["authorization"]) return next();
  return authenticateToken(req, res, next);
};

router.get("/", optionalAuth, asyncHandler(properties.searchProperties));
router.get("/:id", optionalAuth, asyncHandler(properties.getProperty));

router.post("/", authenticateToken, requireRole(["seller"]), asyncHandler(properties.createProperty));
router.patch("/:id", authenticateToken, requireRole(["seller"]), asyncHandler(properties.updateProperty));

router.post("/:id/media/upload-url", authenticateToken, requireRole(["seller"]), asyncHandler(properties.getMediaUploadUrl));
router.post("/:id/media", authenticateToken, requireRole(["seller"]), asyncHandler(properties.confirmMedia));
router.delete("/:id/media/:mediaId", authenticateToken, requireRole(["seller"]), asyncHandler(properties.deleteMedia));

router.post("/:id/viewings", authenticateToken, requireRole(["buyer"]), asyncHandler(properties.requestViewing));
router.post("/:id/interact", authenticateToken, asyncHandler(properties.logInteraction));
router.post("/:id/save", authenticateToken, requireRole(["buyer"]), asyncHandler(properties.saveProperty));
router.delete("/:id/save", authenticateToken, requireRole(["buyer"]), asyncHandler(properties.unsaveProperty));

module.exports = router;
