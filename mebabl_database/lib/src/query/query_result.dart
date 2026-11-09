/// A document returned by a Mebabl database query.
///
/// [version] is the optimistic-concurrency version. Pass it to document
/// update/delete operations to prevent overwriting a newer document.
class QueryResult {
  final String id;
  final String key;
  final Map<String, dynamic> data;
  final int version;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const QueryResult({
    required this.id,
    required this.key,
    required this.data,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QueryResult.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    if (rawData is! Map) {
      throw const FormatException('Query result data must be a JSON object.');
    }

    final id = json['id'];
    final key = json['key'];
    final rawVersion = json['version'] ?? 1;
    final rawCreatedAt = json['createdAt'];
    final rawUpdatedAt = json['updatedAt'];

    if (id is! String || id.trim().isEmpty) {
      throw const FormatException(
        'Query result id must be a non-empty string.',
      );
    }
    if (key is! String) {
      throw const FormatException('Query result key must be a string.');
    }
    if (rawVersion is! int || rawVersion < 1) {
      throw const FormatException(
        'Query result version must be a positive integer.',
      );
    }
    if (rawCreatedAt is! String) {
      throw const FormatException(
        'Query result createdAt must be an ISO-8601 string.',
      );
    }
    if (rawUpdatedAt != null && rawUpdatedAt is! String) {
      throw const FormatException(
        'Query result updatedAt must be a string or null.',
      );
    }

    return QueryResult(
      id: id,
      key: key,
      data: Map<String, dynamic>.from(rawData),
      version: rawVersion,
      createdAt: _parseDateTime(rawCreatedAt, 'createdAt'),
      updatedAt: rawUpdatedAt == null
          ? null
          : _parseDateTime(rawUpdatedAt as String, 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'key': key,
    'data': data,
    'version': version,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  static DateTime _parseDateTime(String value, String field) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('Query result $field is not a valid date.');
    }
    return parsed;
  }
}
