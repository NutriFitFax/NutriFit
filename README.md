# NutriFit

Student project: Flutter mobile app + FastAPI backend for food tracking (barcode scan, search, meal-photo estimation, weight/water logging, BMI, history).

## Team & ownership

| Area                                          | Owner              | Folder(s)                                              |
| --------------------------------------------- | ------------------ | ------------------------------------------------------ |
| Backend + DevOps + Flutter `api_client.dart`  | **Esma Krnjić**    | `nutrifit-backend/`, `mobile/lib/api/`                 |
| Camera features (Flutter)                     | Bakir Baković      | `mobile/lib/features/barcode/`, `mobile/lib/features/meal_estimation/` |
| Search + food display (Flutter)               | Ahmed Musaefendić  | `mobile/lib/features/search/`, `mobile/lib/features/food_detail/` |
| Health tracking + local SQLite (Flutter)      | Davud Sadikaj      | `mobile/lib/db/`, `mobile/lib/features/tracking/`      |
| Home + nav + history + design system (Flutter)| Ferhad Jukić       | `mobile/lib/app/`, `mobile/lib/features/history/`, `mobile/lib/ui/` |

## Week 1 priorities

* **Esma** → deploy the backend to a staging URL, share it (see `nutrifit-backend/README.md`).
* **Davud** → define the SQLite schema first — everyone reads from / writes to it.
* **Ferhad** → define shared widgets / theme — others use these.
* **Bakir + Ahmed** → build against the deployed backend immediately.

## Quick start

Backend: see [`nutrifit-backend/README.md`](nutrifit-backend/README.md).

Flutter client wrapper: see [`mobile/lib/api/README.md`](mobile/lib/api/README.md).
