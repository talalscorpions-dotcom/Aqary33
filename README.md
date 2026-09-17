# AQARY

Verified real estate super app for Oman — Flutter frontend (`aqary_app/`) + Node/Express/PostgreSQL backend (`aqary_backend/`).

## Live backend

Deployed on Render's free tier: **https://aqary-backend-l03v.onrender.com** — `aqary_app`'s GitHub Pages build (`.github/workflows/web-build.yml`) already points at it via `--dart-define=API_BASE_URL`.

Two things about Render's free tier worth knowing:
- The web service sleeps after 15 minutes of no traffic — the first request after that takes ~30–50s to wake it back up.
- The free Postgres database is deleted after 30 days unless upgraded to a paid plan — redeploy the blueprint below to get a fresh one when that happens.

To deploy your own instance instead:

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/talalscorpions-dotcom/Aqary33)

`render.yaml` provisions a free web service plus a free Postgres database and runs the schema migration automatically. Once deployed, point the Flutter app at it with `--dart-define=API_BASE_URL=<your-render-url>`.

## Run it in GitHub Codespaces

See `aqary_backend/README.md` and `.devcontainer/` — open a Codespace on this repo and both the backend and a Postgres instance are provisioned automatically.
