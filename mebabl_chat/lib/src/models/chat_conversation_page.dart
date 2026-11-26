import 'chat_conversation.dart';
import 'json_helpers.dart';

class MebablChatConversationPage {
  final List<MebablChatConversation> items;
  final bool hasMore;
  final String? nextCursor;

  const MebablChatConversationPage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  factory MebablChatConversationPage.fromJson(Object? value) {
    if (value is List) {
      return MebablChatConversationPage(
        items: readItems(value, 'conversations')
            .map(MebablChatConversation.fromJson)
            .toList(growable: false),
        hasMore: false,
      );
    }
    final json = asJsonMap(value, 'conversation page');
    final raw = json['items'] ?? json['conversations'] ?? json['data'];
    if (raw is! List) {
      throw const FormatException('Conversation page must contain an items array.');
    }
    return MebablChatConversationPage(
      items: raw
          .map((item) => MebablChatConversation.fromJson(asJsonMap(item, 'conversation')))
          .toList(growable: false),
      hasMore: json['hasMore'] == true,
      nextCursor: optionalString(json, 'nextCursor'),
    );
  }
}
