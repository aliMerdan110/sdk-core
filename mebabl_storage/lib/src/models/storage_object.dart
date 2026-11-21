/// Metadata for one object returned by the Storage listing endpoint.
class MebablStorageObject {
  final String id;
  final String bucketId;
  final String path;
  final String fileName;
  final String contentType;
  final int size;
  final DateTime? createdAt;
  final String contentUrl;

  const MebablStorageObject({
    required this.id,
    required this.bucketId,
    required this.path,
    required this.fileName,
    required this.contentType,
    required this.size,
    required this.createdAt,
    required this.contentUrl,
  });

  factory MebablStorageObject.fromJson(Map<String, dynamic> json) {
    return MebablStorageObject(
      id: _requiredString(json, 'id'),
      bucketId: _requiredString(json, 'bucketId'),
      path: _requiredString(json, 'path'),
      fileName: _requiredString(json, 'fileName'),
      contentType: _requiredString(json, 'contentType'),
      size: _requiredInt(json, 'size'),
      createdAt: _optionalDateTime(json['createdAt'] ?? json['CreatedAt']),
      contentUrl: _requiredString(json, 'contentUrl'),
    );
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key] ?? json[_pascalCase(key)];
  if (value is String && value.trim().isNotEmpty) return value;
  throw FormatException(
    'The Storage response field "$key" is missing or invalid.',
  );
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key] ?? json[_pascalCase(key)];
  if (value is int) return value;
  if (value is num) return value.toInt();
  throw FormatException(
    'The Storage response field "$key" is missing or invalid.',
  );
}

String _pascalCase(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

DateTime? _optionalDateTime(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
