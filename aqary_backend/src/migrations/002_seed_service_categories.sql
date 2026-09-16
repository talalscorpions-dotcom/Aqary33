-- service_categories ships empty from 001_init.sql, but auth.controller.js's
-- signUp() looks up professionalType against it by name (ILIKE) for every
-- maintenance_service sign-up — with no rows, that path always 400s.
-- Seeded to match the categories the Flutter sign-up form offers
-- (MaintenanceCategory in signup_form_screen.dart). run.js re-runs every
-- .sql file on each `npm run migrate`, so this has to be idempotent itself.
INSERT INTO service_categories (name)
SELECT v.name FROM (VALUES
  ('Plumbing'),
  ('AC & Cooling'),
  ('Gas'),
  ('Kitchen'),
  ('Electrical'),
  ('Painting'),
  ('Cleaning'),
  ('Other')
) AS v(name)
WHERE NOT EXISTS (
  SELECT 1 FROM service_categories WHERE service_categories.name = v.name
);
