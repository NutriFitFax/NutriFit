/// NutriFit backend client.
///
/// Owner: Esma. Calls the Java backend service:
///   * GET  /barcode/{barcode}        -> [Food]
///   * GET  /search?q=...             -> [SearchResult]
///   * POST /estimate-meal (multipart)-> [MealEstimate]
///   * GET  /meal-plan                -> [MealPlanResponse]
///   * GET  /recipes/{id}             -> [RecipeDetails]
///   * /storage/*                     -> profile, meal, water, weight, activity logs
///
/// Configure the base URL at app start:
///
///   final api = NutriFitApi(baseUrl: Uri.parse('https://staging.example.com'));
///
/// Use `package:http`, already a Flutter convention. To swap to `dio` later,
/// only this file needs to change; the rest of the app talks to the typed
/// methods below.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

import 'api_exception.dart';
import 'models.dart';

class NutriFitApi {
  /// Base URL of the deployed backend. No trailing slash.
  final Uri baseUrl;

  /// Default per-request timeout. The meal endpoint uses 4x this because the
  /// upstream AI call is slow.
  final Duration timeout;

  final http.Client _client;
  final bool _ownsClient;

  /// The currently signed-in user. Set this after login; reset on logout.
  String userId;

  NutriFitApi({
    required this.baseUrl,
    this.userId = 'demo-user',
    this.timeout = const Duration(seconds: 10),
    http.Client? client,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null;

  /// Releases the underlying HTTP client. Call once at app shutdown.
  void close() {
    if (_ownsClient) _client.close();
  }

  Uri _u(String path, [Map<String, dynamic>? query]) {
    final stringQuery = query
        ?.map((k, v) => MapEntry(k, v == null ? '' : v.toString()));
    final basePath = baseUrl.path.endsWith('/')
        ? baseUrl.path.substring(0, baseUrl.path.length - 1)
        : baseUrl.path;
    return baseUrl.replace(
      path: '$basePath$path',
      queryParameters: stringQuery,
    );
  }

  T _decode<T>(http.Response resp, T Function(Map<String, dynamic>) parse) {
    final status = resp.statusCode;
    final body = resp.body;
    if (status >= 200 && status < 300) {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return parse(json);
    }
    _throwForStatus(status, body);
  }

  List<T> _decodeList<T>(
    http.Response resp,
    T Function(Map<String, dynamic>) parse,
  ) {
    final status = resp.statusCode;
    final body = resp.body;
    if (status >= 200 && status < 300) {
      final json = jsonDecode(body) as List<dynamic>;
      return json
          .map((e) => parse(e as Map<String, dynamic>))
          .toList(growable: false);
    }
    _throwForStatus(status, body);
  }

  Never _throwForStatus(int status, String body) {
    final detail = _safeDetail(body) ?? 'http $status';
    switch (status) {
      case 400:
        throw BadRequestException(detail);
      case 404:
        throw NotFoundException(detail);
      case 413:
        throw BadRequestException('upload too large: $detail');
      case 415:
      case 422:
        throw ValidationException(detail);
      case 502:
      case 503:
      case 504:
        throw UpstreamException(detail);
      default:
        throw ServerException(detail, statusCode: status);
    }
  }

  Map<String, String> get _userHeaders => {'X-User-Id': userId};
  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        'X-User-Id': userId,
      };

  String _date(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String? _safeDetail(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final d = decoded['detail'];
        if (d is String) return d;
        if (d != null) return d.toString();
      }
    } on FormatException {
      // Body was not JSON; fall through.
    }
    return body.length > 200 ? '${body.substring(0, 200)}...' : body;
  }

  Future<T> _wrapErrors<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on TimeoutException {
      throw const TimeoutException('request timed out');
    } on SocketException catch (e) {
      throw NetworkException('network error: ${e.message}');
    } on http.ClientException catch (e) {
      throw NetworkException('client error: ${e.message}');
    }
  }

  /// GET /barcode/{barcode}. Throws [NotFoundException] if product is unknown.
  Future<Food> getByBarcode(String barcode) {
    return _wrapErrors(() async {
      final resp = await _client.get(_u('/barcode/$barcode')).timeout(timeout);
      return _decode(resp, Food.fromJson);
    });
  }

  /// GET /search?q=...
  Future<SearchResult> search(
    String query, {
    int page = 1,
    int pageSize = 20,
  }) {
    return _wrapErrors(() async {
      final url = _u('/search', {
        'q': query,
        'page': page,
        'page_size': pageSize,
      });
      final resp = await _client.get(url).timeout(timeout);
      return _decode(resp, SearchResult.fromJson);
    });
  }

  /// POST /estimate-meal as multipart/form-data.
  ///
  /// [imageBytes] should be raw JPEG/PNG/WebP bytes. [filename] is used only
  /// for the multipart part name and the server-side extension hint.
  Future<MealEstimate> estimateMeal(
    Uint8List imageBytes, {
    String filename = 'meal.jpg',
    String contentType = 'image/jpeg',
  }) {
    return _wrapErrors(() async {
      final parts = contentType.split('/');
      if (parts.length != 2) {
        throw const BadRequestException('contentType must be type/subtype');
      }
      final request = http.MultipartRequest('POST', _u('/estimate-meal'))
        ..files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: filename,
            contentType: MediaType(parts[0], parts[1]),
          ),
        );
      final streamed = await _client.send(request).timeout(timeout * 4);
      final resp = await http.Response.fromStream(streamed);
      return _decode(resp, MealEstimate.fromJson);
    });
  }

  /// GET /meal-plan. Uses Spoonacular through the backend.
  Future<MealPlanResponse> generateMealPlan({
    String timeFrame = 'day',
    int? targetCalories,
    String? diet,
  }) {
    return _wrapErrors(() async {
      final query = <String, dynamic>{
        'time_frame': timeFrame,
      };
      if (targetCalories != null) {
        query['target_calories'] = targetCalories;
      }
      if (diet != null && diet.trim().isNotEmpty) {
        query['diet'] = diet.trim();
      }
      final resp = await _client.get(_u('/meal-plan', query)).timeout(timeout);
      return _decode(resp, MealPlanResponse.fromJson);
    });
  }

  /// GET /recipes/{id}. Uses Spoonacular through the backend.
  Future<RecipeDetails> getRecipeDetails(String id) {
    return _wrapErrors(() async {
      final resp = await _client.get(_u('/recipes/$id')).timeout(timeout);
      return _decode(resp, RecipeDetails.fromJson);
    });
  }

  /// GET /storage/users/me — verify the current user is registered.
  /// Throws [NotFoundException] if the email is not in the users table.
  Future<void> getUserAccount() {
    return _wrapErrors(() async {
      final resp = await _client
          .get(_u('/storage/users/me'), headers: _userHeaders)
          .timeout(timeout);
      if (resp.statusCode >= 200 && resp.statusCode < 300) return;
      _throwForStatus(resp.statusCode, resp.body);
    });
  }

  /// POST /storage/users — create account row in the users table.
  Future<void> registerUser({required String email, required String displayName}) {
    return _wrapErrors(() async {
      await _client
          .post(
            _u('/storage/users'),
            headers: _jsonHeaders,
            body: jsonEncode({'email': email, 'display_name': displayName}),
          )
          .timeout(timeout);
    });
  }

  Future<StoredUserProfile> getStorageProfile() {
    return _wrapErrors(() async {
      final resp = await _client
          .get(_u('/storage/profile'), headers: _userHeaders)
          .timeout(timeout);
      return _decode(resp, StoredUserProfile.fromJson);
    });
  }

  Future<StoredUserProfile> saveStorageProfile(StoredUserProfile profile) {
    return _wrapErrors(() async {
      final resp = await _client
          .put(
            _u('/storage/profile'),
            headers: _jsonHeaders,
            body: jsonEncode(profile.toJson()),
          )
          .timeout(timeout);
      return _decode(resp, StoredUserProfile.fromJson);
    });
  }

  Future<DailyStorageSummary> getDailyStorageSummary({DateTime? date}) {
    return _wrapErrors(() async {
      final resp = await _client
          .get(
            _u('/storage/summary', {
              if (date != null) 'date': _date(date),
            }),
            headers: _userHeaders,
          )
          .timeout(timeout);
      return _decode(resp, DailyStorageSummary.fromJson);
    });
  }

  Future<MealLogEntry> addMealLog(MealLogEntry meal) {
    return _wrapErrors(() async {
      final resp = await _client
          .post(
            _u('/storage/meals'),
            headers: _jsonHeaders,
            body: jsonEncode(meal.toJson()),
          )
          .timeout(timeout);
      return _decode(resp, MealLogEntry.fromJson);
    });
  }

  Future<List<MealLogEntry>> getMealLogs({DateTime? date}) {
    return _wrapErrors(() async {
      final resp = await _client
          .get(
            _u('/storage/meals', {
              if (date != null) 'date': _date(date),
            }),
            headers: _userHeaders,
          )
          .timeout(timeout);
      return _decodeList(resp, MealLogEntry.fromJson);
    });
  }

  Future<void> deleteMealLog(String id) {
    return _wrapErrors(() async {
      final resp = await _client
          .delete(_u('/storage/meals/$id'), headers: _userHeaders)
          .timeout(timeout);
      if (resp.statusCode == 204) return;
      _throwForStatus(resp.statusCode, resp.body);
    });
  }

  Future<WaterLogEntry> addWaterLog(WaterLogEntry water) {
    return _wrapErrors(() async {
      final resp = await _client
          .post(
            _u('/storage/water'),
            headers: _jsonHeaders,
            body: jsonEncode(water.toJson()),
          )
          .timeout(timeout);
      return _decode(resp, WaterLogEntry.fromJson);
    });
  }

  Future<List<WaterLogEntry>> getWaterLogs({DateTime? date}) {
    return _wrapErrors(() async {
      final resp = await _client
          .get(
            _u('/storage/water', {
              if (date != null) 'date': _date(date),
            }),
            headers: _userHeaders,
          )
          .timeout(timeout);
      return _decodeList(resp, WaterLogEntry.fromJson);
    });
  }

  Future<WeightLogEntry> addWeightLog(WeightLogEntry weight) {
    return _wrapErrors(() async {
      final resp = await _client
          .post(
            _u('/storage/weight'),
            headers: _jsonHeaders,
            body: jsonEncode(weight.toJson()),
          )
          .timeout(timeout);
      return _decode(resp, WeightLogEntry.fromJson);
    });
  }

  Future<List<WeightLogEntry>> getWeightLogs({int limit = 30}) {
    return _wrapErrors(() async {
      final resp = await _client
          .get(
            _u('/storage/weight', {'limit': limit}),
            headers: _userHeaders,
          )
          .timeout(timeout);
      return _decodeList(resp, WeightLogEntry.fromJson);
    });
  }

  Future<ActivityLogEntry> addActivityLog(ActivityLogEntry activity) {
    return _wrapErrors(() async {
      final resp = await _client
          .post(
            _u('/storage/activity'),
            headers: _jsonHeaders,
            body: jsonEncode(activity.toJson()),
          )
          .timeout(timeout);
      return _decode(resp, ActivityLogEntry.fromJson);
    });
  }

  Future<List<ActivityLogEntry>> getActivityLogs({DateTime? date}) {
    return _wrapErrors(() async {
      final resp = await _client
          .get(
            _u('/storage/activity', {
              if (date != null) 'date': _date(date),
            }),
            headers: _userHeaders,
          )
          .timeout(timeout);
      return _decodeList(resp, ActivityLogEntry.fromJson);
    });
  }

  /// GET /health. Useful for connectivity checks and Settings -> "ping server".
  Future<bool> ping() async {
    try {
      final resp = await _client.get(_u('/health')).timeout(timeout);
      return resp.statusCode == 200;
    } on Object {
      return false;
    }
  }
}
