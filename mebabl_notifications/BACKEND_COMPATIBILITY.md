# Backend compatibility — mebabl_notifications 1.2.0

The package is aligned with the supplied `SdkNotificationsController` and
uses the authenticated Application User JWT through the shared `MebablCore`
client.

## Inbox routes

| Capability | HTTP contract |
|---|---|
| Inbox | `GET /api/sdk/notifications?offset=&limit=` |
| Unread count | `GET /unread-count` (response `{count}`) |
| Mark one read | `PATCH /{notificationId}/read` |
| Mark all read | `POST /read-all` |
| Delete one | `DELETE /{notificationId}` |
| Preferences | `GET/PUT /preferences` |
| Devices | `GET /devices`, `POST /devices`, `DELETE /devices/{deviceInstallationId}` |
| Quiet hours | `GET/PUT /quiet-hours` |
| Web Push key/subscription | `GET /web-push/public-key`, `POST /web-push/subscriptions` |

The inbox uses offset/limit pagination and returns an array. Its DTO includes
`id`, `type`, `title`, `message`, `data`, `isRead`, `readAt`, `createdAt`,
`actorUserId`, `targetType`, `targetId`, `priority`, `aggregatedCount`, `locale`
and `category`; nullable/additional fields are parsed defensively.

## Device registration

The stable installation ID is generated and stored independently of the FCM
token. FCM registration is limited to supported native/web platforms and uses
the server's returned device registration ID for restore/revoke handling. Device
list results include platform, provider, locale, app version and timestamps.

Browser subscriptions require the project's Web Push configuration. Private
VAPID keys remain on the server; the Flutter client receives only the public
key and sends the browser endpoint/key material over the authenticated API.
Firebase service-account credentials must never be embedded in the client.

## Quiet hours and preferences

Quiet-hour policy uses `isEnabled`, `timeZoneId`, `startTime`, `endTime`,
`daysOfWeekMask` and `allowHighPriority`. The server validates `HH:mm`,
time-zone availability and the 7-bit weekday mask. Category preferences are
sent as `{preferences:[{category,pushEnabled,mutedUntil}]}`.

## Unsupported archive operation

The inspected backend has no notification archive endpoint and the inbox DTO
has no archive state. Accordingly, the SDK rejects `archive` and the obsolete
`includeArchived` option locally rather than issuing a request that would fail
with 404 or pretending the notification was archived. Use mark-as-read or
delete where appropriate.

Push delivery and SignalR are delivery/refresh channels only. The durable
notification inbox from the API remains the source of truth.
