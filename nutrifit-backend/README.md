# nutrifit-backend

Java Spring Boot service backing the NutriFit Flutter app. Owned by **Esma Krnjic**.

Five endpoints power the mobile app, plus a health check used by Render/Fly uptime probes:

| Method | Path                       | Purpose                                  |
| ------ | -------------------------- | ---------------------------------------- |
| GET    | `/barcode/{barcode}`       | Look up a product by EAN/UPC             |
| GET    | `/search?q=`               | Full-text food search                    |
| POST   | `/estimate-meal`           | Estimate macros from a meal photo (multipart `image`) |
| GET    | `/meal-plan`               | Generate a day/week recipe meal plan     |
| GET    | `/recipes/{id}`            | Get recipe details and nutrition         |
| GET    | `/health`                  | Liveness / readiness probe               |

Search is backed by [USDA FoodData Central](https://fdc.nal.usda.gov/api-guide/). Barcode lookup tries USDA first, then falls back to [Open Food Facts](https://openfoodfacts.github.io/openfoodfacts-server/api/) for products USDA does not have. The meal-photo endpoint uses OpenAI `gpt-4o` vision when `OPENAI_API_KEY` is set; if OpenAI is not configured or fails, the endpoint returns an upstream error instead of inventing fake foods.
Meal plans and recipe details are backed by [Spoonacular](https://spoonacular.com/food-api/docs) when `SPOONACULAR_API_KEY` is set.

Live staging URL: <https://nutrifit-backend-lnm0.onrender.com>

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
curl "http://127.0.0.1:8000/meal-plan?time_frame=day&target_calories=2000&diet=vegetarian"
curl http://127.0.0.1:8000/recipes/716429
```

## Tests

```bash
mvn test
```

Tests use `MockWebServer` to mock USDA FoodData Central, OpenFoodFacts, and Spoonacular, so no network is required and no API key is needed.

## Deploy

Three options. Pick one and ignore the rest.

### Render

Render does not provide Java as a native runtime, so this repo deploys the Java backend with Docker.

1. Push this repo to GitHub.
2. Create a new "Blueprint" in Render and point it at the repo. The root `render.yaml` is auto-detected.
3. Hit deploy. The current staging URL is <https://nutrifit-backend-lnm0.onrender.com>. Share it with the team.
4. In the service's Environment tab, set `USDA_API_KEY` to your free data.gov key, `OPENAI_API_KEY` to your OpenAI key, and `SPOONACULAR_API_KEY` to your Spoonacular key. OpenFoodFacts barcode fallback does not need a key.
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
| `OPENFOODFACTS_BASE_URL` | `https://world.openfoodfacts.org` | Public barcode fallback. No key needed for read requests. |
| `SPOONACULAR_API_KEY` | unset | Required for `/meal-plan` and `/recipes/{id}`. |
| `SPOONACULAR_BASE_URL` | `https://api.spoonacular.com` | Spoonacular API base URL. |
| `OPENAI_API_KEY` | unset   | Required for real meal-photo estimation. Missing or failing OpenAI calls return an upstream error. |
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
