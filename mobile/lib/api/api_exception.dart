/// Typed exceptions for the NutriFit backend client.
///
/// Catch [ApiException] for any failure. Use subtype matching when the UI
/// needs to react differently (e.g. NotFound -> "no product for that barcode",
/// NetworkException -> "you are offline").
library;

sealed class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class NetworkException extends ApiException {
  const NetworkException(super.message) : super(statusCode: null);
}

class TimeoutException extends ApiException {
  const TimeoutException(super.message) : super(statusCode: null);
}

class BadRequestException extends ApiException {
  const BadRequestException(super.message) : super(statusCode: 400);
}

class NotFoundException extends ApiException {
  const NotFoundException(super.message) : super(statusCode: 404);
}

class ValidationException extends ApiException {
  const ValidationException(super.message) : super(statusCode: 422);
}

class ServerException extends ApiException {
  const ServerException(super.message, {required int super.statusCode});
}

class UpstreamException extends ApiException {
  const UpstreamException(super.message) : super(statusCode: 502);
}
