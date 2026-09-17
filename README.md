# AQARY

Verified real estate super app for Oman — Flutter frontend (`aqary_app/`) + Node/Express/PostgreSQL backend (`aqary_backend/`).

## Run the backend live

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/talalscorpions-dotcom/Aqary33)

Click the button, sign in with GitHub, and confirm — `render.yaml` provisions a free web service plus a free Postgres database and runs the schema migration automatically. A few minutes later you have a real `https://aqary-backend-xxxx.onrender.com` URL.

Two things about Render's free tier worth knowing:
- The web service sleeps after 15 minutes of no traffic — the first request after that takes ~30–50s to wake it back up.
- The free Postgres database is deleted after 30 days unless upgraded to a paid plan.

Once deployed, point the Flutter app at it with `--dart-define=API_BASE_URL=<your-render-url>`.

## Run it in GitHub Codespaces

See `aqary_backend/README.md` and `.devcontainer/` — open a Codespace on this repo and both the backend and a Postgres instance are provisioned automatically.
