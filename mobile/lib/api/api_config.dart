/// Single place to set the backend URL.
///
/// Override at build time:
///   flutter run --dart-define=API_BASE_URL=https://nutrifit-staging.example.com
///
/// The default points at localhost on the platform-correct host for emulators:
///   * Android emulator -> http://10.0.2.2:8000
///   * iOS simulator / desktop -> http://127.0.0.1:8000
library;

import 'dart:io' show Platform;

class ApiConfig {
  static Uri get baseUrl {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) return Uri.parse(fromDefine);
    final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    return Uri.parse('http://$host:8000');
  }
}
