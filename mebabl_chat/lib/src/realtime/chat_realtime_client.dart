import 'dart:async';

import 'package:mebabl_core/mebabl_core.dart';
import 'package:signalr_netcore/signalr_client.dart';

import 'chat_realtime_event.dart';

/// Authenticated SignalR connection for the current RealtimeHub contract.
class MebablChatRealtimeClient {
  static const List<String> defaultEventNames = [
    'messageReceived',
    'messageUpdated',
    'messageDeleted',
    'messageRead',
    'reactionAdded',
    'reactionRemoved',
    'conversationDelivered',
    'conversationRead',
    'conversationUpdated',
    'attachmentAdded',
    'attachmentRemoved',
    'participantAdded',
    'participantRemoved',
    'participantLeft',
    'participantRoleChanged',
    'userTyping',
    'userStoppedTyping',
    'userOnline',
    'userOffline',
    // Calls share RealtimeHub with chat and presence. Keeping these in the
    // default subscription lets one authenticated connection serve both SDKs.
    'incomingCall',
    'callParticipantJoined',
    'callInvitationExpired',
    'callParticipantDeclined',
    'callEnded',
    'callSignal',
    'callParticipantLeft',
    'callMediaStateChanged',
  ];

  final MebablCore core;
  final Future<String?> Function() getAccessToken;
  final String hubPath;
  final String joinMethod;
  final String leaveMethod;
  final List<String> eventNames;

  HubConnection? _connection;
  late final StreamController<MebablChatRealtimeEvent> _events =
      StreamController<MebablChatRealtimeEvent>.broadcast();
  late final StreamController<Object> _errors =
      StreamController<Object>.broadcast();
  final Set<String> _joinedConversations = <String>{};
  Future<void>? _connecting;
  bool _disposed = false;

  MebablChatRealtimeClient({
    required this.core,
    required this.getAccessToken,
    this.hubPath = '/hubs/realtime',
    String? eventName,
    List<String> eventNames = defaultEventNames,
    this.joinMethod = 'JoinConversation',
    this.leaveMethod = 'LeaveConversation',
  }) : eventNames = List.unmodifiable({
          if (eventName != null && eventName.trim().isNotEmpty) eventName.trim(),
          ...eventNames.map((value) => value.trim()).where((value) => value.isNotEmpty),
          // Always subscribe to call events because chat and calls share this
          // authenticated RealtimeHub connection.
          'incomingCall',
          'callParticipantJoined',
          'callInvitationExpired',
          'callParticipantDeclined',
          'callEnded',
          'callSignal',
          'callParticipantLeft',
          'callMediaStateChanged',
        });

  Stream<MebablChatRealtimeEvent> get events => _events.stream;
  Stream<Object> get errors => _errors.stream;
  bool get isConnected => _connection?.state == HubConnectionState.Connected;
  Set<String> get joinedConversations => Set.unmodifiable(_joinedConversations);

  Future<void> connect() async {
    _ensureNotDisposed();
    if (isConnected) return;
    final pending = _connecting;
    if (pending != null) return pending;

    final future = _connectInternal();
    _connecting = future;
    try {
      await future;
    } finally {
      if (identical(_connecting, future)) _connecting = null;
    }
  }

  Future<void> _connectInternal() async {
    final token = await getAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw const MebablException(
        message: 'A signed-in user session is required for Chat realtime.',
        statusCode: 401,
      );
    }

    final options = HttpConnectionOptions(
      accessTokenFactory: () async {
        final current = await getAccessToken();
        if (current == null || current.trim().isEmpty) {
          throw StateError('The user session is no longer available.');
        }
        return current;
      },
    );

    final connection = HubConnectionBuilder()
        .withUrl(_resolveHubUri().toString(), options: options)
        .withAutomaticReconnect(retryDelays: [2000, 5000, 10000, 20000, 30000])
        .build();

    for (final name in eventNames) {
      connection.on(name, (args) => _handleEvent(name, args));
    }
    connection.onreconnected(({String? connectionId}) async {
      await _rejoinConversations(connection);
      _emitLocalEvent('connectionReconnected');
    });
    connection.onclose(({Exception? error}) {
      if (error != null && !_errors.isClosed) _errors.add(error);
    });

    _connection = connection;
    await connection.start();
    await _rejoinConversations(connection);
  }

  Future<void> joinConversation(String conversationId) async {
    _validateGuid(conversationId, 'conversationId');
    if (_joinedConversations.contains(conversationId)) return;
    final connection = _requireConnected();
    await connection.invoke(joinMethod, args: <Object>[conversationId]);
    _joinedConversations.add(conversationId);
  }

  Future<Object?> invokeServerMethod(
    String methodName, {
    List<Object> arguments = const [],
  }) async {
    if (methodName.trim().isEmpty) {
      throw ArgumentError.value(methodName, 'methodName', 'A Hub method name is required.');
    }
    return _requireConnected().invoke(methodName, args: arguments);
  }

  Future<void> startTyping(String conversationId) async {
    _validateGuid(conversationId, 'conversationId');
    await invokeServerMethod('StartTyping', arguments: [conversationId]);
  }

  Future<void> stopTyping(String conversationId) async {
    _validateGuid(conversationId, 'conversationId');
    await invokeServerMethod('StopTyping', arguments: [conversationId]);
  }

  Future<void> leaveConversation(String conversationId) async {
    _validateGuid(conversationId, 'conversationId');
    if (!_joinedConversations.contains(conversationId)) return;
    final connection = _requireConnected();
    await connection.invoke(leaveMethod, args: <Object>[conversationId]);
    _joinedConversations.remove(conversationId);
  }

  Future<void> disconnect() async {
    final connection = _connection;
    _connection = null;
    _joinedConversations.clear();
    if (connection != null) await connection.stop();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await disconnect();
    await _events.close();
    await _errors.close();
  }

  void _emitLocalEvent(String eventName) {
    if (_events.isClosed) return;
    _events.add(
      MebablChatRealtimeEvent(
        eventName: eventName,
        eventId: '',
        data: const <String, dynamic>{},
      ),
    );
  }

  void _handleEvent(String eventName, List<Object?>? arguments) {
    if (_events.isClosed) return;
    try {
      _events.add(
        MebablChatRealtimeEvent.fromSignalRArguments(
          arguments,
          eventName: eventName,
        ),
      );
    } catch (error) {
      if (!_errors.isClosed) _errors.add(error);
    }
  }

  Future<void> _rejoinConversations(HubConnection connection) async {
    for (final id in _joinedConversations.toList(growable: false)) {
      try {
        await connection.invoke(joinMethod, args: <Object>[id]);
      } catch (error) {
        if (!_errors.isClosed) _errors.add(error);
      }
    }
  }

  HubConnection _requireConnected() {
    final connection = _connection;
    if (connection == null || connection.state != HubConnectionState.Connected) {
      throw StateError('Chat realtime is not connected. Call connect() first.');
    }
    return connection;
  }

  Uri _resolveHubUri() {
    final configured = Uri.tryParse(hubPath);
    if (configured != null && configured.hasScheme) {
      if (configured.scheme != 'https' && configured.scheme != 'http') {
        throw ArgumentError.value(hubPath, 'hubPath', 'Only HTTP(S) is supported.');
      }
      return configured;
    }
    return Uri.parse(core.config.baseUrl).resolve(hubPath);
  }

  void _validateGuid(String value, String name) {
    if (!RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value.trim())) {
      throw ArgumentError.value(value, name, 'A valid GUID is required.');
    }
  }

  void _ensureNotDisposed() {
    if (_disposed) throw StateError('Chat realtime client has been disposed.');
  }
}
