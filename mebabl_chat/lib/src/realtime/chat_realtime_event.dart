import 'dart:convert';

import '../models/json_helpers.dart';

/// One named SignalR event published by the backend's Outbox dispatcher.
///
/// The backend sends event names separately (for example `messageReceived`)
/// and the payload is the event data itself, not a generic event envelope.
class MebablChatRealtimeEvent {
  final String eventName;
  final String eventId;
  final String? conversationId;
  final int? sequence;
  final DateTime? occurredAtUtc;
  final Map<String, dynamic> data;

  const MebablChatRealtimeEvent({
    required this.eventName,
    required this.eventId,
    this.conversationId,
    this.sequence,
    this.occurredAtUtc,
    this.data = const {},
  });

  /// Backward-compatible aliases for the earlier generic-event contract.
  String get eventType => eventName;
  String? get aggregateId => conversationId;

  factory MebablChatRealtimeEvent.fromSignalRArguments(
    List<Object?>? args, {
    String eventName = 'unknown',
  }) {
    if (args == null || args.isEmpty) {
      throw const FormatException('The SignalR event payload is empty.');
    }
    final raw = args.first;
    final decoded = raw is String ? jsonDecode(raw) : raw;
    final json = asJsonMap(decoded, 'chat realtime event');
    final nestedData = json['data'];
    final data = nestedData is Map
        ? Map<String, dynamic>.from(nestedData)
        : Map<String, dynamic>.from(json);

    return MebablChatRealtimeEvent(
      eventName: optionalString(json, 'eventType') ?? eventName,
      eventId: optionalString(json, 'eventId') ?? '',
      conversationId: optionalString(json, 'conversationId') ??
          optionalString(data, 'conversationId'),
      sequence: json['sequence'] == null && data['sequence'] == null
          ? null
          : intValue(json['sequence'] ?? data['sequence']),
      occurredAtUtc: optionalDateTime(
        json['occurredAtUtc'] ?? json['occurredAt'] ?? data['occurredAt'],
      ),
      data: data,
    );
  }
}
