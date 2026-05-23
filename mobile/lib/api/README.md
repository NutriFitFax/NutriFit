# `mobile/lib/api/` - NutriFit backend client

Owner: **Esma**. Anything in this folder is the Flutter app's only path to the Java backend service. If you need a new endpoint, ping Esma; don't call HTTP directly from feature code.

## Add to `pubspec.yaml`

```yaml
dependencies:
  http: ^1.2.2
  http_parser: ^4.0.2
```

## Usage

```dart
import 'package:nutrifit/api/api_client.dart';
import 'package:nutrifit/api/api_config.dart';
import 'package:nutrifit/api/api_exception.dart';

final api = NutriFitApi(baseUrl: ApiConfig.baseUrl);

// 1. Barcode lookup
try {
  final food = await api.getByBarcode('5449000000996');
  print('${food.name} - ${food.macrosPer100g.caloriesKcal} kcal / 100 g');
} on NotFoundException {
  // show "no product found for that barcode"
} on ApiException catch (e) {
  // show generic error
}

// 2. Search
final results = await api.search('yogurt', page: 1, pageSize: 20);
for (final item in results.items) {
  print('${item.name} (${item.brand ?? "no brand"})');
}

// 3. Meal photo
final bytes = await imageFile.readAsBytes();
final estimate = await api.estimateMeal(bytes, contentType: 'image/jpeg');
print('${estimate.totalCaloriesKcal} kcal total, source=${estimate.source}');

// 4. Meal plan + recipe details
final plan = await api.generateMealPlan(
  targetCalories: 2000,
  diet: 'vegetarian',
);
final recipe = await api.getRecipeDetails(plan.meals.first.id);
print('${recipe.title} - ${recipe.nutrients.caloriesKcal} kcal');

// 5. Storage through Supabase-backed backend
await api.saveStorageProfile(
  const StoredUserProfile(
    displayName: 'Esma',
    heightCm: 170,
    goalCaloriesKcal: 2100,
  ),
);
await api.addMealLog(
  const MealLogEntry(
    name: 'Banana',
    caloriesKcal: 105,
    proteinG: 1.3,
    carbsG: 27,
    fatG: 0.4,
    source: 'manual',
  ),
);
final summary = await api.getDailyStorageSummary();
print('${summary.totals.caloriesKcal} kcal logged today');

// At app shutdown
api.close();
```

## Endpoints

| Method | Path                          | Returns        | Notes                                          |
| ------ | ----------------------------- | -------------- | ---------------------------------------------- |
| GET    | `/barcode/{barcode}`          | `Food`         | 404 -> `NotFoundException`                     |
| GET    | `/search?q=&page=&page_size=` | `SearchResult` | `page` 1-50, `page_size` 1-50                  |
| POST   | `/estimate-meal`              | `MealEstimate` | multipart field name = `image`, jpg/png/webp   |
| GET    | `/meal-plan`                  | `MealPlanResponse` | `time_frame`, `target_calories`, `diet`    |
| GET    | `/recipes/{id}`               | `RecipeDetails` | Spoonacular recipe details and nutrients       |
| `/storage/*` | profile/meals/water/weight/activity | Supabase-backed user tracking data |
| GET    | `/health`                     | `bool`         | use `api.ping()` for a soft connectivity check |

Storage calls send `X-User-Id`. Until real auth exists, the default is `demo-user`;
pass a stable user id from the app once auth/profile ownership is decided.

## Errors

All thrown errors are subclasses of `ApiException`:

* `NetworkException` - device offline, DNS failure
* `TimeoutException` - slow or unreachable server
* `BadRequestException` - 400 / 413
* `NotFoundException` - 404 (no product for barcode)
* `ValidationException` - 415 / 422 (bad image type, missing query)
* `UpstreamException` - 502 / 503 / 504 (USDA/OpenAI upstream down)
* `ServerException` - anything else 5xx

## Configuring the base URL

Production / staging:

```bash
flutter run --dart-define=API_BASE_URL=https://nutrifit-backend-lnm0.onrender.com
```

Local dev: default. Android emulator hits `10.0.2.2:8000`, iOS simulator / desktop hit `127.0.0.1:8000`.
