import 'chat_message.dart';
import 'json_helpers.dart';

class MebablChatMessagePage {
  final List<MebablChatMessage> items;
  final bool hasMore;
  final int? nextBeforeSequence;
  final int? nextAfterSequence;
  final int? snapshotSequence;

  const MebablChatMessagePage({
    required this.items,
    required this.hasMore,
    this.nextBeforeSequence,
    this.nextAfterSequence,
    this.snapshotSequence,
  });

  factory MebablChatMessagePage.fromJson(Object? value) {
    if (value is List) {
      return MebablChatMessagePage(
        items: readItems(value, 'messages')
            .map(MebablChatMessage.fromJson)
            .toList(growable: false),
        hasMore: false,
      );
    }

    final json = asJsonMap(value, 'message page');
    final rawItems = json['items'] ?? json['messages'] ?? json['data'];
    if (rawItems is! List) {
      throw const FormatException('Message page must contain an items array.');
    }

    return MebablChatMessagePage(
      items: rawItems
          .map((item) => MebablChatMessage.fromJson(asJsonMap(item, 'message')))
          .toList(growable: false),
      hasMore: json['hasMore'] == true,
      nextBeforeSequence: json['nextBeforeSequence'] == null
          ? null
          : intValue(json['nextBeforeSequence']),
      nextAfterSequence: json['nextAfterSequence'] == null
          ? null
          : intValue(json['nextAfterSequence']),
      snapshotSequence: (json['snapshotSequence'] ?? json['latestSequence']) == null
          ? null
          : intValue(json['snapshotSequence'] ?? json['latestSequence']),
    );
  }
}
