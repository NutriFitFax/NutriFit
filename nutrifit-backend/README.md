# nutrifit-backend

Java Spring Boot service backing the NutriFit Flutter app. Owned by **Esma Krnjic**.

Three endpoints power the mobile app, plus a health check used by Render/Fly uptime probes:

| Method | Path                       | Purpose                                  |
| ------ | -------------------------- | ---------------------------------------- |
| GET    | `/barcode/{barcode}`       | Look up a product by EAN/UPC             |
| GET    | `/search?q=`               | Full-text food search                    |
| POST   | `/estimate-meal`           | Estimate macros from a meal photo (multipart `image`) |
| GET    | `/health`                  | Liveness / readiness probe               |

Barcode + search are backed by [USDA FoodData Central](https://fdc.nal.usda.gov/api-guide/). The meal-photo endpoint uses OpenAI `gpt-4o` vision when `OPENAI_API_KEY` is set, otherwise returns a deterministic stub so the Flutter app has something to render in dev.

## Run locally

Requires Java 21 and Maven.

```bash
cd nutrifit-backend
mvn spring-boot:run
```

Open <http://127.0.0.1:8000/health> for a quick health check.

### Try the endpoints

```bash
curl http://127.0.0.1:8000/health
curl http://127.0.0.1:8000/barcode/077034085228
curl "http://127.0.0.1:8000/search?q=cheddar%20cheese"
curl -F "image=@./some_meal.jpg" http://127.0.0.1:8000/estimate-meal
```

## Tests

```bash
mvn test
```

Tests use `MockWebServer` to mock USDA FoodData Central, so no network is required and no API key is needed.

## Deploy

Three options. Pick one and ignore the rest.

### Render

Render does not provide Java as a native runtime, so this repo deploys the Java backend with Docker.

1. Push this repo to GitHub.
2. Create a new "Blueprint" in Render and point it at the repo. The root `render.yaml` is auto-detected.
3. Hit deploy. The staging URL appears in the dashboard. Share it with the team.
4. In the service's Environment tab, set `USDA_API_KEY` to your free data.gov key. Optional: paste your `OPENAI_API_KEY` to flip `/estimate-meal` from `stub` to `ai`.
5. Auto-deploy on every push to `main` is wired through `.github/workflows/backend-deploy.yml`. Add the deploy hook URL to the repo secret `RENDER_DEPLOY_HOOK_URL`.

### Fly.io

```bash
cd nutrifit-backend
flyctl launch --no-deploy --copy-config
flyctl deploy
```

To enable GitHub Actions deploys: set repo variable `DEPLOY_TARGET=fly`, then add secret `FLY_API_TOKEN` from `flyctl auth token`.

### Railway

Railway can build the Maven project and use the `Procfile`. Create a project from the repo, set the root to `nutrifit-backend`, and add the same env vars as `.env.example`.

### Docker

```bash
cd nutrifit-backend
docker build -t nutrifit-backend .
docker run --rm -p 8000:8000 -e ENVIRONMENT=local nutrifit-backend
```

## Configuration

All settings come from environment variables. See `.env.example` for the full list. The two that matter most:

| Var              | Default | Why                                                                 |
| ---------------- | ------- | ------------------------------------------------------------------- |
| `CORS_ORIGINS`   | `*`     | Tighten for production: list the actual Flutter web / device hosts. |
| `USDA_API_KEY`   | `DEMO_KEY` | Free data.gov key used for barcode/search. `DEMO_KEY` is only for light local testing. |
| `OPENAI_API_KEY` | unset   | Set to enable real meal-photo estimation. Unset means stub mode.    |
| `OPENAI_MODEL`   | `gpt-4o` | Vision model used by `/estimate-meal`.                              |

## Project layout

```text
nutrifit-backend/
+-- src/main/java/com/nutrifit/backend/
|   +-- NutriFitBackendApplication.java
|   +-- config/             Env-driven settings + CORS
|   +-- controller/         HTTP endpoints
|   +-- model/              JSON response contracts mirrored in Dart
|   +-- service/            USDA FoodData Central + meal estimator integrations
+-- src/main/resources/
|   +-- application.properties
+-- src/test/java/com/nutrifit/backend/
|   +-- Spring MVC tests with MockWebServer
+-- Dockerfile              Production image for Render/Fly/Docker
+-- fly.toml                Fly.io app config
+-- Procfile                Railway / Heroku-style process command
+-- pom.xml                 Maven build
```

## Contracts with the Flutter app

The Dart client lives in `mobile/lib/api/`. Java response records in `src/main/java/com/nutrifit/backend/model/` are mirrored by Dart classes in `mobile/lib/api/models.dart`. Breaking a JSON field name or type means breaking the app; version-bump or coordinate before changing the contract.
