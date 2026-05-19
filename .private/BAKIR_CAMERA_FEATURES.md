# NutriFit — Camera Features Briefing

**This is your personal briefing document. Keep it open while you work.**

When you start a new chat with an AI assistant (Claude, GPT, Cursor, whatever),
paste the relevant sections at the top of your first prompt so the AI has full
context. Sections marked **📋 COPY-PASTE FRIENDLY** are designed to be dropped
into prompts verbatim.

---

## 📋 TL;DR — paste this into the FIRST message of any new chat

```
I'm building the camera features for "NutriFit", a Flutter Android app for
nutrition tracking. My specific responsibility:

  1. Barcode scanning screen (camera → decode barcode → fetch product nutrition)
  2. Image meal estimation screen (camera/gallery → upload photo → show identified
     foods with nutrition)

The backend (Python/FastAPI) is already built by my teammate. I call it via
HTTPS. The backend handles all external APIs (Open Food Facts for barcodes,
GPT-4o + USDA for image analysis) — I never call those directly.

Stack: Flutter (Dart), Android target API 24+, packages:
  - mobile_scanner — barcode decoding
  - image_picker — camera capture + gallery
  - permission_handler — Android runtime permissions
  - http (or our shared api_client.dart) — HTTPS calls to my backend

I do NOT build: backend code, local SQLite, water/weight tracking, food history,
home screen navigation, search UI, food detail UI. Those belong to other team
members.

The user can adjust portion size on the food detail screen (someone else's
work), so my screens just need to display the API response and let the user
"confirm and save" or navigate to detail.
```

---

## 1. Project context — what NutriFit is

NutriFit is an **Android mobile app** built by a 5-person student team at the
International University of Sarajevo. It helps users track nutrition by:

- Scanning food barcodes
- Searching food by name
- Estimating calories from meal photos
- Tracking water, weight, BMI
- Viewing recent food history

**Architecture:** thin-client mobile app + stateless backend.

```
[Flutter App on phone]
        │  HTTPS
        ▼
[FastAPI Backend on a server]
        │
        ├─► OpenAI GPT-4o (image recognition)
        ├─► USDA FoodData Central (nutrition data)
        └─► Open Food Facts (barcode lookup)
```

**Critical constraint:** all user data (water logs, weight, food history) stays
on the device in SQLite. The backend stores nothing per-user. This is
in the SRS (section 5.2) — don't try to add user accounts or cloud sync.

---

## 2. The 5-person team — who does what

| Person | Role | Owns |
|---|---|---|
| Esma | Backend + API client | `nutrifit-backend/`, `mobile/lib/api/` |
| **You (Bakir)** | **Camera features** | **`mobile/lib/features/barcode/`, `mobile/lib/features/meal_estimation/`** |
| Ahmed | Search + food display | `mobile/lib/features/search/`, `mobile/lib/features/food_detail/` |
| Davud | Health tracking + SQLite | `mobile/lib/db/`, `mobile/lib/features/tracking/` |
| Ferhad | Home + navigation + design | `mobile/lib/app/`, `mobile/lib/features/history/`, `mobile/lib/ui/` |

**Who you depend on:**
- **Esma** — gives you the `ApiClient` Dart class. You call methods on it; you
  don't write the HTTP code yourself. Coordinate early to agree on method
  signatures.
- **Ferhad** — gives you the design system (colors, button widgets, app theme).
  Use his shared widgets so your screens match the rest of the app.
- **Ahmed** — your screens hand off to his food detail screen for "view full
  nutrition / adjust portion". Agree on the navigation route name.
- **Davud** — when the user confirms a scanned/analyzed food, it should be
  saved to history. He owns the SQLite layer. Just call his save function.

**Who depends on you:** nobody blocks on you. Your screens are leaf nodes.

---

## 3. 📋 Your role in detail — paste this when asking for help

```
My two screens:

A) BARCODE SCANNING (SRS REQ-BAR-1, REQ-BAR-2, REQ-BAR-5)
   - Full-screen camera viewfinder with a barcode-shaped overlay
   - Auto-detect EAN-13, UPC-A, and other 1D/2D barcodes
   - On successful decode: vibrate, call backend with barcode, show result
   - Handle "product not found" gracefully — let user retry or enter manually
   - Handle camera permission denied with a clear "open settings" CTA
   - Handle no internet with a clear retry option
   - Pause scanning when navigating away; resume on return

B) IMAGE MEAL ESTIMATION (SRS REQ-IMG-1, REQ-IMG-3)
   - Bottom-sheet picker: "Take photo" or "Choose from gallery"
   - Show preview of selected image with "Analyze" and "Retake" buttons
   - On Analyze: show loading state (this takes 3-5 seconds — the backend
     calls GPT-4o then USDA), then show results
   - Results screen: list of identified foods, each with:
       * name (e.g. "grilled chicken breast")
       * estimated portion ("~150g")
       * confidence (show as a badge — "high confidence" / "estimate")
       * scaled nutrition (calories, protein/carbs/fat)
   - Show meal total at the bottom (sum of all items)
   - Each item is tappable → navigates to food detail for adjustment
   - Handle errors: image too big, no food detected, upstream timeout
```

---

## 4. 📋 Backend API I'll be calling — paste this when prompting

```
BASE URL: https://nutrifit-api.example.com  (Esma will give the real URL)

═══════════════════════════════════════════════════════════════════════════
ENDPOINT 1: Barcode lookup
═══════════════════════════════════════════════════════════════════════════
  GET /food/barcode/{barcode}

  Path param: barcode (string of 6–20 digits)

  ✅ 200 OK — product found:
  {
    "barcode": "737628064502",
    "food": {
      "name": "Organic Peanut Butter",
      "brand": "Acme Foods",
      "matched_to": "Organic Peanut Butter",
      "source": "Open Food Facts",
      "source_id": "737628064502",
      "nutrition_per_100g": {
        "calories": 588.0,
        "protein_g": 25.0,
        "carbs_g": 20.0,
        "fat_g": 50.0,
        "fiber_g": 6.0,
        "sugar_g": 9.0,
        "sodium_mg": 12.0,
        "saturated_fat_g": 10.0
      }
    }
  }

  ❌ 404 NOT_FOUND — barcode not in OFF database
  ❌ 422 — invalid barcode format (non-numeric)
  ❌ 502 EXTERNAL_API_ERROR — Open Food Facts is down
  ❌ 504 EXTERNAL_API_TIMEOUT — Open Food Facts is slow
  ❌ 429 RATE_LIMITED — too many requests

  Every error has this shape:
  { "error": "NotFound", "code": "NOT_FOUND", "detail": "human readable" }

═══════════════════════════════════════════════════════════════════════════
ENDPOINT 2: Image meal analysis
═══════════════════════════════════════════════════════════════════════════
  POST /food/analyze-image
  Content-Type: multipart/form-data
  Field: "image" — JPEG/PNG/WebP/HEIC, max 10 MB

  ✅ 200 OK:
  {
    "items": [
      {
        "identified": {
          "name": "grilled chicken breast",
          "portion_estimate": "1 medium fillet",
          "portion_grams": 150,
          "confidence": 0.92
        },
        "food": {
          "name": "grilled chicken breast",
          "matched_to": "Chicken, broilers, breast, grilled",
          "source": "USDA FoodData Central",
          "source_id": "171688",
          "nutrition_per_100g": { /* same shape as above */ }
        },
        "nutrition_scaled": {
          "calories": 247.5,
          "protein_g": 46.4,
          "carbs_g": 0.0,
          "fat_g": 5.4,
          "portion_grams": 150
        },
        "notes": null
      }
    ],
    "totals": {
      "calories": 247.5,
      "protein_g": 46.4,
      "carbs_g": 0.0,
      "fat_g": 5.4,
      "portion_grams": 150
    },
    "image_size_bytes": 245678,
    "processing_ms": 3421
  }

  When `food` is null inside an item, GPT-4o identified the food but USDA
  couldn't match it. Show the item with name + estimated portion but no
  nutrition values, plus the `notes` field as explanation.

  ❌ 400 INVALID_IMAGE — file is empty, too big, or not a real image
  ❌ 502 EXTERNAL_API_ERROR — OpenAI or USDA error
  ❌ 504 EXTERNAL_API_TIMEOUT
  ❌ 429 RATE_LIMITED — image analysis costs 5 tokens vs 1 for other endpoints

  Empty `items: []` means "no food was visible in the image" — show a clear
  message, NOT an error.
```

---

## 5. Tech stack and recommended packages

Add these to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  # Barcode scanning
  mobile_scanner: ^5.2.3
  # Camera capture + gallery
  image_picker: ^1.1.2
  # Runtime permissions
  permission_handler: ^11.3.1
  # HTTP (or use Esma's api_client if she provides one)
  http: ^1.2.2
  # Haptic feedback on successful scan
  vibration: ^2.0.0
```

**Why these specific packages:**
- `mobile_scanner` is the modern replacement for `qr_code_scanner` (which is
  deprecated). It uses Google's ML Kit under the hood.
- `image_picker` is the official Flutter team package — simple, reliable.
- `permission_handler` is the standard for runtime permissions on Android.

---

## 6. Suggested implementation order

Build in this order so each step works on its own before adding complexity:

### Phase 1 — Permissions + skeleton (Day 1)
- [ ] Add packages to `pubspec.yaml` and run `flutter pub get`
- [ ] Add permissions to `AndroidManifest.xml`:
  - `android.permission.CAMERA`
  - `android.permission.INTERNET`
- [ ] Build a `PermissionHelper` that requests camera permission on first launch
  and shows a "go to settings" dialog if permanently denied
- [ ] Create empty screen files in `mobile/lib/features/barcode/` and
  `mobile/lib/features/meal_estimation/`

### Phase 2 — Barcode scanning (Days 2-3)
- [ ] Build `BarcodeScannerScreen` with `MobileScanner` widget
- [ ] Overlay UI: scanning rectangle, "point camera at barcode" text, flash toggle
- [ ] On successful decode: vibrate, pause scanner, show bottom sheet with loading state
- [ ] Call Esma's `apiClient.lookupBarcode(code)` from the bottom sheet
- [ ] On success: navigate to Ahmed's food detail screen with the result
- [ ] On 404: show "Product not found" with "Scan again" and "Enter manually" buttons
- [ ] On network error: show "Check your connection" with "Retry" button
- [ ] Handle scanner lifecycle: pause when app backgrounded, resume on return

### Phase 3 — Image meal estimation (Days 4-6)
- [ ] Build `MealEstimationEntryScreen` with two big buttons: "Take Photo" / "From Gallery"
- [ ] Wire up `image_picker` to launch camera / gallery
- [ ] After selection: navigate to `MealPreviewScreen` showing the image with
  "Analyze" / "Retake" buttons
- [ ] On Analyze: show full-screen loader (this takes 3-5 seconds)
- [ ] Call `apiClient.analyzeImage(file)` with the selected file
- [ ] Build `MealResultsScreen` showing list of identified foods with confidence badges
- [ ] Show meal totals at the bottom (sticky footer)
- [ ] Each item tappable → Ahmed's food detail screen for portion adjustment
- [ ] On `items: []`: show "No food detected — try a clearer photo" with "Retry"

### Phase 4 — Polish (Day 7)
- [ ] Loading skeletons / shimmer effects on the results screen
- [ ] Smooth transitions between screens
- [ ] Test on a real Android device (camera doesn't work well in emulators)
- [ ] Test edge cases: airplane mode, permission denied, large image, dark photo
- [ ] Write widget tests for at least the result-display logic

---

## 7. Screens you'll build

```
mobile/lib/features/
├── barcode/
│   ├── barcode_scanner_screen.dart       # Camera viewfinder + overlay
│   ├── barcode_result_sheet.dart         # Bottom sheet shown on decode
│   └── widgets/
│       ├── scanner_overlay.dart          # The scanning-frame UI
│       └── flash_toggle.dart
├── meal_estimation/
│   ├── meal_entry_screen.dart            # "Take photo" / "From gallery"
│   ├── meal_preview_screen.dart          # Show image + Analyze button
│   ├── meal_results_screen.dart          # List of identified foods
│   └── widgets/
│       ├── food_item_card.dart           # One row in the results list
│       ├── confidence_badge.dart         # "High confidence" / "Estimate"
│       └── meal_totals_footer.dart       # Sticky total at bottom
└── shared/
    ├── permission_helper.dart            # Camera permission logic
    └── error_state.dart                  # Reusable error widget
```

---

## 8. Android permissions and lifecycle gotchas

### Permissions
Add to `android/app/src/main/AndroidManifest.xml` inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
```

### Permission states
`permission_handler` returns these states. Handle each:
- **granted** — proceed
- **denied** — user denied this time, can ask again with rationale
- **permanentlyDenied** — user clicked "Don't ask again"; must send them to settings via `openAppSettings()`
- **restricted** — parental controls; cannot be granted (rare)

### Lifecycle
The `MobileScanner` widget needs explicit lifecycle handling:

```dart
class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with WidgetsBindingObserver {
  late MobileScannerController controller;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.start();
    } else if (state == AppLifecycleState.paused) {
      controller.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }
}
```

### Image picker gotchas
- iOS needs `NSCameraUsageDescription` in Info.plist — not your problem (Android-only)
- Android 13+ uses photo picker by default — no storage permission needed
- Compress images before upload: pass `imageQuality: 85` and `maxWidth: 1920` to `picker.pickImage()`. The backend will resize again, but this saves upload bandwidth.

---

## 9. Error handling matrix

Use this table verbatim. Every error from the API maps to a specific UX.

| API code | UX action |
|---|---|
| `NOT_FOUND` (barcode) | "Product not found. Try scanning again or search by name." |
| `INVALID_IMAGE` | "Image format not supported. Try a JPG or PNG photo." |
| `RATE_LIMITED` | "Too many requests. Try again in a few seconds." |
| `EXTERNAL_API_ERROR` | "Service is having trouble. Tap to retry." |
| `EXTERNAL_API_TIMEOUT` | "Taking longer than usual. Tap to retry." |
| `INTERNAL_ERROR` | "Something went wrong. Tap to retry." |
| No internet (caught client-side) | "No internet connection. Reconnect and tap to retry." |
| Empty `items: []` (image) | "No food detected. Try a clearer, well-lit photo." |

Never show raw error codes or stack traces to users.

---

## 10. What you do NOT build (avoid scope creep)

- ❌ Backend code — Esma owns this
- ❌ The HTTP client logic — Esma's `ApiClient` is what you call
- ❌ Local SQLite storage — Davud owns this; you call his save function
- ❌ Search screen — Ahmed owns this
- ❌ Food detail screen with serving slider — Ahmed owns this
- ❌ Home screen / bottom nav — Ferhad owns this
- ❌ Theme colors, fonts, button styles — Ferhad owns this; you use his widgets
- ❌ Food history screen — Ferhad owns this
- ❌ Water/weight/BMI screens — Davud owns this

If a feature touches your screens but is "owned" by someone else, talk to them
before building it yourself. Better to coordinate than to duplicate work.

---

## 11. 📋 How to prompt an AI assistant effectively for your work

When asking for help, structure your prompt like this:

```
[1. CONTEXT — paste sections 1-3 from this doc]

[2. SPECIFIC TASK — what you want built right now]
Example: "Build the BarcodeScannerScreen widget. It should..."

[3. CONSTRAINTS — anything specific to your situation]
Example: "I'm using mobile_scanner 5.2.3. I want to handle permission denied
with a custom dialog instead of just showing an error."

[4. WHAT YOU'VE TRIED — if asking for debugging help]
Example: "The scanner works in debug but crashes on release builds. Logcat
shows..."
```

### Good prompt example:
> I'm building the camera features for NutriFit, a Flutter Android nutrition app.
> [paste TL;DR section]
>
> Build the BarcodeScannerScreen widget. Requirements:
> - Use mobile_scanner package
> - Show a centered 280x180 scanning frame with translucent overlay around it
> - Top bar with back button (left) and flash toggle (right)
> - Bottom: "Point your camera at a product barcode"
> - On decode: vibrate (HapticFeedback.heavyImpact), pause scanner, show bottom sheet
> - The bottom sheet shows a loading spinner while calling apiClient.lookupBarcode(code),
>   then either: a) on success, navigates to '/food-detail' with the Food object;
>   or b) on 404, shows "Product not found" with "Scan again" / "Enter manually" buttons
> - Handle camera permission denied — show a dialog with "Open Settings" CTA
> - Pause scanner when screen loses focus, resume on return
>
> The ApiClient signature is:
>   Future<Food> lookupBarcode(String code)  // throws NotFoundException on 404

### Bad prompt example (will get you a generic answer):
> "Make a barcode scanner in Flutter"

The more context you load up front, the better the AI's first answer.
Pasting from this doc is faster than re-explaining the project each time.

---

## 12. Communication checklist with teammates

Before you start coding, lock these down:

**With Esma:**
- [ ] What's the `ApiClient` class signature for `lookupBarcode` and `analyzeImage`?
- [ ] What exceptions does it throw on each error type?
- [ ] What's the base URL for the deployed backend?
- [ ] How is the API URL configured (env var? hardcoded?)

**With Ahmed:**
- [ ] What's the route name for the food detail screen?
- [ ] What does it expect as an argument — the `Food` object directly, or a food ID?
- [ ] Can it accept a portion override (for the scaled portion from image analysis)?

**With Davud:**
- [ ] What's the function to save a food to history? Does it take a `Food` or a custom model?
- [ ] Should I call it directly from my result screens or does Ahmed call it from the detail screen?

**With Ferhad:**
- [ ] What's the app theme? Use his colors/fonts.
- [ ] What shared button/card widgets are available?
- [ ] Where do my screens slot in the navigation tree?

---

## 13. Resources

- Mobile Scanner docs: https://pub.dev/packages/mobile_scanner
- Image Picker docs: https://pub.dev/packages/image_picker
- Permission Handler docs: https://pub.dev/packages/permission_handler
- Flutter Camera guide: https://docs.flutter.dev/cookbook/plugins/picture-using-camera
- Our SRS: see `NutriFitSRSfinal-1.pdf` in the project repo
- Our Backend Design Doc: see `NutriFit_Backend_Design.docx`
- Backend code & API contract: `nutrifit-backend/` folder
- Backend interactive docs: `https://<backend-url>/docs` (Esma will deploy)

---

## 14. Definition of done

Your part is "done" when:

- [ ] User can open the barcode scanner, scan a real product, and see its nutrition
- [ ] User can take a photo of a meal, see foods identified with portion estimates
- [ ] User can pick a photo from gallery (same flow as taking one)
- [ ] All errors from the API map to clear, non-technical user messages
- [ ] Camera permission flow handles all 4 states (granted/denied/permanently denied/restricted)
- [ ] No crashes when backgrounding the app mid-scan
- [ ] Code follows Ferhad's design system (no random hardcoded colors)
- [ ] Tappable items navigate correctly to Ahmed's food detail screen
- [ ] Widget tests pass for the result-display logic
- [ ] Tested on at least one real Android device (not just emulator)
- [ ] PRs reviewed by at least one teammate

Good luck. Ship it.
