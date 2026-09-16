#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../aqary_backend"

npm install

if [ ! -f .env ]; then
  cp .env.example .env
  # Point at the devcontainer's own Postgres service instead of localhost.
  sed -i 's#^DATABASE_URL=.*#DATABASE_URL=postgresql://aqary:aqary@db:5432/aqary#' .env
  sed -i 's#^JWT_SECRET=.*#JWT_SECRET=codespaces-dev-secret-change-me#' .env
fi

echo "Waiting for PostgreSQL to accept connections..."
set -a
source .env
set +a
for i in $(seq 1 30); do
  if node -e "const { Pool } = require('pg'); new Pool({ connectionString: process.env.DATABASE_URL }).query('SELECT 1').then(() => process.exit(0)).catch(() => process.exit(1));" 2>/dev/null; then
    echo "PostgreSQL is ready."
    break
  fi
  sleep 1
done

npm run migrate

echo ""
echo "Setup complete. Run 'npm start' inside aqary_backend/ to start the API on port 3000."
