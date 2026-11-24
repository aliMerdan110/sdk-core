# mebabl_notifications

Typed Flutter SDK for the Babilo in-app notification inbox, category preferences, device registration, Firebase Cloud Messaging token lifecycle, and realtime notification events.

## Requirements

- Dart `>=3.8.1`
- Flutter `>=3.32.0`
- `mebabl_core ^1.2.0`
- Firebase initialized by the host application before FCM methods are used.

## Install in the SDK workspace

```yaml
dependencies:
  mebabl_core:
    path: ../mebabl_core
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

The current backend returns a plain array and uses offset/limit pagination:

```dart
final firstPage = await notifications.getNotifications(
  offset: 0,
  limit: 30,
);
final olderPage = await notifications.getNotifications(
  offset: firstPage.items.length,
  limit: 30,
);
final unreadCount = await notifications.getUnreadCount();

if (firstPage.items.isNotEmpty && !firstPage.items.first.isRead) {
  await notifications.markAsRead(
    notificationId: firstPage.items.first.id,
  );
}

await notifications.markAllAsRead();
await notifications.delete(notificationId: firstPage.items.first.id);
```

## Category preferences

The backend returns all known categories as a list. `pushEnabled` controls push delivery; `mutedUntilUtc` is a category-level mute deadline.

```dart
final current = await notifications.getPreferences();
final updatedCategories = current.categories.map((item) {
  if (item.category != 'social') return item;
  return MebablNotificationPreference(
    category: item.category,
    pushEnabled: false,
    mutedUntilUtc: item.mutedUntilUtc,
    isCustomized: true,
  );
}).toList();

await notifications.updatePreferences(
  preferences: MebablNotificationPreferences(
    categories: updatedCategories,
  ),
);
```

Supported backend categories are `messaging`, `social`, `account`, `security`, `system`, `moderation`, and `general`.

## Register an FCM device

The app must initialize Firebase and provide its platform configuration before using this method. The installation ID is generated and persisted by the SDK; it must remain stable when an FCM registration token rotates.

```dart
await Firebase.initializeApp();

final installationId = await notifications.getOrCreateInstallationId();
final device = await notifications.registerCurrentFirebaseDevice(
  installationId: installationId,
  locale: 'ar-IQ',
);

final tokenRefreshSubscription = notifications.listenForFirebaseTokenRefresh(
  installationId: installationId,
  locale: 'ar-IQ',
);
```

Cancel the token refresh subscription on sign-out or when the authenticated app scope is disposed. The backend derives user identity from the User JWT; the SDK never accepts a caller-supplied user ID for device registration.

## Handle push messages

```dart
notifications.onForegroundMessage.listen((remoteMessage) {
  // Update inbox state or show a local notification.
});

notifications.onMessageOpenedApp.listen((remoteMessage) {
  // Fetch and validate the target before navigating to private content.
});

final initial = await notifications.getInitialMessage();
```

Foreground system notification presentation is the host application's responsibility.

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

Hub path, event method name, and optional user-group join method are configurable. Refresh the inbox after reconnect; realtime is not a durable delivery queue.

## Backend contract used by this package

Base path: `/api/sdk/notifications` (all endpoints require an Application User JWT).

- `GET /?offset=&limit=` — inbox array (maximum limit 100).
- `GET /unread-count` — `{ "count": number }`.
- `PATCH /{notificationId}/read` — mark one as read.
- `POST /read-all` — mark all as read.
- `DELETE /{notificationId}` — delete one notification.
- `GET /preferences` — category preference array.
- `PUT /preferences` — body `{ "preferences": [{ "category", "pushEnabled", "mutedUntil" }] }`.
- `POST /devices` — register/update this installation.
- `DELETE /devices/{deviceId}` — unregister a device.

The current backend does not expose an archive endpoint. Push messages are a delivery channel, not the source of truth; the durable inbox is read from the API. Never put Firebase service-account JSON or private server credentials into a Flutter app.
