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
      'priority': 'high',
      'aggregatedCount': 4,
      'category': 'social',
      'locale': 'ar-IQ',
    });

    expect(notification.type, 'social.post.reaction');
    expect(notification.isRead, isFalse);
    expect(notification.targetType, 'post');
    expect(notification.createdAtUtc.isUtc, isTrue);
    expect(notification.priority, 'high');
    expect(notification.aggregatedCount, 4);
    expect(notification.category, 'social');
    expect(notification.locale, 'ar-IQ');
  });

  test('preserves server preference fields unknown to this SDK version', () {
    final preferences = MebablNotificationPreferences.fromJson({
      'pushEnabled': true,
      'inAppEnabled': true,
      'mutedTypes': ['chat.message'],
      'quietHours': {'from': '22:00', 'to': '08:00'},
    });

    expect(preferences.pushEnabled, isTrue);
    expect(preferences.mutedTypes, contains('chat.message'));
    expect(preferences.toJson()['quietHours'], isNotNull);
  });

  test('parses the backend device installation projection', () {
    final device = MebablDeviceInstallation.fromJson({
      'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'installationId': 'installation-01',
      'platform': 'android',
      'provider': 'fcm',
      'locale': 'ar-IQ',
      'appVersion': '1.5.0',
      'lastRegisteredAtUtc': '2026-11-23T10:00:00Z',
      'lastSeenAtUtc': '2026-11-23T11:00:00Z',
    });

    expect(device.provider, 'fcm');
    expect(device.appVersion, '1.5.0');
    expect(device.lastRegisteredAtUtc?.isUtc, isTrue);
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
