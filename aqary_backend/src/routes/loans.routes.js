const express = require("express");
const router = express.Router();
const loans = require("../controllers/loans.controller");

// No auth required — BR-LOAN-01: any user, no account needed.
router.get("/estimate", loans.estimate);

module.exports = router;
