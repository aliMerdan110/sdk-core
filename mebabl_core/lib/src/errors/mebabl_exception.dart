/// A normalized exception returned by the Mebabl SDK.
///
/// Applications should classify failures using [statusCode] and the helper
/// getters, not by comparing the server's localized [message].
class MebablException implements Exception {
  final String message;
  final int? statusCode;
  final Object? data;
  final String? code;
  final String? requestPath;
  final Object? cause;

  const MebablException({
    required this.message,
    this.statusCode,
    this.data,
    this.code,
    this.requestPath,
    this.cause,
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidationError => statusCode == 400 || statusCode == 422;
  bool get isConflict => statusCode == 409;
  bool get isRateLimited => statusCode == 429;
  bool get isClientError =>
      statusCode != null && statusCode! >= 400 && statusCode! < 500;
  bool get isServerError => statusCode != null && statusCode! >= 500;
  bool get isTimeout =>
      code == 'connectionTimeout' ||
      code == 'sendTimeout' ||
      code == 'receiveTimeout';
  bool get isCancelled => code == 'cancel';
  bool get isNetworkError => statusCode == null && !isCancelled;

  @override
  String toString() {
    final status = statusCode;
    if (status == null) return 'MebablException: $message';
    return 'MebablException [$status]: $message';
  }
}
