import 'package:flutter_test/flutter_test.dart';
import 'package:mebabl_notifications/mebabl_notifications.dart';

void main() {
  test('parses a notification and deep-link target', () {
    final notification = MebablUserNotification.fromJson({
      'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'type': 'social.post.reaction',
      'title': 'New reaction',
      'message': 'Someone reacted to your post',
      'targetType': 'post',
      'targetId': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      'deepLink': '/posts/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      'isRead': false,
      'createdAtUtc': '2026-11-23T10:00:00Z',
    });

    expect(notification.type, 'social.post.reaction');
    expect(notification.isRead, isFalse);
    expect(notification.targetType, 'post');
    expect(notification.createdAtUtc.isUtc, isTrue);
  });

  test('preserves server preference fields unknown to this SDK version', () {
    final preferences = MebablNotificationPreferences.fromJson([
      {
        'category': 'social',
        'pushEnabled': true,
        'mutedUntilUtc': null,
        'isCustomized': false,
      },
    ]);

    expect(preferences.categories.single.category, 'social');
    expect(preferences.categories.single.pushEnabled, isTrue);
    expect(preferences.toJson()['preferences'], hasLength(1));
  });

  test('parses unread count response through model helpers', () {
    final page = MebablNotificationPage.fromJson({
      'items': [],
      'hasMore': false,
      'unreadCount': 4,
    });

    expect(page.items, isEmpty);
    expect(page.unreadCount, 4);
  });
}
