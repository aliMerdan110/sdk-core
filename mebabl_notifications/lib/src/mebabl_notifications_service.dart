import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mebabl_core/mebabl_core.dart';

import 'models/device_installation.dart';
import 'models/json_helpers.dart';
import 'models/notification_page.dart';
import 'models/notification_preferences.dart';

/// User-scoped Notifications API and Firebase Cloud Messaging bridge.
///
/// Firebase itself must be initialized by the host application before calling
/// the FCM convenience methods. The backend stores only the device token and
/// installation metadata; Firebase service-account credentials never belong
/// in this client package.
class MebablNotificationsService {
  static const String defaultBasePath = '/api/sdk/notifications';
  static const int maximumPageSize = 100;

  final MebablCore core;
  final String basePath;
  final FirebaseMessaging? messaging;

  MebablNotificationsService({
    required this.core,
    this.basePath = defaultBasePath,
    this.messaging,
  }) {
    if (basePath.trim().isEmpty || !basePath.startsWith('/')) {
      throw ArgumentError.value(
        basePath,
        'basePath',
        'basePath must be a non-empty absolute API path.',
      );
    }
  }

  Future<MebablNotificationPage> getNotifications({
    int offset = 0,
    int limit = 30,
    CancelToken? cancelToken,
  }) async {
    if (offset < 0) {
      throw ArgumentError.value(offset, 'offset', 'Offset cannot be negative.');
    }
    if (limit < 1 || limit > maximumPageSize) {
      throw ArgumentError.value(limit, 'limit', 'Limit must be between 1 and $maximumPageSize.');
    }
    final response = await core.http.get<Object>(
      basePath,
      queryParameters: {'offset': offset, 'limit': limit},
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
    return MebablNotificationPage.fromJson(response.data);
  }

  Future<int> getUnreadCount({CancelToken? cancelToken}) async {
    final response = await core.http.get<Object>(
      '$basePath/unread-count',
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
    final data = response.data;
    if (data is num) return data.toInt();
    final json = asJsonMap(data, 'unread count');
    final value = json['unreadCount'] ?? json['count'];
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    throw const FormatException('The unread-count response is invalid.');
  }

  Future<void> markAsRead({
    required String notificationId,
    CancelToken? cancelToken,
  }) async {
    final id = _requireId(notificationId, 'notificationId');
    await core.http.patch<void>(
      '$basePath/$id/read',
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
  }

  Future<void> markAllAsRead({CancelToken? cancelToken}) async {
    await core.http.post<void>(
      '$basePath/read-all',
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
  }


  Future<void> delete({
    required String notificationId,
    CancelToken? cancelToken,
  }) async {
    final id = _requireId(notificationId, 'notificationId');
    await core.http.delete<void>(
      '$basePath/$id',
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
  }

  Future<MebablNotificationPreferences> getPreferences({
    CancelToken? cancelToken,
  }) async {
    final response = await core.http.get<Object>(
      '$basePath/preferences',
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
    return MebablNotificationPreferences.fromJson(response.data);
  }

  Future<MebablNotificationPreferences> updatePreferences({
    required MebablNotificationPreferences preferences,
    CancelToken? cancelToken,
  }) async {
    final response = await core.http.put<Object>(
      '$basePath/preferences',
      data: preferences.toJson(),
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
    return MebablNotificationPreferences.fromJson(response.data);
  }

  /// Registers a push token already obtained by the application.
  ///
  /// [installationId] must be a stable, app-generated identifier for this
  /// installation. Do not use the FCM token as the installation ID because
  /// FCM tokens can rotate.
  /// Returns a stable, per-application installation identifier.
  ///
  /// The identifier is generated once and kept in secure storage. It is not
  /// the FCM token and must not be regenerated when FCM rotates that token.
  Future<String> getOrCreateInstallationId({
    FlutterSecureStorage? secureStorage,
  }) async {
    final storage = secureStorage ?? const FlutterSecureStorage();
    final key = 'mebabl.notification.installation.${core.config.applicationId}';
    final existing = await storage.read(key: key);
    if (existing != null && existing.trim().isNotEmpty) return existing;

    final created = _createGuid();
    await storage.write(key: key, value: created);
    final verified = await storage.read(key: key);
    if (verified == null || verified.isEmpty) {
      throw StateError('Could not persist the notification installation ID.');
    }
    return verified;
  }

  Future<MebablDeviceInstallation> registerDevice({
    required String installationId,
    required String token,
    required String platform,
    String provider = 'fcm',
    String? locale,
    CancelToken? cancelToken,
  }) async {
    final installation = installationId.trim();
    final pushToken = token.trim();
    final normalizedPlatform = platform.trim().toLowerCase();
    if (installation.isEmpty || installation.length > 128) {
      throw ArgumentError.value(
        installationId,
        'installationId',
        'Installation ID must contain 1 to 128 characters.',
      );
    }
    if (pushToken.isEmpty || pushToken.length > 8192) {
      throw ArgumentError.value(token, 'token', 'Push token is empty or too long.');
    }
    if (!const {'android', 'ios', 'web', 'macos', 'windows', 'linux'}
        .contains(normalizedPlatform)) {
      throw ArgumentError.value(platform, 'platform', 'Unsupported device platform.');
    }
    final response = await core.http.post<Object>(
      '$basePath/devices',
      data: {
        'installationId': installation,
        'platform': normalizedPlatform,
        'provider': provider.trim().isEmpty ? 'fcm' : provider.trim(),
        'token': pushToken,
        if (locale != null && locale.trim().isNotEmpty) 'locale': locale.trim(),
      },
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
    return MebablDeviceInstallation.fromJson(
      _unwrapObject(response.data, const ['device', 'installation', 'data']),
    );
  }

  Future<void> unregisterDevice({
    required String deviceId,
    CancelToken? cancelToken,
  }) async {
    final id = _requireId(deviceId, 'deviceId');
    await core.http.delete<void>(
      '$basePath/devices/$id',
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
  }

  /// Requests OS permission, obtains the current FCM token and registers it.
  ///
  /// The host app must call `Firebase.initializeApp()` first and provide the
  /// matching `GoogleService-Info.plist` / `google-services.json`.
  Future<MebablDeviceInstallation> registerCurrentFirebaseDevice({
    required String installationId,
    String? locale,
    String? webVapidKey,
    bool requestPermission = true,
    CancelToken? cancelToken,
  }) async {
    final firebase = _requireMessaging();
    if (requestPermission) {
      final settings = await firebase.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        throw const MebablException(
          message: 'Push notification permission was denied by the user.',
          code: 'pushPermissionDenied',
        );
      }
    }

    final token = await firebase.getToken(
      vapidKey: kIsWeb ? webVapidKey : null,
    );
    if (token == null || token.trim().isEmpty) {
      throw const MebablException(
        message: 'Firebase Messaging did not return a device token.',
        code: 'pushTokenUnavailable',
      );
    }

    return registerDevice(
      installationId: installationId,
      token: token,
      platform: _currentPlatform,
      provider: 'fcm',
      locale: locale,
      cancelToken: cancelToken,
    );
  }

  /// Registers every refreshed FCM token. Keep the returned subscription and
  /// cancel it when the authenticated session is signed out or the app scope
  /// is disposed. Errors are forwarded to [onError].
  StreamSubscription<String> listenForFirebaseTokenRefresh({
    required String installationId,
    String? locale,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    final firebase = _requireMessaging();
    return firebase.onTokenRefresh.listen(
      (token) async {
        try {
          await registerDevice(
            installationId: installationId,
            token: token,
            platform: _currentPlatform,
            provider: 'fcm',
            locale: locale,
          );
        } catch (error, stackTrace) {
          onError?.call(error, stackTrace);
        }
      },
      onError: onError,
    );
  }

  /// Messages received while the app is foregrounded. The host app decides
  /// whether to show a local notification or update its UI.
  Stream<RemoteMessage> get onForegroundMessage {
    return FirebaseMessaging.onMessage;
  }

  /// Messages opened by tapping a notification while the app was backgrounded.
  Stream<RemoteMessage> get onMessageOpenedApp {
    return FirebaseMessaging.onMessageOpenedApp;
  }

  Future<RemoteMessage?> getInitialMessage() {
    return _requireMessaging().getInitialMessage();
  }

  FirebaseMessaging _requireMessaging() {
    final current = messaging ?? FirebaseMessaging.instance;
    return current;
  }

  String get _currentPlatform {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'android',
    };
  }

  String _createGuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }


  String _requireId(String value, String name) {
    final normalized = value.trim();
    if (!RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(normalized)) {
      throw ArgumentError.value(value, name, 'A valid GUID identifier is required.');
    }
    return normalized;
  }

  Map<String, dynamic> _unwrapObject(Object? value, List<String> keys) {
    var current = asJsonMap(value, 'response');
    for (final key in keys) {
      final nested = current[key];
      if (nested is Map) {
        current = Map<String, dynamic>.from(nested);
        break;
      }
    }
    return current;
  }
}
