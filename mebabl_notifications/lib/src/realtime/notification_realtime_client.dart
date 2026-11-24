import 'dart:async';

import 'package:mebabl_core/mebabl_core.dart';
import 'package:signalr_netcore/signalr_client.dart';

import 'notification_realtime_event.dart';

/// SignalR stream for in-app notification events.
///
/// Configure [eventName] to match the server's client event method name.
/// User-specific group subscription can be enabled with [joinMethod] when the
/// deployed hub requires an explicit join call.
class MebablNotificationRealtimeClient {
  final MebablCore core;
  final Future<String?> Function() getAccessToken;
  final String hubPath;
  final String eventName;
  final String? joinMethod;
  final String? joinArgument;

  HubConnection? _connection;
  final StreamController<MebablNotificationRealtimeEvent> _events =
      StreamController<MebablNotificationRealtimeEvent>.broadcast();
  final StreamController<Object> _errors = StreamController<Object>.broadcast();
  bool _disposed = false;

  MebablNotificationRealtimeClient({
    required this.core,
    required this.getAccessToken,
    this.hubPath = '/hubs/realtime',
    this.eventName = 'notificationReceived',
    this.joinMethod,
    this.joinArgument,
  });

  Stream<MebablNotificationRealtimeEvent> get events => _events.stream;
  Stream<Object> get errors => _errors.stream;
  bool get isConnected => _connection?.state == HubConnectionState.Connected;

  Future<void> connect() async {
    if (_disposed) throw StateError('Notification realtime client disposed.');
    if (isConnected) return;

    final token = await getAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw const MebablException(
        message: 'A signed-in user session is required for notifications realtime.',
        statusCode: 401,
      );
    }

    final parsed = Uri.tryParse(hubPath);
    final uri = parsed != null && parsed.hasScheme
        ? parsed
        : Uri.parse(core.config.baseUrl).resolve(hubPath);
    if (uri.scheme != 'https' && uri.scheme != 'http') {
      throw ArgumentError.value(hubPath, 'hubPath', 'Only HTTP(S) Hub URLs are supported.');
    }

    final connection = HubConnectionBuilder()
        .withUrl(
          uri.toString(),
          options: HttpConnectionOptions(
            accessTokenFactory: () async {
              final current = await getAccessToken();
              if (current == null || current.trim().isEmpty) {
                throw StateError('The user session is no longer available.');
              }
              return current;
            },
          ),
        )
        .withAutomaticReconnect(retryDelays: [2000, 5000, 10000, 20000, 30000])
        .build();

    connection.on(eventName, _handleEvent);
    connection.onreconnected(({String? connectionId}) async {
      await _joinIfRequired(connection);
    });
    connection.onclose(({Exception? error}) {
      if (error != null && !_errors.isClosed) _errors.add(error);
    });

    _connection = connection;
    await connection.start();
    await _joinIfRequired(connection);
  }

  Future<Object?> invokeServerMethod(
    String methodName, {
    List<Object> arguments = const [],
  }) async {
    if (methodName.trim().isEmpty) {
      throw ArgumentError.value(methodName, 'methodName', 'A Hub method name is required.');
    }
    final connection = _connection;
    if (connection == null ||
        connection.state != HubConnectionState.Connected) {
      throw StateError('Notification realtime is not connected.');
    }
    return connection.invoke(methodName, args: arguments);
  }

  Future<void> disconnect() async {
    final connection = _connection;
    _connection = null;
    if (connection != null) await connection.stop();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await disconnect();
    await _events.close();
    await _errors.close();
  }

  void _handleEvent(List<Object?>? arguments) {
    if (_events.isClosed) return;
    try {
      _events.add(
        MebablNotificationRealtimeEvent.fromSignalRArguments(arguments),
      );
    } catch (error) {
      if (!_errors.isClosed) _errors.add(error);
    }
  }

  Future<void> _joinIfRequired(HubConnection connection) async {
    final method = joinMethod;
    final argument = joinArgument;
    if (method == null || method.trim().isEmpty) return;
    try {
      await connection.invoke(
        method,
        args: argument == null ? <Object>[] : <Object>[argument],
      );
    } catch (error) {
      if (!_errors.isClosed) _errors.add(error);
    }
  }
}
