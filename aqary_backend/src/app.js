require("dotenv").config();
const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");

const authRoutes = require("./routes/auth.routes");
const propertiesRoutes = require("./routes/properties.routes");
const viewingsRoutes = require("./routes/viewings.routes");
const professionalsRoutes = require("./routes/professionals.routes");
const maintenanceRoutes = require("./routes/maintenance.routes");
const loansRoutes = require("./routes/loans.routes");
const reviewsRoutes = require("./routes/reviews.routes");
const adminRoutes = require("./routes/admin.routes");
const usersRoutes = require("./routes/users.routes");

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: "2mb" }));

// General API rate limit — auth routes have their own tighter limiter.
app.use(rateLimit({ windowMs: 15 * 60 * 1000, max: 300 }));

app.get("/health", (req, res) => res.json({ status: "ok", service: "aqary-backend" }));

app.use("/auth", authRoutes);
app.use("/properties", propertiesRoutes);
app.use("/viewings", viewingsRoutes);
app.use("/professionals", professionalsRoutes);
app.use("/maintenance", maintenanceRoutes);
app.use("/loans", loansRoutes);
app.use("/reviews", reviewsRoutes);
app.use("/admin", adminRoutes);
app.use("/users", usersRoutes);

// 404
app.use((req, res) => res.status(404).json({ error: "Not found." }));

// Centralised error handler — every asyncHandler-wrapped controller
// funnels rejected promises here instead of crashing the process.
app.use((err, req, res, next) => {
  console.error(err);
  const status = err.status || 500;
  res.status(status).json({ error: err.message || "Internal server error." });
});

module.exports = app;
