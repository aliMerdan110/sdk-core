import 'post_attachment.dart';

class Post {
  final String id;
  final String ownerId;
  final String? text;
  final DateTime createdAt;
  final List<PostAttachment> attachments;

  const Post({
    required this.id,
    required this.ownerId,
    this.text,
    required this.createdAt,
    required this.attachments,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      text: json['text'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      attachments: (json['attachments'] as List<dynamic>? ?? [])
          .map((item) => PostAttachment.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
