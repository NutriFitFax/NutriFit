# nutrifit-backend

FastAPI service backing the NutriFit Flutter app. Owned by **Esma Krnjić**.

Three endpoints power the mobile app, plus a health check used by Render/Fly uptime probes:

| Method | Path                       | Purpose                                  |
| ------ | -------------------------- | ---------------------------------------- |
| GET    | `/barcode/{barcode}`       | Look up a product by EAN/UPC             |
| GET    | `/search?q=`               | Full-text food search                    |
| POST   | `/estimate-meal`           | Estimate macros from a meal photo (multipart `image`) |
| GET    | `/health`                  | Liveness / readiness probe               |

Barcode + search are backed by [OpenFoodFacts](https://world.openfoodfacts.org). The meal-photo endpoint uses OpenAI's vision model when `OPENAI_API_KEY` is set, otherwise returns a deterministic stub so the mobile app has something to render in dev.

## Run locally

Requires Python 3.11+ (3.12 recommended).

```bash
cd nutrifit-backend
python -m venv .venv
. .venv/Scripts/activate          # Windows PowerShell: .venv\Scripts\Activate.ps1
pip install -r requirements-dev.txt
cp .env.example .env              # optional — defaults are fine
uvicorn app.main:app --reload
```

Open <http://127.0.0.1:8000/docs> for Swagger UI.

### Try the endpoints

```bash
curl http://127.0.0.1:8000/health
curl http://127.0.0.1:8000/barcode/5449000000996
curl "http://127.0.0.1:8000/search?q=yogurt"
curl -F "image=@./some_meal.jpg" http://127.0.0.1:8000/estimate-meal
```

## Tests

```bash
pytest -q
ruff check .
```

Tests use [`respx`](https://github.com/lundberg/respx) to mock OpenFoodFacts — no network is required and no API key is needed.

## Deploy

Three options. Pick one and ignore the rest.

### Render (easiest — free tier)

1. Push this repo to GitHub.
2. Create a new "Blueprint" in Render and point it at the repo. The root `render.yaml` is auto-detected.
3. Hit deploy. The staging URL appears in the dashboard. Share it with the team.
4. (Optional) In the service's Environment tab, paste your `OPENAI_API_KEY` to flip `/estimate-meal` from `stub` to `ai`.
5. Auto-deploy on every push to `main` is wired through `.github/workflows/backend-deploy.yml` — drop the **deploy hook URL** into the repo secret `RENDER_DEPLOY_HOOK_URL` (Settings → Deploy Hook → copy).

### Fly.io

```bash
cd nutrifit-backend
flyctl launch --no-deploy --copy-config        # accepts existing fly.toml
flyctl deploy
```

To enable GitHub Actions deploys: set repo variable `DEPLOY_TARGET=fly`, then add secret `FLY_API_TOKEN` (run `flyctl auth token`).

### Railway

Railway auto-detects `Procfile`. Create a project from the repo, set the root to `nutrifit-backend`, and add the same env vars as `.env.example`.

### Docker (anywhere)

```bash
cd nutrifit-backend
docker build -t nutrifit-backend .
docker run --rm -p 8000:8000 -e ENVIRONMENT=local nutrifit-backend
```

## Configuration

All settings come from environment variables. See `.env.example` for the full list. The two that matter most:

| Var               | Default         | Why                                                                 |
| ----------------- | --------------- | ------------------------------------------------------------------- |
| `CORS_ORIGINS`    | `*`             | Tighten for production: list the actual Flutter web / device hosts. |
| `OPENAI_API_KEY`  | (unset)         | Set to enable real meal-photo estimation. Unset → stub mode.        |

## Project layout

```
nutrifit-backend/
├── app/
│   ├── main.py             FastAPI entrypoint + lifespan
│   ├── config.py           Env-driven Settings
│   ├── schemas.py          Pydantic contracts (mirrored in Dart)
│   ├── version.py          __version__ — single source of truth
│   ├── routers/
│   │   ├── health.py       /, /health
│   │   ├── barcode.py      /barcode/{barcode}
│   │   ├── search.py       /search
│   │   └── meal.py         /estimate-meal
│   └── services/
│       ├── openfoodfacts.py  OFF wrapper + Food mapping
│       └── meal_estimator.py AI / stub meal estimator
├── tests/                  pytest + respx (offline-safe)
├── Dockerfile              Production image
├── fly.toml                Fly.io app config
├── Procfile                Railway / Heroku
├── requirements.txt        Runtime deps
├── requirements-dev.txt    Test/lint deps
└── pyproject.toml          pytest + ruff config
```

## Contracts with the Flutter app

The Dart client lives in `mobile/lib/api/`. Pydantic schemas in `app/schemas.py` are mirrored by Dart classes in `mobile/lib/api/models.dart`. **Breaking a schema = breaking the app** — version-bump or coordinate before changing field names/types.
