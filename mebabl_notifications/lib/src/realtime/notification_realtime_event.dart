import 'dart:convert';

import '../models/json_helpers.dart';

class MebablNotificationRealtimeEvent {
  final String eventType;
  final String? notificationId;
  final String? eventId;
  final Map<String, dynamic> data;

  const MebablNotificationRealtimeEvent({
    required this.eventType,
    this.notificationId,
    this.eventId,
    this.data = const {},
  });

  factory MebablNotificationRealtimeEvent.fromSignalRArguments(
    List<Object?>? arguments,
  ) {
    if (arguments == null || arguments.isEmpty) {
      throw const FormatException('The SignalR notification payload is empty.');
    }
    final raw = arguments.first;
    final decoded = raw is String ? jsonDecode(raw) : raw;
    final json = asJsonMap(decoded, 'notification realtime event');
    final rawData = json['data'];
    final payload = rawData is Map ? Map<String, dynamic>.from(rawData) : json;
    return MebablNotificationRealtimeEvent(
      eventType: optionalString(json, 'eventType') ??
          optionalString(json, 'type') ??
          'notification.created',
      notificationId: optionalString(json, 'notificationId') ??
          optionalString(payload, 'notificationId'),
      eventId: optionalString(json, 'eventId'),
      data: payload,
    );
  }
}
