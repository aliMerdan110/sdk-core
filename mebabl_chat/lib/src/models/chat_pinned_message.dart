import 'chat_message.dart';
import 'json_helpers.dart';

class MebablChatPinnedMessage {
  final String id;
  final String conversationId;
  final String messageId;
  final String pinnedByUserId;
  final DateTime pinnedAtUtc;
  final DateTime? expiresAtUtc;
  final MebablChatMessage? message;

  const MebablChatPinnedMessage({
    required this.id,
    required this.conversationId,
    required this.messageId,
    required this.pinnedByUserId,
    required this.pinnedAtUtc,
    this.expiresAtUtc,
    this.message,
  });

  factory MebablChatPinnedMessage.fromJson(Map<String, dynamic> json) {
    final rawMessage = json['message'];
    return MebablChatPinnedMessage(
      id: requiredString(json, 'id'),
      conversationId: requiredString(json, 'conversationId'),
      messageId: requiredString(json, 'messageId'),
      pinnedByUserId: requiredString(json, 'pinnedByUserId'),
      pinnedAtUtc: optionalDateTime(json['pinnedAtUtc'] ?? json['pinnedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      expiresAtUtc: optionalDateTime(json['expiresAtUtc']),
      message: rawMessage is Map
          ? MebablChatMessage.fromJson(asJsonMap(rawMessage, 'pinned message'))
          : null,
    );
  }
}
