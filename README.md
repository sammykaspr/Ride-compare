# RideCompare

Compare ride-hailing prices across **Uber, Ola, Rapido, and Namma Yatri** using distance-based heuristics, then deep-link to the real apps to book.

```
flutter_app/         Flutter mobile app (Material 3)
backend/             FastAPI service
  app/               routes, services, models, schemas
  config/pricing.yaml   provider pricing rules — tune freely
  scripts/           ML training + sample dataset
docker-compose.yml   local Postgres + API
```

## Why heuristics, not scraping

Uber, Ola, Rapido, and Namma Yatri don't expose public price APIs. Their mobile apps use signed, device-fingerprinted requests, and their web flows require authenticated sessions. Scraping is unreliable, gets blocked fast, and likely violates their ToS.

So this app:

- **Estimates** prices from the Distance Matrix API (or a haversine fallback) plus tunable per-provider pricing rules in `backend/config/pricing.yaml`.
- **Deep-links** to each provider's app/web flow so the user books in the real app.
- Leaves a **scraper interface** at `backend/app/providers/scraper_base.py` if you ever wire one up legitimately.

Estimates get more accurate as users log real fares back to `/fares/log` and you retrain the surge model.

## Prerequisites

- Python 3.11+
- Flutter 3.16+ (`flutter doctor` should be green)
- Docker (for local Postgres) **or** a Neon connection string
- Google Maps API key with **Places** and **Distance Matrix** APIs enabled (optional — the backend falls back to a mock without one)

## Run the backend

### Option A — Docker (recommended)

```bash
cp .env.example .env
# edit .env: set GOOGLE_MAPS_API_KEY (optional)
docker compose up --build
```

API at `http://localhost:8000`. Postgres at `localhost:5432` (`postgres`/`postgres`).

### Option B — Local venv

```bash
cd backend
python -m venv .venv && source .venv/bin/activate    # Windows: .venv\Scripts\activate
pip install -r requirements.txt
export DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/ridecompare
export GOOGLE_MAPS_API_KEY=AIza...                   # or unset to use mock
uvicorn app.main:app --reload
```

Sanity check: `curl http://localhost:8000/health` → `{"status":"ok"}`.

OpenAPI docs at `http://localhost:8000/docs`.

### Using Neon instead of local Postgres

Set `DATABASE_URL` to your Neon connection string with `postgresql+asyncpg://` scheme and `?sslmode=require` appended. The backend creates tables on startup (no migrations needed for MVP).

## Run the Flutter app

```bash
cd flutter_app
flutter create .                                     # generates platform stubs
# merge flutter_app/android_manifest_additions.xml into
# android/app/src/main/AndroidManifest.xml (queries block + INTERNET permission)
flutter pub get
flutter run \
  --dart-define BACKEND_URL=http://10.0.2.2:8000 \
  --dart-define GOOGLE_MAPS_API_KEY=AIza...
```

Notes:
- `10.0.2.2` is the Android emulator's alias for the host machine. Use `localhost` for iOS simulator, or your LAN IP for a physical device.
- `GOOGLE_MAPS_API_KEY` here is for the **client-side Places autocomplete**. Restrict it to your app's bundle ID/package name in the GCP console.
- Without the key, autocomplete is disabled but you can still test the compare screen by hard-coding lat/lng in `screens/input_screen.dart`.

## Tuning prices

Edit `backend/config/pricing.yaml` — base, per-km, per-min, min fare, and ETA per ride type. Restart the backend to apply. The same file holds the hour-of-day surge fallback used when no ML model is loaded.

## ML: surge predictor

A small dataset and training script ship with the repo.

```bash
cd backend
python scripts/train_surge_model.py             # trains from sample_fares.csv
# After collecting real /fares/log entries:
python scripts/train_surge_model.py --from-db
```

The script writes `scripts/surge_model.pkl`. The backend loads it at startup; if missing, it falls back to the YAML heuristic.

`sample_fares.csv` (~120 rows) is synthetic but follows realistic patterns: weekday rush hours, weekend late-night spikes. Replace with your own data once `/fares/log` accumulates entries.

## API

| Method | Path             | Purpose                                      |
|--------|------------------|----------------------------------------------|
| GET    | `/health`        | Liveness check                               |
| POST   | `/estimate`      | Distance + per-provider price + ETA + picks  |
| POST   | `/fares/log`     | Log an actual fare for ML training           |
| POST   | `/surge/predict` | Predicted surge for `(hour, weekday)`        |

`/estimate` request:
```json
{
  "pickup": {"lat": 12.9716, "lng": 77.5946},
  "drop":   {"lat": 13.0827, "lng": 77.5877}
}
```

Returns options sorted cheapest-first and a `recommendations` block with `cheapest`/`fastest`/`best_value` ride-type IDs.

## Known limitations

- **Deep-link reliability**: Uber and Ola's iOS schemes are documented; Rapido and Namma Yatri schemes are best-effort and may not pre-fill drop locations on every version. The web fallbacks (`m.uber.com/ul`, `book.olacabs.com`, `m.rapido.bike`, `nammayatri.in`) always work.
- **Pricing is heuristic** until you log real fares and tune `pricing.yaml`. Treat the ranges as ballpark.
- **No auth, no migrations**: this is an MVP. For production, add Alembic migrations, an auth layer on `/fares/log`, and rate limiting.
- **Trend graph not included**: deferred until enough `fare_logs` rows exist to plot meaningfully.

## Troubleshooting

- `connect ECONNREFUSED 10.0.2.2:8000` on Android emulator → backend isn't running, or you're testing on iOS (use `localhost`).
- `used_mock: true` in `/estimate` response → no Google Maps key set, or the API call failed; check that Distance Matrix is enabled and the key isn't restricted.
- `/fares/log` returns 500 → DB unreachable; backend logs `[startup] DB unavailable`.
- Deep link opens browser instead of app → app not installed, or `<queries>` block missing on Android 11+.
