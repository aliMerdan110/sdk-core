# Backend compatibility — mebabl_notifications 1.1.0

The package targets the user-scoped API at `/api/sdk/notifications`. All REST calls use the Application User JWT.

## Inbox

- `GET /?offset=&limit=` returns a plain array of `GetNotificationsResponse`.
- Notification JSON includes `id`, `userId`, `type`, `title`, `message`, `data`, `isRead`, `readAt`, `createdAt`, `actorUserId`, `targetType`, and `targetId`.
- `GET /unread-count` returns `{ "count": number }`.
- `PATCH /{notificationId}/read`, `POST /read-all`, and `DELETE /{notificationId}` are supported.
- Archive is not part of the current backend contract.

## Preferences

- `GET /preferences` returns an array of `category`, `pushEnabled`, `mutedUntilUtc`, and `isCustomized`.
- `PUT /preferences` accepts `{ "preferences": [{ "category", "pushEnabled", "mutedUntil" }] }` and returns the updated array.
- Categories: `messaging`, `social`, `account`, `security`, `system`, `moderation`, `general`.

## Device registration

Request properties:
- `installationId`
- `platform`
- `provider`
- `token`
- `locale` (optional)
- `appVersion` (optional)

The response contains device installation metadata including an ID. The SDK does not call project-level Push configuration endpoints. Firebase service-account credentials are configured and encrypted on the server by the developer through project management APIs; they must never be sent from the Flutter client.

The FCM convenience bridge relies on host application Firebase setup. The host app remains responsible for Firebase initialization, Android/iOS native configuration, iOS APNs capability, foreground presentation, and navigation from a tapped notification.
