# NutriFit E2E Tests (Postman / Newman)

10 end-to-end test scenarios that run against the live API.

## Quick start

```bash
npm install -g newman
newman run postman/NutriFit.postman_collection.json \
  -e postman/NutriFit.postman_environment.json
```

## Test against a local backend

```bash
newman run postman/NutriFit.postman_collection.json \
  --env-var base_url=http://localhost:8000
```

## Scenarios

| # | Endpoint | What is tested |
|---|----------|----------------|
| 1 | `GET /` | 200 + `status` field present |
| 2 | `GET /db-health` | Not 500, `status` field present |
| 3 | `GET /search?q=chicken` | 200, `items` array returned |
| 4 | `GET /search?q=` | 400 — empty query rejected |
| 5 | `GET /search?q=<121 chars>` | 400 — oversized query rejected |
| 6 | `GET /barcode/077034085228` | 200 / 404 / 502 — not a 400 or 500 |
| 7 | `GET /barcode/ABCDEFGHIJ` | 400 — non-numeric barcode rejected |
| 8 | `GET /barcode/<21 digits>` | 400 — oversized barcode rejected |
| 9 | `GET /meal-plan?time_frame=day` | Not 400 (200 / 502 / 503 accepted) |
| 10 | `GET /meal-plan?...&target_calories=100` | 400 — calories below minimum rejected |

> Note: Tests 6 and 9 accept upstream failure codes (502/503) because external
> API keys (USDA, Spoonacular) may be rate-limited or absent in CI.
