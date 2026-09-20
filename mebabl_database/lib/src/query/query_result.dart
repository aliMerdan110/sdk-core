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

    final Map<String, dynamic> data;

    if (rawData is Map) {
      data = Map<String, dynamic>.from(rawData);
    } else if (rawData is String) {
      throw FormatException('Query result data must be a JSON object.');
    } else {
      throw FormatException('Query result data must be a JSON object.');
    }

    return QueryResult(
      id: json['id'] as String,
      key: json['key'] as String,
      data: data,
      version: json['version'] as int? ?? 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'data': data,
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
