class PostAttachment {
  final String id;
  final String storageFileId;
  final String type;
  final int order;
  final String? name;
  final String? path;
  final String? contentType;
  final int? size;
  final bool? isPublic;
  final DateTime? createdAt;
  final String? url;

  const PostAttachment({
    required this.id,
    required this.storageFileId,
    required this.type,
    required this.order,
    this.name,
    this.path,
    this.contentType,
    this.size,
    this.isPublic,
    this.createdAt,
    this.url,
  });

  factory PostAttachment.fromJson(Map<String, dynamic> json) {
    return PostAttachment(
      id: json['id'] as String,
      storageFileId: json['storageFileId'] as String,
      type: json['type'] as String,
      order: json['order'] as int,
      name: json['name'] as String?,
      path: json['path'] as String?,
      contentType: json['contentType'] as String?,
      size: json['size'] as int?,
      isPublic: json['isPublic'] as bool?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      url: json['url'] as String?,
    );
  }
}
