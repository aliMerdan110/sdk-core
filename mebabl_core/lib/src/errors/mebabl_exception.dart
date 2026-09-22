class MebablException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const MebablException({
    required this.message,
    this.statusCode,
    this.data,
  });

  bool get isUnauthorized => statusCode == 401;

  bool get isForbidden => statusCode == 403;

  bool get isNotFound => statusCode == 404;

  bool get isValidationError => statusCode == 400;

  bool get isServerError => statusCode != null && statusCode! >= 500;

  bool get isNetworkError => statusCode == null;

  @override
  String toString() {
    if (statusCode == null) {
      return 'MebablException: $message';
    }

    return 'MebablException [$statusCode]: $message';
  }
}
