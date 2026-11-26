# Backend compatibility — mebabl_chat 1.2.0

This release is aligned with the supplied `SdkChatController.cs`,
`SdkChatPrivacyController.cs`, Chat handlers and the current application-user
JWT contract. All REST operations use the application's shared
`MebablCore` instance and the signed-in Application User JWT.

## Verified routes

| Capability | HTTP contract |
|---|---|
| Create/list conversations | `POST/GET /api/sdk/chat/conversations` |
| Conversation details | `GET /conversations/{conversationId}` |
| Rename group/conversation | `PATCH /conversations/{conversationId}` with `title` |
| Participant list and presence | `GET /conversations/{id}/participants` and `/presence` |
| Add/remove/leave participant | `POST /conversations/{id}/participants`, `DELETE /conversations/{id}/participants/{userId}`, `POST /conversations/{id}/leave` |
| Promote/demote participant | `PUT /conversations/{id}/participants/{userId}/admin` with `isAdmin` |
| Inbox preferences | `PUT /conversations/{id}/preferences` with `isArchived`, `isPinnedInInbox`, `mutedUntilUtc` |
| Messages, pages and sync | `GET /conversations/{id}/messages`, `/messages/page`, `/messages/sync` |
| Send/edit/delete | `POST /conversations/{id}/messages`, `PUT` or `PATCH /messages/{messageId}`, `DELETE /messages/{messageId}` |
| Delivery/read cursor | `PUT /conversations/{id}/delivered` and `PUT /conversations/{id}/read` |
| Per-message readers | `GET /messages/{messageId}/reads` |
| Reactions | `GET/POST /messages/{id}/reactions`, `DELETE /messages/{id}/reactions?reaction=...` |
| Threads/search | `GET /messages/{id}/thread`, `GET /conversations/{id}/messages/search` |
| Voice and attachments | `POST /conversations/{id}/voice-messages`, `POST/GET /messages/{id}/attachments` |
| Pins and forward | `GET /conversations/{id}/pinned-messages`, `POST/DELETE /conversations/{id}/messages/{messageId}/pin`, `POST /messages/{messageId}/forward` |
| Privacy and blocks | `GET/PUT /privacy`, `POST/DELETE /users/{userId}/block`, `GET /blocked-users` |

## Inbox response enrichment

The integration's backend patch adds optional `participants`, `lastMessage`, and
`lastMessageAtUtc` properties to `GetConversationsResponse`. Participant rows
contain only `userId`, `username`, `displayName`, `avatarUrl`, and `isAdmin`.
The preview contains the last eligible message's ID, sender, content, type,
sequence and timestamp. No email, account ID, password, refresh token or other
authentication data is projected. Older clients can ignore the optional fields.

## Conversation creation and security

- The client supplies only invited participant IDs; the backend adds the
  authenticated creator itself as the first participant and admin.
- Direct conversations require exactly one other user and are subject to the
  server's direct-message privacy/block policy.
- Group creation accepts at most 100 invited users; user and application scope
  validation remains on the server.
- User discovery is not a Chat route. The app uses the public-safe Social route
  `GET /api/sdk/social/users/search?q=&page=&pageSize=` and then supplies the
  selected user IDs to Chat. Search results do not expose email or credentials.

## Preference update semantics

The backend's preference `PUT` replaces all three values in one request.
Therefore `updateConversationPreferences` first reads the current inbox state
when a caller changes only one property. It preserves the other values and
supports `clearMute: true` to remove a mute explicitly. This avoids silently
unpinning or unarchiving a conversation when changing another preference.

## Message editing and deletion

Only the original sender may edit or delete a message. Delete is a delete-for-
everyone operation and is subject to the application's Chat retention policy
and delete window; it is not a local-only hide operation. The app must handle
server rejection when the project policy disallows deletion or the time window
has expired.

## Realtime

The hub path is `/hubs/realtime`. Join/leave use `JoinConversation` and
`LeaveConversation`; typing uses `StartTyping` and `StopTyping`. Events include
`messageReceived`, `messageUpdated`, `messageDeleted`, `messageRead`, reaction,
conversation read/delivery, attachment, participant and typing updates.
Realtime events are hints, not a durable queue. The client uses
`/messages/sync` to recover missed changes after reconnect.

## Media

Upload media through the authenticated Storage/Media SDK first. Use the
returned `StoredFileId` with Chat attachment or voice-message methods. Do not
make conversation files public simply to make previews work; every read must
continue to pass the published Storage rules and conversation authorization.
