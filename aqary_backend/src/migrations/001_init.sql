-- AQARY — full schema, per the Full Architecture Plan (A to Z), Section 5.2.
-- Run via `npm run migrate`. Idempotent-ish: uses IF NOT EXISTS throughout
-- so it's safe to re-run in development.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- USERS & AUTH
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
  id                        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  phone                     VARCHAR(20) NOT NULL,
  email                     VARCHAR(255) UNIQUE NOT NULL,
  password_hash             VARCHAR(255) NOT NULL,
  role                      VARCHAR(12) NOT NULL DEFAULT 'buyer',
    -- buyer | seller | professional | admin
  full_name                 VARCHAR(255),
  agent_licence_url         TEXT,           -- seller accounts
  professional_licence_url  TEXT,           -- professional accounts
  photo_id_url              TEXT,
  mfa_enabled               BOOLEAN DEFAULT false,   -- admin accounts only
  mfa_secret                TEXT,
  verification_status       VARCHAR(20) DEFAULT 'active',
    -- buyer: active; seller/professional: pending|verified|rejected
  created_at                TIMESTAMP DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

CREATE TABLE IF NOT EXISTS password_reset_tokens (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID REFERENCES users(id) ON DELETE CASCADE,
  token_hash  VARCHAR(255) NOT NULL,
  expires_at  TIMESTAMP NOT NULL,
  used_at     TIMESTAMP,
  created_at  TIMESTAMP DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_password_reset_user ON password_reset_tokens(user_id);

-- ============================================================
-- PROPERTIES
-- ============================================================
CREATE TABLE IF NOT EXISTS properties (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id              UUID REFERENCES users(id),
  category              VARCHAR(20) NOT NULL,
    -- residential | commercial | agriculture | industrial
  listing_type          VARCHAR(10),         -- rent | sale
  property_type         VARCHAR(20),         -- villa|apartment|land|building|office|shop|farm_house
  title                 VARCHAR(255) NOT NULL,
  description           TEXT,
  price                 DECIMAL(12,3) NOT NULL,
  currency              VARCHAR(3) DEFAULT 'OMR',
  region                VARCHAR(100) NOT NULL,   -- Governorate
  city                  VARCHAR(100) NOT NULL,   -- Wilayat
  location_detail       VARCHAR(255),
  latitude              DECIMAL(9,6),
  longitude             DECIMAL(9,6),
  area_sqm              DECIMAL(8,2),
  bedrooms              INT,
  bathrooms             INT,
  title_deed_url        TEXT,
  verification_status   VARCHAR(20) DEFAULT 'pending',
  rating                DECIMAL(2,1),
  review_count          INT DEFAULT 0,
  view_count            INT DEFAULT 0,
  click_count           INT DEFAULT 0,
  save_count            INT DEFAULT 0,
  created_at            TIMESTAMP DEFAULT now(),
  updated_at            TIMESTAMP DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_properties_location ON properties(region, city);
CREATE INDEX IF NOT EXISTS idx_properties_category ON properties(category, listing_type, property_type);

CREATE TABLE IF NOT EXISTS property_media (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  property_id       UUID REFERENCES properties(id) ON DELETE CASCADE,
  media_type        VARCHAR(10) NOT NULL,   -- photo | video
  url               TEXT NOT NULL,
  thumbnail_url     TEXT,
  duration_seconds  INT,
  sort_order        INT DEFAULT 0,
  created_at        TIMESTAMP DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_property_media_property ON property_media(property_id);

CREATE TABLE IF NOT EXISTS viewings (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  property_id     UUID REFERENCES properties(id),
  requester_id    UUID REFERENCES users(id),
  requested_date  DATE NOT NULL,
  requested_time  TIME NOT NULL,
  status          VARCHAR(20) DEFAULT 'pending', -- pending|confirmed|rejected|completed|cancelled
  created_at      TIMESTAMP DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_viewings_property ON viewings(property_id);

-- ============================================================
-- DEVELOPMENT & BUILDING (Developer, Contractor, Architect)
-- ============================================================
CREATE TABLE IF NOT EXISTS professionals (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id               UUID REFERENCES users(id),
  professional_type     VARCHAR(20) NOT NULL,  -- developer | architect | contractor
  company_name          VARCHAR(255),
  licence_number        VARCHAR(100),
  bio                   TEXT,
  region                VARCHAR(100),
  city                  VARCHAR(100),
  rating                DECIMAL(2,1),
  review_count          INT DEFAULT 0,
  profile_view_count    INT DEFAULT 0,
  contact_count         INT DEFAULT 0,
  verification_status   VARCHAR(20) DEFAULT 'pending',
  created_at            TIMESTAMP DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_professionals_region ON professionals(professional_type, region, city);

-- ============================================================
-- MAINTENANCE SERVICE (Plumber, Pool, AC, Kitchen)
-- ============================================================
CREATE TABLE IF NOT EXISTS service_categories (
  id    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name  VARCHAR(100) NOT NULL   -- Plumber | Pool | AC | Kitchen
);

CREATE TABLE IF NOT EXISTS service_providers (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id               UUID REFERENCES users(id),
  category_id           UUID REFERENCES service_categories(id),
  licence_number        VARCHAR(100),
  region                VARCHAR(100),
  city                  VARCHAR(100),
  latitude              DECIMAL(9,6),
  longitude             DECIMAL(9,6),
  rating                DECIMAL(2,1),
  review_count          INT DEFAULT 0,
  profile_view_count    INT DEFAULT 0,
  booking_count         INT DEFAULT 0,
  verification_status   VARCHAR(20) DEFAULT 'pending'
);
CREATE INDEX IF NOT EXISTS idx_service_providers_region ON service_providers(category_id, region, city);

CREATE TABLE IF NOT EXISTS service_bookings (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  provider_id     UUID REFERENCES service_providers(id),
  requester_id    UUID REFERENCES users(id),
  requested_date  DATE,
  status          VARCHAR(20) DEFAULT 'pending',
  created_at      TIMESTAMP DEFAULT now()
);

-- ============================================================
-- SHARED: REVIEWS, ACTIVITY TRACKING, VERIFICATION QUEUE
-- ============================================================
CREATE TABLE IF NOT EXISTS reviews (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  entity_type  VARCHAR(20) NOT NULL,  -- property | seller | professional | service_provider
  entity_id    UUID NOT NULL,
  reviewer_id  UUID REFERENCES users(id),
  stars        SMALLINT NOT NULL CHECK (stars BETWEEN 1 AND 5),
  comment      TEXT,
  created_at   TIMESTAMP DEFAULT now(),
  UNIQUE(entity_type, entity_id, reviewer_id)
);
CREATE INDEX IF NOT EXISTS idx_reviews_entity ON reviews(entity_type, entity_id);

CREATE TABLE IF NOT EXISTS property_views (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  property_id  UUID REFERENCES properties(id),
  viewer_id    UUID REFERENCES users(id),
  source       VARCHAR(30),  -- search_results | map_view | saved | shared_link
  viewed_at    TIMESTAMP DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_property_views_property ON property_views(property_id);
CREATE INDEX IF NOT EXISTS idx_property_views_viewer ON property_views(viewer_id);

CREATE TABLE IF NOT EXISTS property_interactions (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  property_id       UUID REFERENCES properties(id),
  user_id           UUID REFERENCES users(id),
  interaction_type  VARCHAR(30) NOT NULL, -- contact_click|schedule_click|save|share|phone_reveal
  created_at        TIMESTAMP DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_property_interactions_property ON property_interactions(property_id, interaction_type);

CREATE TABLE IF NOT EXISTS saved_properties (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id      UUID REFERENCES users(id),
  property_id  UUID REFERENCES properties(id),
  created_at   TIMESTAMP DEFAULT now(),
  UNIQUE(user_id, property_id)
);

CREATE TABLE IF NOT EXISTS app_sessions (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID REFERENCES users(id),
  role       VARCHAR(12) NOT NULL,
  device     VARCHAR(20),
  opened_at  TIMESTAMP DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_app_sessions_role_date ON app_sessions(role, opened_at);

CREATE TABLE IF NOT EXISTS verification_queue (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  entity_type  VARCHAR(20) NOT NULL, -- listing | professional | seller | service_provider
  entity_id    UUID NOT NULL,
  status       VARCHAR(20) DEFAULT 'pending',
  reviewed_by  UUID REFERENCES users(id),
  reviewed_at  TIMESTAMP,
  created_at   TIMESTAMP DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_verification_queue_status ON verification_queue(status);
