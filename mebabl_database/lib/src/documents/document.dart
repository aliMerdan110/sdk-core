/// A JSON document stored in a project-owned Mebabl collection.
///
/// [version] is the optimistic-concurrency value. Pass it as
/// `expectedVersion` when updating or deleting the document. A successful
/// update or delete advances the version.
class Document {
  final String id;
  final String key;
  final Map<String, dynamic> data;
  final int version;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Document({
    required this.id,
    required this.key,
    required Map<String, dynamic> data,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  }) : data = Map<String, dynamic>.unmodifiable(data);

  factory Document.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    if (rawData is! Map) {
      throw const FormatException('Document.data must be a JSON object.');
    }

    final Map<String, dynamic> documentData;
    try {
      documentData = Map<String, dynamic>.from(rawData);
    } on TypeError {
      throw const FormatException(
        'Document.data must contain string property names.',
      );
    }

    final version = json['version'] ?? 1;
    if (version is! int || version < 1) {
      throw const FormatException(
        'Document.version must be a positive integer.',
      );
    }

    return Document(
      id: _requiredString(json, 'id'),
      key: _requiredString(json, 'key'),
      data: documentData,
      version: version,
      createdAt: _requiredDateTime(json, 'createdAt'),
      updatedAt: _optionalDateTime(json, 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'key': key,
      'data': data,
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Document.$key must be a non-empty string.');
    }
    return value;
  }

  static DateTime _requiredDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Document.$key must be an ISO-8601 string.');
    }
    try {
      return DateTime.parse(value);
    } on FormatException {
      throw FormatException('Document.$key is not a valid date/time.');
    }
  }

  static DateTime? _optionalDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! String || value.isEmpty) {
      throw FormatException(
        'Document.$key must be a date/time string or null.',
      );
    }
    try {
      return DateTime.parse(value);
    } on FormatException {
      throw FormatException('Document.$key is not a valid date/time.');
    }
  }
}
