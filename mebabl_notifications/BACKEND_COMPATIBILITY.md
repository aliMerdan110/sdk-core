# Backend compatibility — mebabl_notifications 1.0.0

The package expects the user-scoped API at `/api/sdk/notifications`.

Device registration request properties:
- `installationId`
- `platform`
- `provider`
- `token`
- `locale` (optional)

The device response must contain `id` (or `deviceId`), `installationId`,
`platform`, and `provider`.

The SDK does not call project-level Push configuration endpoints. Firebase
service-account credentials are configured and encrypted on the server by the
developer through the project management API; they must never be sent from
the Flutter client.

The FCM convenience bridge relies on the host application's Firebase setup.
The host app remains responsible for Firebase initialization, Android/iOS
native configuration, iOS APNs capability, foreground presentation, and
navigation from a tapped notification.
