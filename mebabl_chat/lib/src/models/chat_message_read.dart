import 'json_helpers.dart';

/// Server-confirmed read receipt or a receipt inferred from the conversation cursor.
class MebablChatMessageRead {
  final String? id;
  final String messageId;
  final String userId;
  final DateTime readAtUtc;
  final bool isInferredFromConversationCursor;

  const MebablChatMessageRead({
    this.id,
    required this.messageId,
    required this.userId,
    required this.readAtUtc,
    this.isInferredFromConversationCursor = false,
  });

  factory MebablChatMessageRead.fromJson(Map<String, dynamic> json) =>
      MebablChatMessageRead(
        id: json['id'] is String ? json['id'] as String : null,
        messageId: requiredString(json, 'messageId'),
        userId: requiredString(json, 'userId'),
        readAtUtc: requiredDateTime(json, 'readAt'),
        isInferredFromConversationCursor: json['isInferredFromConversationCursor'] == true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'messageId': messageId,
        'userId': userId,
        'readAt': readAtUtc.toUtc().toIso8601String(),
        'isInferredFromConversationCursor': isInferredFromConversationCursor,
      };
}
