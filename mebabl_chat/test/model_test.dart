import 'package:flutter_test/flutter_test.dart';
import 'package:mebabl_chat/mebabl_chat.dart';

void main() {
  group('MebablChatMessage', () {
    test('parses the current backend message DTO', () {
      final message = MebablChatMessage.fromJson({
        'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'conversationId': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'senderId': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        'clientMessageId': 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        'sequence': 12,
        'messageType': 'text',
        'content': 'Hello',
        'createdAt': '2026-11-23T10:00:00Z',
        'replyToMessageId': null,
        'threadRootMessageId': null,
        'isEdited': false,
        'isDeleted': false,
      });

      expect(message.sequence, 12);
      expect(message.type, 'text');
      expect(message.content, 'Hello');
      expect(message.createdAtUtc.isUtc, isTrue);
      expect(message.attachments, isEmpty);
    });
  });

  group('MebablChatService', () {
    test('generates a UUID client message id', () {
      final id = MebablChatService.createClientMessageId();
      expect(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ).hasMatch(id),
        isTrue,
      );
    });
  });

  group('Backend contract models', () {
    test('parses conversations returned as GetConversationsResponse array', () {
      final page = MebablChatConversationPage.fromJson([
        {
          'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
          'title': null,
          'isGroup': false,
          'createdAt': '2026-11-23T10:00:00Z',
          'participantIds': [
            'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
            'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
          ],
          'lastReadAt': null,
          'lastReadMessageId': null,
          'lastMessageSequence': 8,
          'lastEventSequence': 13,
          'lastDeliveredSequence': 8,
          'lastReadSequence': 7,
          'unreadCount': 1,
        },
      ]);

      expect(page.items.single.isGroup, isFalse);
      expect(page.items.single.participantIds, hasLength(2));
      expect(page.items.single.lastSequence, 8);
      expect(page.items.single.lastEventSequence, 13);
      expect(page.items.single.unreadCount, 1);
    });

    test('parses the CreateConversationResponse shape', () {
      final conversation = MebablChatConversation.fromJson({
        'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'title': 'Team',
        'isGroup': true,
        'createdAt': '2026-11-23T10:00:00Z',
        'lastMessageSequence': 4,
        'lastEventSequence': 7,
      });

      expect(conversation.isGroup, isTrue);
      expect(conversation.lastEventSequence, 7);
      expect(conversation.title, 'Team');
      expect(conversation.participantIds, isEmpty);
    });

    test('parses sequence-based message page and snapshot', () {
      final page = MebablChatMessagePage.fromJson({
        'conversationId': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'latestSequence': 25,
        'hasMore': true,
        'nextBeforeSequence': 10,
        'items': [
          {
            'id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
            'conversationId': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
            'senderId': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
            'content': 'Page item',
            'messageType': 'text',
            'isEdited': false,
            'editedAt': null,
            'createdAt': '2026-11-23T10:00:00Z',
            'sequence': 10,
            'clientMessageId': null,
            'replyToMessageId': null,
            'threadRootMessageId': null,
            'isDeleted': false,
          },
        ],
      });

      expect(page.snapshotSequence, 25);
      expect(page.hasMore, isTrue);
      expect(page.nextBeforeSequence, 10);
      expect(page.items.single.content, 'Page item');
    });

    test('parses sync items with conversation ID inherited from response', () {
      final sync = MebablChatMessageSyncPage.fromJson({
        'conversationId': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'requestedAfterEventSequence': 10,
        'latestEventSequence': 11,
        'nextAfterEventSequence': 11,
        'hasMore': false,
        'cursorAhead': false,
        'items': [
          {
            'id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
            'sequence': 5,
            'eventSequence': 11,
            'senderId': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
            'clientMessageId': null,
            'content': 'Hello',
            'messageType': 'text',
            'isEdited': false,
            'isDeleted': false,
            'createdAt': '2026-11-23T10:00:00Z',
            'updatedAt': null,
            'deletedAt': null,
          },
        ],
      });

      expect(sync.nextEventSequence, 11);
      expect(
        sync.messages.single.conversationId,
        'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      );
      expect(sync.messages.single.sequence, 5);
    });

    test('preserves deleted message tombstones in sync responses', () {
      final sync = MebablChatMessageSyncPage.fromJson({
        'conversationId': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'nextAfterEventSequence': 12,
        'items': [
          {
            'id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
            'sequence': 5,
            'eventSequence': 12,
            'senderId': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
            'content': '',
            'messageType': 'text',
            'isEdited': false,
            'isDeleted': true,
            'createdAt': '2026-11-23T10:00:00Z',
          },
        ],
      });

      expect(sync.messages, isEmpty);
      expect(sync.deletedMessageIds, contains('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'));
      expect(sync.nextEventSequence, 12);
    });

    test('encodes a shared post as a schema-versioned Chat message', () {
      const payload = MebablChatPostSharePayload(
        postId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      );
      expect(payload.toJson(), {
        'schemaVersion': 1,
        'postId': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      });
      expect(
        MebablChatPostSharePayload.tryParseContent(
          '{"schemaVersion":1,"postId":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"}',
        )?.postId,
        'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      );
    });

    test('parses explicit and inferred message read receipts', () {
      final read = MebablChatMessageRead.fromJson({
        'id': null,
        'messageId': 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        'userId': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        'readAt': '2026-11-23T11:00:00Z',
        'isInferredFromConversationCursor': true,
      });

      expect(read.id, isNull);
      expect(read.readAtUtc.isUtc, isTrue);
      expect(read.isInferredFromConversationCursor, isTrue);
    });

    test('parses inbox participant summaries and latest message previews', () {
      final conversation = MebablChatConversation.fromJson({
        'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'title': null,
        'isGroup': false,
        'createdAt': '2026-11-23T10:00:00Z',
        'participantIds': [
          'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
          'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        ],
        'participants': [
          {
            'userId': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
            'username': 'sam',
            'displayName': 'Sam',
            'avatarUrl': 'https://cdn.example.test/sam.jpg',
            'isAdmin': true,
          },
          {
            'userId': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
            'username': 'lee',
            'displayName': 'Lee',
            'avatarUrl': null,
            'isAdmin': false,
          },
        ],
        'lastMessageAtUtc': '2026-11-23T11:00:00Z',
        'lastMessage': {
          'id': 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
          'conversationId': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
          'senderId': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
          'content': 'See you soon',
          'messageType': 'text',
          'sequence': 9,
          'createdAt': '2026-11-23T11:00:00Z',
        },
      });

      expect(conversation.participants.first.displayName, 'Sam');
      expect(conversation.participants.first.role, 'admin');
      expect(conversation.lastMessage?.content, 'See you soon');
      expect(conversation.lastMessageAtUtc, isNotNull);
    });
  });

  group('RealtimeHub contract', () {
    test('parses named SignalR events with direct backend payloads', () {
      final event = MebablChatRealtimeEvent.fromSignalRArguments(
        [
          {
            'id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
            'conversationId': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
            'sequence': 10,
            'lastEventSequence': 12,
          },
        ],
        eventName: 'messageDeleted',
      );

      expect(event.eventName, 'messageDeleted');
      expect(event.conversationId, 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
      expect(event.data['id'], 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');
    });
  });
}
