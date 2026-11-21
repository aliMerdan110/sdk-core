import 'dart:typed_data';

/// A streamed Storage response, suitable for large files.
///
/// The caller owns the returned stream and should consume or cancel it.
class MebablStorageContentStream {
  final Stream<Uint8List> stream;
  final String? contentType;
  final int? contentLength;
  final String? contentRange;
  final int statusCode;

  const MebablStorageContentStream({
    required this.stream,
    required this.contentType,
    required this.contentLength,
    required this.contentRange,
    required this.statusCode,
  });
}
