import 'dart:convert';

import 'json_helpers.dart';

/// Structured reference embedded in a Chat message for a shared Content post.
/// Only the post ID is authoritative; the receiver loads the post from Content
/// API using its own authenticated session.
class MebablChatPostSharePayload {
  static const String messageType = 'post_share';
  static const int currentSchemaVersion = 1;

  final String postId;
  final int schemaVersion;

  const MebablChatPostSharePayload({
    required this.postId,
    this.schemaVersion = currentSchemaVersion,
  });

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'postId': postId,
      };

  factory MebablChatPostSharePayload.fromJson(Map<String, dynamic> json) {
    final version = intValue(json['schemaVersion']);
    if (version != currentSchemaVersion) {
      throw FormatException('Unsupported shared-post schema version: $version.');
    }
    return MebablChatPostSharePayload(
      postId: requiredString(json, 'postId'),
      schemaVersion: version,
    );
  }

  static MebablChatPostSharePayload? tryParseContent(String? content) {
    if (content == null || content.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(content);
      if (decoded is! Map) return null;
      return MebablChatPostSharePayload.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}
