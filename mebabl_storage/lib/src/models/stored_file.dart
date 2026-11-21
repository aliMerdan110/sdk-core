/// Safe metadata for a file created by the Storage upload endpoint.
///
/// The current backend upload endpoint serializes a StoredFile entity. This
/// model deliberately reads only public metadata and never exposes internal
/// fields such as StorageKey or StorageProviderKey.
class MebablStoredFile {
  final String id;
  final String bucketId;
  final String path;
  final String fileName;
  final String contentType;
  final int size;
  final DateTime? createdAt;
  final String? hash;
  final int? version;

  const MebablStoredFile({
    required this.id,
    required this.bucketId,
    required this.path,
    required this.fileName,
    required this.contentType,
    required this.size,
    this.createdAt,
    this.hash,
    this.version,
  });

  String get name => fileName.contains('.')
      ? fileName.substring(0, fileName.lastIndexOf('.'))
      : fileName;

  factory MebablStoredFile.fromJson(Map<String, dynamic> json) {
    return MebablStoredFile(
      id: _requiredString(json, 'id'),
      bucketId: _requiredString(json, 'bucketId'),
      path: _requiredString(json, 'path'),
      fileName: _requiredString(json, 'fileName'),
      contentType: _requiredString(json, 'contentType'),
      size: _requiredInt(json, 'size'),
      createdAt: _optionalDateTime(_value(json, 'createdAt')),
      hash: _optionalString(_value(json, 'hash')),
      version: _optionalInt(_value(json, 'version')),
    );
  }
}

Object? _value(Map<String, dynamic> json, String key) =>
    json[key] ?? json[_pascalCase(key)];

String _pascalCase(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

String _requiredString(Map<String, dynamic> json, String key) {
  final value = _value(json, key);
  if (value is String && value.trim().isNotEmpty) return value;
  throw FormatException(
    'The Storage response field "$key" is missing or invalid.',
  );
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = _value(json, key);
  if (value is int) return value;
  if (value is num) return value.toInt();
  throw FormatException(
    'The Storage response field "$key" is missing or invalid.',
  );
}

String? _optionalString(Object? value) => value is String ? value : null;

int? _optionalInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

DateTime? _optionalDateTime(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

/// Backwards-compatible public name for uploaded Storage file metadata.
///
/// [StorageFile] and [MebablStoredFile] refer to the same immutable model.
/// New code may use either name.
typedef StorageFile = MebablStoredFile;
