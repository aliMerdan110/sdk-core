import 'dart:typed_data';

/// A streamed response for media content.
///
/// Use this for large video files instead of buffering the entire file in
/// memory with a byte download operation. The request may have included the
/// User JWT or may have been anonymous, depending on the option used to open it.
class MebablMediaContentStream {
  final Stream<Uint8List> stream;
  final String? contentType;
  final int? contentLength;
  final String? contentRange;
  final int statusCode;

  const MebablMediaContentStream({
    required this.stream,
    required this.contentType,
    required this.contentLength,
    required this.contentRange,
    required this.statusCode,
  });
}
