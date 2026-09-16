const express = require("express");
const router = express.Router();
const rateLimit = require("express-rate-limit");
const auth = require("../controllers/auth.controller");
const asyncHandler = require("../utils/asyncHandler");

// Auth endpoints are the most attractive brute-force target in the
// platform — rate limit more tightly than the general API limiter.
const authLimiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 20 });

router.post("/sign-up", authLimiter, asyncHandler(auth.signUp));
router.post("/log-in", authLimiter, asyncHandler(auth.logIn));
router.post("/admin/log-in", authLimiter, asyncHandler(auth.adminLogIn));
router.post("/forgot-password", authLimiter, asyncHandler(auth.forgotPassword));
router.post("/reset-password", authLimiter, asyncHandler(auth.resetPassword));

module.exports = router;
