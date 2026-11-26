import 'dart:convert';

import 'json_helpers.dart';

String _notificationId(Map<String, dynamic> json) {
  final value = json['id'] ?? json['notificationId'];
  if (value is String && value.trim().isNotEmpty) return value;
  throw const FormatException('Expected a notification id.');
}

class MebablUserNotification {
  final String id;
  final String type;
  final String? title;
  final String? message;
  final String? actorUserId;
  final String? targetType;
  final String? targetId;
  final String? deepLink;
  final String? sourceEventId;
  final Map<String, dynamic> payload;
  final bool isRead;
  final DateTime? readAtUtc;
  final DateTime? archivedAtUtc;
  final DateTime createdAtUtc;
  final String priority;
  final int aggregatedCount;
  final String category;
  final String? locale;

  const MebablUserNotification({
    required this.id,
    required this.type,
    this.title,
    this.message,
    this.actorUserId,
    this.targetType,
    this.targetId,
    this.deepLink,
    this.sourceEventId,
    this.payload = const {},
    this.isRead = false,
    this.readAtUtc,
    this.archivedAtUtc,
    required this.createdAtUtc,
    this.priority = 'normal',
    this.aggregatedCount = 1,
    this.category = 'general',
    this.locale,
  });

  factory MebablUserNotification.fromJson(Map<String, dynamic> json) {
    final rawPayload = json['payload'] ?? json['data'];
    Map<String, dynamic> payload = const {};
    if (rawPayload is Map) {
      payload = Map<String, dynamic>.from(rawPayload);
    } else if (rawPayload is String && rawPayload.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawPayload);
        if (decoded is Map) payload = Map<String, dynamic>.from(decoded);
      } on FormatException {
        // Older notification rows may contain plain text in Data.
      }
    }
    return MebablUserNotification(
      id: _notificationId(json),
      type: (json['type'] ?? json['notificationType']) is String
          ? (json['type'] ?? json['notificationType']) as String
          : (throw const FormatException('Expected a notification type.')),
      title: optionalString(json, 'title') ?? optionalString(payload, 'title'),
      message: optionalString(json, 'message') ??
          optionalString(json, 'body') ?? optionalString(payload, 'message'),
      actorUserId: optionalString(json, 'actorUserId') ??
          optionalString(json, 'actorId') ?? optionalString(payload, 'actorUserId'),
      targetType: optionalString(json, 'targetType') ?? optionalString(payload, 'targetType'),
      targetId: optionalString(json, 'targetId') ?? optionalString(payload, 'targetId'),
      deepLink: optionalString(json, 'deepLink') ?? optionalString(payload, 'deepLink'),
      sourceEventId: optionalString(json, 'sourceEventId') ??
          optionalString(payload, 'sourceEventId'),
      payload: payload,
      isRead: json['isRead'] == true,
      readAtUtc: optionalDateTime(json['readAtUtc'] ?? json['readAt']),
      archivedAtUtc: optionalDateTime(json['archivedAtUtc'] ?? json['archivedAt']),
      createdAtUtc: optionalDateTime(json['createdAtUtc'] ?? json['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      priority: optionalString(json, 'priority') ?? 'normal',
      aggregatedCount: intValue(json['aggregatedCount'], fallback: 1),
      category: optionalString(json, 'category') ?? 'general',
      locale: optionalString(json, 'locale'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'message': message,
        'actorUserId': actorUserId,
        'targetType': targetType,
        'targetId': targetId,
        'deepLink': deepLink,
        'sourceEventId': sourceEventId,
        'payload': payload,
        'isRead': isRead,
        'readAtUtc': readAtUtc?.toIso8601String(),
        'archivedAtUtc': archivedAtUtc?.toIso8601String(),
        'createdAtUtc': createdAtUtc.toIso8601String(),
        'priority': priority,
        'aggregatedCount': aggregatedCount,
        'category': category,
        'locale': locale,
      };
}
