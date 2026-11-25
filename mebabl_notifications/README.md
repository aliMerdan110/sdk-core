# mebabl_notifications

Typed Flutter SDK for the Mebabl in-app notification inbox, device registration,
user notification preferences, Firebase Cloud Messaging token lifecycle, and
realtime notification events.

## Requirements

- Dart `>=3.8.1`
- Flutter `>=3.32.0`
- `mebabl_core ^1.2.0`
- Firebase native project configuration (`google-services.json` / `GoogleService-Info.plist`) for Android/iOS; web requires explicit FirebaseOptions.

## Install in the Mebabl SDK workspace

```yaml
dependencies:
  mebabl_core:
    path: ../mebabl_core
  mebabl_auth:
    path: ../mebabl_auth
  mebabl_notifications:
    path: ../mebabl_notifications
```

## Initialize

```dart
final core = await MebablCore.initialize();
final auth = MebablAuthService(core: core);
await auth.initialize();

final notifications = MebablNotificationsService(core: core);
```

## In-app inbox

```dart
final page = await notifications.getNotifications(offset: 0, limit: 30);
final unreadCount = await notifications.getUnreadCount();

if (page.items.isNotEmpty) {
  await notifications.markAsRead(
    notificationId: page.items.first.id,
  );
}
```

## Register an FCM device

The SDK initializes the default Firebase app on first FCM registration when no
Messaging instance is injected. The platform configuration must still be present:
`google-services.json` / `GoogleService-Info.plist`; web requires FirebaseOptions.
The installation ID and the returned server device-registration ID are persisted
securely by the SDK. The app can read the device ID with
`getRegisteredDeviceId()` on restart and revoke it before logout. The installation
ID remains stable when an FCM registration token rotates.

```dart
final installationId =
    await notifications.getOrCreateInstallationId();

final device = await notifications.registerCurrentFirebaseDevice(
  installationId: installationId,
  locale: 'ar-IQ',
);

// Keep this subscription while the user is signed in.
final tokenRefreshSubscription =
    notifications.listenForFirebaseTokenRefresh(
  installationId: installationId,
  locale: 'ar-IQ',
  onError: (error, stackTrace) {
    // Log without including the token.
  },
);
```

Cancel the token refresh subscription on sign-out or when the authenticated
app scope is disposed. The backend derives the user identity from the User JWT;
the SDK never accepts a caller-supplied user ID for device registration.

## Handle push messages

```dart
notifications.onForegroundMessage.listen((remoteMessage) {
  // Update inbox state or show a local notification.
});

notifications.onMessageOpenedApp.listen((remoteMessage) {
  // Parse remoteMessage.data and navigate to a validated target.
});

final initial = await notifications.getInitialMessage();
```

Do not trust a deep link or target ID from a push payload by itself. Fetch the
target from the authenticated API before showing private content. Foreground
system notification presentation is the host app's responsibility.

## Preferences

```dart
final current = await notifications.getPreferences();

final updated = await notifications.updatePreferences(
  preferences: MebablNotificationPreferences(
    inAppEnabled: current.inAppEnabled ?? true,
    pushEnabled: true,
    emailEnabled: current.emailEnabled,
    mutedTypes: current.mutedTypes,
    additionalSettings: current.additionalSettings,
  ),
);
```

Unknown preference fields are preserved by `additionalSettings`.

## Realtime events

```dart
final realtime = MebablNotificationRealtimeClient(
  core: core,
  getAccessToken: auth.getValidAccessToken,
  hubPath: '/hubs/realtime',
  eventName: 'notificationReceived',
);

realtime.events.listen((event) {
  // Treat the event as a signal to refresh the server inbox.
});

await realtime.connect();
```

Hub path, event method name, and optional user-group join method are
configurable. Defaults must match the deployed SignalR Hub. Refresh the
notification inbox after reconnect; realtime is not a durable delivery queue.

## Backend contract used by this package

Base path: `/api/sdk/notifications`

- `GET /` — notification inbox.
- `GET /unread-count` — unread count.
- `PATCH /{notificationId}/read` — mark one as read.
- `POST /read-all` — mark all as read.
- `DELETE /{notificationId}` — delete/hide one notification.
- `GET /preferences` and `PUT /preferences` — user preferences.
- `POST /devices` — register/update this installation.
- `DELETE /devices/{deviceId}` — unregister a device.

Push messages are a delivery channel, not the source of truth. The durable
notification inbox is read from the Mebabl API. Never put Firebase service
account JSON or private server credentials into a Flutter app.

## Version 1.0.2

- Persist and expose the registered device ID for app restart/logout handling.
- Clear the stored ID after successful revocation.
- Restrict Firebase device registration to Android, iOS and web.

## Version 1.0.1

- Align inbox pagination with the deployed `offset` / `limit` API.
- Parse array-based inbox and category preference responses.
- Serialize concurrent SignalR connects and clean up a failed connection attempt.
- Initialize the default Firebase app on first device registration when platform configuration is available.
