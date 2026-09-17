class StorageFile {
  final String id;
  final String name;
  final String path;
  final String contentType;
  final int size;
  final bool isPublic;
  final DateTime? createdAt;

  const StorageFile({
    required this.id,
    required this.name,
    required this.path,
    required this.contentType,
    required this.size,
    required this.isPublic,
    this.createdAt,
  });

  factory StorageFile.fromJson(Map<String, dynamic> json) {
    return StorageFile(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      contentType: json['contentType'] as String? ?? 'application/octet-stream',
      size: (json['size'] as num?)?.toInt() ?? 0,
      isPublic: json['isPublic'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'contentType': contentType,
      'size': size,
      'isPublic': isPublic,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
