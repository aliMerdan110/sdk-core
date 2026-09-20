class Document {
  final String id;
  final String key;
  final Map<String, dynamic> data;
  final int version;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Document({
    required this.id,
    required this.key,
    required this.data,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];

    if (rawData is! Map) {
      throw FormatException('Document data must be a JSON object.');
    }

    return Document(
      id: json['id'] as String,
      key: json['key'] as String,
      data: Map<String, dynamic>.from(rawData),
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
