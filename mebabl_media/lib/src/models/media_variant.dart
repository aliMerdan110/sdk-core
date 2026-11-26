import 'media_enum_value.dart';

/// A processed derivative generated from an uploaded image or video.
class MebablMediaVariant {
  final MebablMediaEnumValue kind;
  final String contentType;
  final String extension;
  final int sizeBytes;
  final int? width;
  final int? height;
  final int? bitrateKbps;
  final String contentUrl;

  const MebablMediaVariant({
    required this.kind,
    required this.contentType,
    required this.extension,
    required this.sizeBytes,
    required this.width,
    required this.height,
    required this.bitrateKbps,
    required this.contentUrl,
  });

  bool get isThumbnail => kind.matches('Thumbnail', 1);
  bool get isPreview => kind.matches('Preview', 2);
  bool get isImageSmall => kind.matches('ImageSmall', 10);
  bool get isImageMedium => kind.matches('ImageMedium', 11);
  bool get isImageLarge => kind.matches('ImageLarge', 12);
  bool get isVideo360p => kind.matches('Video360p', 20);
  bool get isVideo480p => kind.matches('Video480p', 21);
  bool get isVideo720p => kind.matches('Video720p', 22);
  bool get isVideo1080p => kind.matches('Video1080p', 23);
  bool get isHlsMasterPlaylist => kind.matches('HlsMasterPlaylist', 30);

  String? get knownKindName => switch (kind.numericValue) {
    1 => 'Thumbnail',
    2 => 'Preview',
    10 => 'ImageSmall',
    11 => 'ImageMedium',
    12 => 'ImageLarge',
    20 => 'Video360p',
    21 => 'Video480p',
    22 => 'Video720p',
    23 => 'Video1080p',
    30 => 'HlsMasterPlaylist',
    _ => kind.name,
  };

  factory MebablMediaVariant.fromJson(Map<String, dynamic> json) {
    return MebablMediaVariant(
      kind: MebablMediaEnumValue.fromJson(json['kind']),
      contentType: _requiredString(json, 'contentType'),
      extension: _requiredString(json, 'extension'),
      sizeBytes: _requiredInt(json, 'sizeBytes'),
      width: _nullableInt(json['width']),
      height: _nullableInt(json['height']),
      bitrateKbps: _nullableInt(json['bitrateKbps']),
      contentUrl: _requiredString(json, 'contentUrl'),
    );
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw FormatException(
    'The media response field "$key" is missing or invalid.',
  );
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  throw FormatException(
    'The media response field "$key" is missing or invalid.',
  );
}

int? _nullableInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
