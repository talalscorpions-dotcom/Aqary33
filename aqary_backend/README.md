# AQARY Backend

Node.js + Express + PostgreSQL backend for AQARY, per the **Full Architecture
Plan (A to Z)**. Implements every endpoint and table specified there:
Properties (all four categories), Development & Building, Maintenance
Service, the Loan Calculator, the four-role auth model with
middleware-based enforcement, and the admin verification queue.

## What's real vs. what needs finishing

**Real and complete:**
- Full database schema (`src/migrations/001_init.sql`) — every table from
  the architecture plan, ready to run.
- Every controller function is real logic against the database — not stubs.
- The role + ownership middleware chain (`src/middleware/auth.js`) exactly
  as specified in Section 6.3, with working code, not pseudocode.
- The Loan Calculator's amortization math (verified independently — see
  below).
- Password hashing, JWT issuance, and the Forgot Password flow with its
  security property (identical response whether or not the account exists).

**Needs your attention before this is production-ready:**
- **Email/SMS delivery for password reset** — `auth.controller.js`
  currently only `console.log`s the reset link. Wire up a real provider
  (SES, Twilio, etc.) — search for the `TODO` comment.
- **This was never run against a live database.** The sandbox this was
  built in has no internet access, so `npm install` couldn't fetch
  packages and there was no PostgreSQL instance to test against. Every
  file passed Node's syntax checker (`node -c`), and the Loan Calculator's
  pure math was tested directly and verified against an independently
  computed reference value — but the database queries themselves are
  unexercised. Run the migration and hit a few endpoints yourself before
  trusting this in front of real users.
- **Bank rates in `loans.controller.js` are placeholders** — replace
  `BANK_RATES` with real, current figures before this reaches anyone.

## Setup

```bash
npm install
cp .env.example .env
# edit .env with your real DATABASE_URL, JWT_SECRET, and AWS credentials

npm run migrate    # creates every table
npm start           # or `npm run dev` to auto-restart on file changes
```

Confirm it's running: `curl http://localhost:3000/health`

## Project Structure

```
src/
  config/       db.js (PostgreSQL pool), s3.js (pre-signed URL helpers)
  middleware/   auth.js — authenticateToken, requireRole, assertOwnership
  controllers/  one file per module — the actual business logic
  routes/       wires controllers to Express routes with the middleware chain
  migrations/   001_init.sql (schema) + run.js (runner)
  utils/        jwt.js, asyncHandler.js
  app.js        Express app assembly
  server.js     entry point
```

## The Middleware Pattern (Section 6.3)

Every protected route follows the same shape:

```js
router.patch("/properties/:id",
  authenticateToken,           // verifies JWT, sets req.user
  requireRole(["seller"]),     // 403 if role doesn't match
  asyncHandler(properties.updateProperty)  // ownership check happens inside
);
```

`assertOwnership()` in `middleware/auth.js` is a helper, not a middleware —
call it inside the controller once you've fetched the resource, since the
ownership check needs the row's `owner_id`/`user_id` to compare against.

## Role Model (Section 6.1–6.2)

Four roles: `buyer`, `seller`, `professional`, `admin`. A `professional`
account has a `professionalCategory` (`development_building` or
`maintenance_service`) decided at sign-up, which determines whether their
profile lives in the `professionals` table or the `service_providers`
table — same role, same permissions, different data source. See
`auth.controller.js::signUp` for exactly how this branches.

## Admin Safety Note

`POST /admin/users/:id/promote` is mounted behind the same
`requireRole(["admin"])` as every other admin route — meaning only an
existing admin's token can ever call it. Bootstrap the *first* admin with:

```bash
npm run create-admin -- --email=you@example.com --phone=+96891234567
```

It prompts for a password (never taken as a CLI arg, so it can't end up
in shell history) and creates the row with `mfa_enabled = false`. Finish
setup by enrolling MFA — there is deliberately no way to skip this, since
`adminLogIn` refuses to issue a token until it's done:

```bash
curl -X POST http://localhost:3000/auth/admin/mfa/enroll \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","password":"<the password you just set>"}'
# -> { "secret": "...", "otpauthUrl": "otpauth://totp/..." }
# Add the secret to an authenticator app (or convert otpauthUrl to a QR
# code), then confirm with the 6-digit code it produces:

curl -X POST http://localhost:3000/auth/admin/mfa/confirm \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","mfaCode":"123456"}'
```

## Testing the Loan Calculator Independently

```bash
node -e "
const { calculateMonthlyPayment } = require('./src/controllers/loans.controller.js');
console.log(calculateMonthlyPayment(166500, 5.49, 25)); // OMR 1021.462/month
"
```
