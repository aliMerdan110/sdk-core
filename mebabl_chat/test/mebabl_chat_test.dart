import 'package:flutter_test/flutter_test.dart';
import 'package:mebabl_chat/mebabl_chat.dart';

void main() {
  group('MebablChatMessage', () {
    test('parses message DTO using UTC timestamps and cursor fields', () {
      final message = MebablChatMessage.fromJson({
        'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'conversationId': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'senderId': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        'clientMessageId': 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        'sequence': 12,
        'type': 'text',
        'content': 'Hello',
        'createdAtUtc': '2026-11-23T10:00:00Z',
        'attachments': <Object?>[],
        'reactions': <Object?>[],
      });

      expect(message.sequence, 12);
      expect(message.content, 'Hello');
      expect(message.createdAtUtc.isUtc, isTrue);
      expect(message.attachments, isEmpty);
    });
  });

  group('MebablChatService', () {
    test('generates a UUID v4 client message id', () {
      final id = MebablChatService.createClientMessageId();

      expect(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ).hasMatch(id),
        isTrue,
      );
    });
  });

  group('MebablChatMessageSyncPage', () {
    test('parses deleted message ids and event cursor', () {
      final page = MebablChatMessageSyncPage.fromJson({
        'messages': <Object?>[],
        'deletedMessageIds': ['aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'],
        'nextEventSequence': 91,
        'hasMore': false,
      });

      expect(page.deletedMessageIds, hasLength(1));
      expect(page.nextEventSequence, 91);
      expect(page.hasMore, isFalse);
    });
  });
}
