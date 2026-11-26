import 'media_enum_value.dart';

/// Result returned immediately after the original media file is uploaded.
///
/// A successful upload does not necessarily mean that media processing is
/// complete. Read [status] or fetch the asset details until it is ready.
class MebablMediaUploadResult {
  final String id;
  final MebablMediaEnumValue kind;
  final MebablMediaEnumValue visibility;
  final MebablMediaEnumValue status;
  final String originalFileName;
  final String originalContentType;
  final int originalSizeBytes;
  final String sha256Hash;
  final DateTime createdAt;

  const MebablMediaUploadResult({
    required this.id,
    required this.kind,
    required this.visibility,
    required this.status,
    required this.originalFileName,
    required this.originalContentType,
    required this.originalSizeBytes,
    required this.sha256Hash,
    required this.createdAt,
  });

  bool get isImage => kind.matches('Image', 1);
  bool get isVideo => kind.matches('Video', 2);
  bool get isPrivate => visibility.matches('Private', 1);
  bool get isPublic => visibility.matches('Public', 2);
  bool get isUnlisted => visibility.matches('Unlisted', 3);
  bool get isReady => status.matches('Ready', 5);

  factory MebablMediaUploadResult.fromJson(Map<String, dynamic> json) {
    return MebablMediaUploadResult(
      id: _requiredString(json, 'id'),
      kind: MebablMediaEnumValue.fromJson(json['kind']),
      visibility: MebablMediaEnumValue.fromJson(json['visibility']),
      status: MebablMediaEnumValue.fromJson(json['status']),
      originalFileName: _requiredString(json, 'originalFileName'),
      originalContentType: _requiredString(json, 'originalContentType'),
      originalSizeBytes: _requiredInt(json, 'originalSizeBytes'),
      sha256Hash: _requiredString(json, 'sha256Hash'),
      createdAt: _requiredDateTime(json, 'createdAt'),
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

DateTime _requiredDateTime(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException(
      'The media response field "$key" is missing or invalid.',
    );
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException(
      'The media response field "$key" is not a valid date.',
    );
  }
  return parsed;
}
