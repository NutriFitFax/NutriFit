/// Single place to set the backend URL.
///
/// Override at build time:
///   flutter run --dart-define=API_BASE_URL=https://nutrifit-backend-lnm0.onrender.com
///
/// Default is the deployed Render backend. For local development override with:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000   (Android emulator)
///   flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000  (iOS / desktop)
library;

class ApiConfig {
  static Uri get baseUrl {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) return Uri.parse(fromDefine);
    return Uri.parse('https://nutrifit-backend-lnm0.onrender.com');
  }
}
