import 'chat_message.dart';
import 'json_helpers.dart';

/// Incremental message synchronization response matching SyncMessagesResponse.
/// The backend returns event sequence separately from each message sequence,
/// and omits ConversationId from individual items.
class MebablChatMessageSyncPage {
  final List<MebablChatMessage> messages;
  final List<String> deletedMessageIds;
  final int nextEventSequence;
  final bool hasMore;
  final bool cursorAhead;

  const MebablChatMessageSyncPage({
    required this.messages,
    required this.deletedMessageIds,
    required this.nextEventSequence,
    required this.hasMore,
    this.cursorAhead = false,
  });

  factory MebablChatMessageSyncPage.fromJson(Object? value) {
    final json = asJsonMap(value, 'message sync response');
    final rawItems = json['items'] ?? json['messages'] ?? const [];
    final conversationId = optionalString(json, 'conversationId');
    final parsed = <MebablChatMessage>[];
    final deleted = <String>{
      if (json['deletedMessageIds'] is List)
        ...(json['deletedMessageIds'] as List).whereType<String>(),
    };

    if (rawItems is List) {
      for (final rawItem in rawItems) {
        final item = Map<String, dynamic>.from(asJsonMap(rawItem, 'sync item'));
        if (item['conversationId'] == null && conversationId != null) {
          item['conversationId'] = conversationId;
        }
        // Sync items use EventSequence while ordinary message DTOs use Sequence.
        item['sequence'] ??= item['messageSequence'];
        final message = MebablChatMessage.fromJson(item);
        if (message.isDeleted) {
          deleted.add(message.id);
        } else {
          parsed.add(message);
        }
      }
    }

    return MebablChatMessageSyncPage(
      messages: List.unmodifiable(parsed),
      deletedMessageIds: List.unmodifiable(deleted),
      nextEventSequence: intValue(
        json['nextAfterEventSequence'] ??
            json['nextEventSequence'] ??
            json['nextCursor'] ??
            json['eventSequence'],
      ),
      hasMore: json['hasMore'] == true,
      cursorAhead: json['cursorAhead'] == true,
    );
  }
}
