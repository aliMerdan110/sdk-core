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
  final String? userId;
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

  const MebablUserNotification({
    required this.id,
    required this.type,
    this.title,
    this.message,
    this.userId,
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
  });

  factory MebablUserNotification.fromJson(Map<String, dynamic> json) {
    final rawPayload = json['payload'] ?? json['data'];
    final parsedPayload = _notificationPayload(rawPayload);
    return MebablUserNotification(
      id: _notificationId(json),
      type: (json['type'] ?? json['notificationType']) is String
          ? (json['type'] ?? json['notificationType']) as String
          : (throw const FormatException('Expected a notification type.')),
      userId: optionalString(json, 'userId'),
      title: optionalString(json, 'title'),
      message: optionalString(json, 'message') ?? optionalString(json, 'body'),
      actorUserId: optionalString(json, 'actorUserId') ?? optionalString(json, 'actorId'),
      targetType: optionalString(json, 'targetType'),
      targetId: optionalString(json, 'targetId'),
      deepLink: optionalString(json, 'deepLink'),
      sourceEventId: optionalString(json, 'sourceEventId'),
      payload: parsedPayload,
      isRead: json['isRead'] == true,
      readAtUtc: optionalDateTime(json['readAtUtc'] ?? json['readAt']),
      archivedAtUtc: optionalDateTime(json['archivedAtUtc'] ?? json['archivedAt']),
      createdAtUtc: optionalDateTime(json['createdAtUtc'] ?? json['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'userId': userId,
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
      };
}

Map<String, dynamic> _notificationPayload(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is String && value.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return {'raw': value};
    }
  }
  return const {};
}
