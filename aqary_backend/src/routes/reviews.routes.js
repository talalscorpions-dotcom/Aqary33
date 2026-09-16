const express = require("express");
const router = express.Router();
const reviews = require("../controllers/reviews.controller");
const { authenticateToken } = require("../middleware/auth");
const asyncHandler = require("../utils/asyncHandler");

router.get("/", asyncHandler(reviews.getReviews));
router.post("/", authenticateToken, asyncHandler(reviews.createReview));

module.exports = router;
