import 'chat_participant.dart';
import 'json_helpers.dart';
import 'chat_message.dart';

class MebablChatConversation {
  final String id;
  final String type;
  final String? title;
  final String? imageUrl;
  final DateTime createdAtUtc;
  final DateTime? lastMessageAtUtc;
  final int lastSequence;
  final int lastEventSequence;
  final int unreadCount;
  final bool isArchived;
  final bool isMuted;
  final DateTime? mutedUntilUtc;
  final bool isPinned;
  final MebablChatMessage? lastMessage;
  final List<MebablChatParticipant> participants;

  const MebablChatConversation({
    required this.id,
    required this.type,
    this.title,
    this.imageUrl,
    required this.createdAtUtc,
    this.lastMessageAtUtc,
    this.lastSequence = 0,
    this.lastEventSequence = 0,
    this.unreadCount = 0,
    this.isArchived = false,
    this.isMuted = false,
    this.mutedUntilUtc,
    this.isPinned = false,
    this.lastMessage,
    this.participants = const [],
  });

  bool get isGroup => type.toLowerCase() == 'group';
  List<String> get participantIds =>
      participants.map((item) => item.userId).toList(growable: false);

  factory MebablChatConversation.fromJson(Map<String, dynamic> json) {
    final rawParticipants = json['participants'];
    final rawParticipantIds = json['participantIds'];
    final rawLastMessage = json['lastMessage'];
    final isGroup = json['isGroup'] == true;

    final participants = <MebablChatParticipant>[];
    if (rawParticipants is List) {
      participants.addAll(
        rawParticipants.map(
          (item) => MebablChatParticipant.fromJson(asJsonMap(item, 'participant')),
        ),
      );
    } else if (rawParticipantIds is List) {
      for (final id in rawParticipantIds.whereType<String>()) {
        participants.add(
          MebablChatParticipant(userId: id, role: 'member'),
        );
      }
    }

    return MebablChatConversation(
      id: requiredString(json, 'id', alias: 'conversationId'),
      type: optionalString(json, 'type') ?? (isGroup ? 'group' : 'direct'),
      title: optionalString(json, 'title'),
      imageUrl: optionalString(json, 'imageUrl'),
      createdAtUtc: optionalDateTime(json['createdAtUtc'] ?? json['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      lastMessageAtUtc: optionalDateTime(json['lastMessageAtUtc'] ?? json['lastMessageAt']),
      lastSequence: intValue(
        json['lastSequence'] ?? json['lastMessageSequence'],
      ),
      lastEventSequence: intValue(json['lastEventSequence']),
      unreadCount: intValue(json['unreadCount']),
      isArchived: json['isArchived'] == true ||
          json['archivedAtUtc'] != null,
      isMuted: json['isMuted'] == true,
      mutedUntilUtc: optionalDateTime(json['mutedUntilUtc']),
      isPinned: json['isPinned'] == true || json['isPinnedInInbox'] == true,
      lastMessage: rawLastMessage is Map
          ? MebablChatMessage.fromJson(asJsonMap(rawLastMessage, 'lastMessage'))
          : null,
      participants: List.unmodifiable(participants),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'isGroup': isGroup,
        'title': title,
        'imageUrl': imageUrl,
        'createdAtUtc': createdAtUtc.toIso8601String(),
        'lastMessageAtUtc': lastMessageAtUtc?.toIso8601String(),
        'lastSequence': lastSequence,
        'lastEventSequence': lastEventSequence,
        'unreadCount': unreadCount,
        'isArchived': isArchived,
        'isMuted': isMuted,
        'mutedUntilUtc': mutedUntilUtc?.toIso8601String(),
        'isPinned': isPinned,
        'lastMessage': lastMessage?.toJson(),
        'participants': participants.map((item) => item.toJson()).toList(),
      };
}
