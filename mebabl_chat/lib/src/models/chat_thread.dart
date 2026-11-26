import 'chat_message.dart';
import 'json_helpers.dart';

class MebablChatThread {
  final MebablChatMessage rootMessage;
  final List<MebablChatMessage> replies;
  final bool hasMore;
  final int? nextBeforeSequence;

  const MebablChatThread({
    required this.rootMessage,
    required this.replies,
    required this.hasMore,
    this.nextBeforeSequence,
  });

  factory MebablChatThread.fromJson(Object? value) {
    final json = asJsonMap(value, 'thread response');
    final root = json['rootMessage'] ?? json['root'];
    final replies = json['replies'] ?? json['items'] ?? const [];
    if (root is! Map || replies is! List) {
      throw const FormatException('Thread response has an invalid shape.');
    }
    return MebablChatThread(
      rootMessage: MebablChatMessage.fromJson(asJsonMap(root, 'thread root')),
      replies: replies
          .map((item) => MebablChatMessage.fromJson(asJsonMap(item, 'thread reply')))
          .toList(growable: false),
      hasMore: json['hasMore'] == true,
      nextBeforeSequence: json['nextBeforeSequence'] == null
          ? null
          : intValue(json['nextBeforeSequence']),
    );
  }
}
