class MebablException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const MebablException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() {
    if (statusCode == null) {
      return 'MebablException: $message';
    }

    return 'MebablException [$statusCode]: $message';
  }
}
