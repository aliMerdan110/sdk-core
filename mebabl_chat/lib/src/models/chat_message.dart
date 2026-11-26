import 'chat_attachment.dart';
import 'chat_reaction.dart';
import 'json_helpers.dart';

class MebablChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String? clientMessageId;
  final int sequence;
  final String type;
  final String? content;
  final String? replyToMessageId;
  final String? threadRootMessageId;
  final String? forwardedFromMessageId;
  final DateTime createdAtUtc;
  final DateTime? editedAtUtc;
  final DateTime? expiresAtUtc;
  final bool isEdited;
  final bool isDeleted;
  final List<MebablChatAttachment> attachments;
  final List<MebablChatReaction> reactions;
  final int deliveredCount;
  final int readCount;

  const MebablChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.clientMessageId,
    required this.sequence,
    required this.type,
    this.content,
    this.replyToMessageId,
    this.threadRootMessageId,
    this.forwardedFromMessageId,
    required this.createdAtUtc,
    this.editedAtUtc,
    this.expiresAtUtc,
    this.isEdited = false,
    this.isDeleted = false,
    this.attachments = const [],
    this.reactions = const [],
    this.deliveredCount = 0,
    this.readCount = 0,
  });

  MebablChatMessage copyWith({
    List<MebablChatAttachment>? attachments,
    List<MebablChatReaction>? reactions,
    String? content,
    bool? isDeleted,
    bool? isEdited,
    DateTime? editedAtUtc,
  }) {
    return MebablChatMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      clientMessageId: clientMessageId,
      sequence: sequence,
      type: type,
      content: content ?? this.content,
      replyToMessageId: replyToMessageId,
      threadRootMessageId: threadRootMessageId,
      forwardedFromMessageId: forwardedFromMessageId,
      createdAtUtc: createdAtUtc,
      editedAtUtc: editedAtUtc ?? this.editedAtUtc,
      expiresAtUtc: expiresAtUtc,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      attachments: attachments ?? this.attachments,
      reactions: reactions ?? this.reactions,
      deliveredCount: deliveredCount,
      readCount: readCount,
    );
  }

  factory MebablChatMessage.fromJson(Map<String, dynamic> json) {
    final rawAttachments = json['attachments'];
    final rawReactions = json['reactions'];
    return MebablChatMessage(
      id: requiredString(json, 'id', alias: 'messageId'),
      conversationId: requiredString(json, 'conversationId'),
      senderId: requiredString(json, 'senderId'),
      clientMessageId: optionalString(json, 'clientMessageId'),
      sequence: intValue(json['sequence'] ?? json['messageSequence']),
      type: optionalString(json, 'type') ?? optionalString(json, 'messageType') ?? 'text',
      content: optionalString(json, 'content') ?? optionalString(json, 'text'),
      replyToMessageId: optionalString(json, 'replyToMessageId'),
      threadRootMessageId: optionalString(json, 'threadRootMessageId'),
      forwardedFromMessageId: optionalString(json, 'forwardedFromMessageId'),
      createdAtUtc: optionalDateTime(json['createdAtUtc'] ?? json['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      editedAtUtc: optionalDateTime(json['editedAtUtc'] ?? json['editedAt']),
      expiresAtUtc: optionalDateTime(json['expiresAtUtc']),
      isEdited: json['isEdited'] == true,
      isDeleted: json['isDeleted'] == true,
      attachments: rawAttachments is List
          ? rawAttachments
              .map((item) => MebablChatAttachment.fromJson(asJsonMap(item, 'attachment')))
              .toList(growable: false)
          : const [],
      reactions: rawReactions is List
          ? rawReactions
              .map((item) => MebablChatReaction.fromJson(asJsonMap(item, 'reaction')))
              .toList(growable: false)
          : const [],
      deliveredCount: intValue(json['deliveredCount'] ?? json['deliveredByCount']),
      readCount: intValue(json['readCount'] ?? json['readByCount']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'clientMessageId': clientMessageId,
        'sequence': sequence,
        'type': type,
        'content': content,
        'replyToMessageId': replyToMessageId,
        'threadRootMessageId': threadRootMessageId,
        'forwardedFromMessageId': forwardedFromMessageId,
        'createdAtUtc': createdAtUtc.toIso8601String(),
        'editedAtUtc': editedAtUtc?.toIso8601String(),
        'expiresAtUtc': expiresAtUtc?.toIso8601String(),
        'isEdited': isEdited,
        'isDeleted': isDeleted,
        'attachments': attachments.map((item) => item.toJson()).toList(),
        'reactions': reactions.map((item) => item.toJson()).toList(),
        'deliveredCount': deliveredCount,
        'readCount': readCount,
      };
}
