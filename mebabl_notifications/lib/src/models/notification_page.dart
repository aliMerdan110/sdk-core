import 'json_helpers.dart';
import 'user_notification.dart';

class MebablNotificationPage {
  final List<MebablUserNotification> items;
  final bool hasMore;
  final String? nextCursor;
  final int? unreadCount;

  const MebablNotificationPage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
    this.unreadCount,
  });

  factory MebablNotificationPage.fromJson(Object? value) {
    final rawItems = readItems(value, 'notifications');
    if (value is List) {
      return MebablNotificationPage(
        items: rawItems.map(MebablUserNotification.fromJson).toList(growable: false),
        hasMore: false,
      );
    }
    final json = asJsonMap(value, 'notification page');
    return MebablNotificationPage(
      items: rawItems.map(MebablUserNotification.fromJson).toList(growable: false),
      hasMore: json['hasMore'] == true,
      nextCursor: json['nextCursor'] is String ? json['nextCursor'] as String : null,
      unreadCount: json['unreadCount'] == null ? null : intValue(json['unreadCount']),
    );
  }
}
