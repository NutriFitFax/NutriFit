# NutriFit

A nutrition and fitness tracking app: scan a barcode or snap a photo of your meal, log your calories and macros, and track your weight, water, and daily goals. Built as a student group project at the International University of Sarajevo (IUS).

NutriFit is split into two parts:

| Part | Stack | Folder |
| ---- | ----- | ------ |
| **Mobile app** | Flutter (Android) | [`mobile/`](mobile/) |
| **Backend API** | Java 21 · Spring Boot | [`nutrifit-backend/`](nutrifit-backend/) |

The backend runs live on Render: <https://nutrifit-backend-lnm0.onrender.com>

---

## Features

- 📷 **Barcode scanning** — point at any product to look up its nutrition (USDA FoodData Central, with Open Food Facts as fallback).
- 🍽️ **Meal photo estimation** — take a photo of your plate and get an AI estimate of the foods and their macros (OpenAI vision).
- 🔍 **Food search** — full-text search across the USDA food database.
- 📊 **Daily dashboard** — calorie ring, protein/carb/fat macro bars, and your logged meals for the day.
- 💧 **Water & weight tracking** — quick logging with a weight trend sparkline and BMI.
- 🎯 **Goals & macro targets** — set targets manually or recalculate them automatically from your weight, height, sex, activity level, and age (Mifflin–St Jeor).
- ⏰ **Reminders** — optional meal and hydration notifications on a schedule you choose.
- 👤 **Accounts** — register, log in, and sync your profile and logs to the backend; data is also stored locally so the app works offline.

---

## Mobile app

The Flutter app lives in [`mobile/`](mobile/) and currently targets **Android**.

### Architecture

```text
mobile/lib/
├── api/          HTTP client + response models (mirror the backend contracts)
├── app/          App shell, theme, tabs, notifications, settings storage
├── db/           Local SQLite store (sqflite) for offline logs
├── features/     Feature modules
│   ├── auth/         Register / login / profile setup / goals
│   ├── barcode/      Barcode scanner
│   ├── meal_estimation/  Meal photo capture + results
│   ├── history/      Recently viewed foods
│   ├── tracking/     Water & weight logging
│   └── settings/     Goals, units, reminders, account
├── screens/      Standalone screens (search, food detail)
└── ui/           Shared widgets (rings, cards, tiles)
```

State lives on-device in SQLite and `shared_preferences`, and syncs to the backend when it's reachable. Backend URL is configured in [`mobile/lib/api/api_config.dart`](mobile/lib/api/api_config.dart) and defaults to the live Render instance.

### Run locally

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart `>=3.3.0`).

```bash
cd mobile
flutter pub get
flutter run
```

To point the app at a backend other than the default, override the URL at build time:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000   # Android emulator → localhost
```

### Build a release APK

```bash
cd mobile
flutter build apk --release
```

The APK is written to `mobile/build/app/outputs/flutter-apk/app-release.apk`. Share that file directly to install on any Android device (the installer will ask to allow "install from unknown sources").

> **Note:** Code minification (R8) is intentionally disabled in the release build - it obfuscates the barcode scanner's MLKit classes and crashes the app at startup.

---

## Backend

The Java Spring Boot service in [`nutrifit-backend/`](nutrifit-backend/) powers search, barcode lookup, meal-photo estimation, and profile storage. It integrates USDA FoodData Central, Open Food Facts, OpenAI, Spoonacular, and Supabase Postgres.

See **[`nutrifit-backend/README.md`](nutrifit-backend/README.md)** for endpoints, configuration, local setup, tests, and deployment (Render / Fly.io / Railway / Docker).

Quick start:

```bash
cd nutrifit-backend
mvn spring-boot:run
# health check at http://127.0.0.1:8000/health
```

---

## Tech stack

**Mobile:** Flutter · Dart · sqflite · mobile_scanner · image_picker · flutter_local_notifications · google_fonts

**Backend:** Java 21 · Spring Boot · Maven · Supabase Postgres

**External services:** USDA FoodData Central · Open Food Facts · OpenAI (gpt-4o vision) · Spoonacular

---

## Project status

This is a university group project (team of 5). The backend is deployed to a free Render tier, which sleeps after inactivity - the first request after an idle period may take 30–60 seconds while the service wakes up.

## Download link

(https://github.com/NutriFitFax/NutriFit/releases/download/v1.0.1/app-release.apk)
