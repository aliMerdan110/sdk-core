/// One attachment on a post.
///
/// MediaAsset-backed attachments have [mediaAssetId]. StoredFile-backed
/// attachments use [storageFileId]; the latter is the retained API field name
/// and can reference files stored in the current Project Storage system.
class MebablPostAttachment {
  final String id;
  final String? storageFileId;
  final String type;
  final int order;
  final String name;
  final String path;
  final String? contentType;
  final int size;
  /// Compatibility metadata returned by the backend. It is not an
  /// authorization grant; Media Rules and Storage Rules remain authoritative.
  final bool isPublic;
  final DateTime createdAt;
  final String url;
  final String? mediaAssetId;

  const MebablPostAttachment({
    required this.id,
    required this.storageFileId,
    required this.type,
    required this.order,
    required this.name,
    required this.path,
    required this.contentType,
    required this.size,
    required this.isPublic,
    required this.createdAt,
    required this.url,
    required this.mediaAssetId,
  });

  factory MebablPostAttachment.fromJson(Map<String, dynamic> json) {
    return MebablPostAttachment(
      id: _requiredString(json, 'id'),
      storageFileId: _nullableString(json['storageFileId']),
      type: _requiredString(json, 'type'),
      order: _requiredInt(json, 'order'),
      name: _requiredString(json, 'name'),
      path: _requiredString(json, 'path', allowEmpty: true),
      contentType: _nullableString(json['contentType']),
      size: _requiredInt(json, 'size'),
      isPublic: _requiredBool(json, 'isPublic'),
      createdAt: _requiredDateTime(json, 'createdAt'),
      url: _requiredString(json, 'url'),
      mediaAssetId: _nullableString(json['mediaAssetId']),
    );
  }

  bool get isMediaAsset => mediaAssetId != null;

  bool get isStoredFile => storageFileId != null;

  /// Backwards-compatible alias. Prefer [isStoredFile].
  @Deprecated('Use isStoredFile; StoredFile attachments can use Project Storage V2.')
  bool get isLegacyStorageFile => isStoredFile;

  bool get isImage => type.toLowerCase() == 'image';

  bool get isVideo => type.toLowerCase() == 'video';

  bool get isAudio => type.toLowerCase() == 'audio';

  /// Resolves the backend's relative attachment URL against the configured
  /// API base URL. Absolute URLs are returned unchanged.
  Uri resolveUri(String baseUrl) {
    final attachmentUri = Uri.parse(url);
    if (attachmentUri.hasScheme) return attachmentUri;

    final normalizedBase = baseUrl.trim();
    if (normalizedBase.isEmpty) {
      throw ArgumentError.value(
        baseUrl,
        'baseUrl',
        'A base URL is required to resolve a relative attachment URL.',
      );
    }

    final baseUri = Uri.parse(
      normalizedBase.endsWith('/') ? normalizedBase : '$normalizedBase/',
    );
    return baseUri.resolve(url);
  }
}

String _requiredString(
  Map<String, dynamic> json,
  String key, {
  bool allowEmpty = false,
}) {
  final value = json[key];
  if (value is String && (allowEmpty || value.trim().isNotEmpty)) {
    return value;
  }
  throw FormatException(
    'The post attachment field "$key" is missing or invalid.',
  );
}

String? _nullableString(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  throw const FormatException('A nullable post attachment string is invalid.');
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) return value;
  if (value is num && value.isFinite && value == value.roundToDouble()) {
    return value.toInt();
  }
  throw FormatException(
    'The post attachment field "$key" is missing or invalid.',
  );
}

bool _requiredBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is bool) return value;
  throw FormatException(
    'The post attachment field "$key" is missing or invalid.',
  );
}

DateTime _requiredDateTime(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException(
      'The post attachment field "$key" is missing or invalid.',
    );
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException(
      'The post attachment field "$key" is not a valid date.',
    );
  }
  return parsed;
}
