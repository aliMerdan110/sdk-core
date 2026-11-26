# mebabl_chat

Typed Flutter SDK for the current Mebabl Chat API. It uses the shared
`mebabl_core` HTTP client and the authenticated Application User JWT.

## Requirements

- Dart `>=3.8.1`
- Flutter `>=3.32.0`
- `mebabl_core ^1.2.0`
- An authenticated Application User session initialized by `mebabl_auth`.

## Installation in a local SDK workspace

Add the package as a path dependency, using the path where you extracted this
folder:

```yaml
dependencies:
  mebabl_chat:
    path: <path-to-mebabl_chat>
```

Keep the application's existing `mebabl_core`, `mebabl_auth`, and
`mebabl_social` dependencies; this package shares their initialized Core
instance and does not create another token store.

## Initialize

```dart
final chat = MebablChatService(core: core);
final realtime = MebablChatRealtimeClient(
  core: core,
  getAccessToken: () => core.tokenStorage.getAccessToken(),
);

await realtime.connect();
await realtime.joinConversation(conversationId);
```

## Send messages

```dart
final sent = await chat.sendMessage(
  conversationId: conversationId,
  content: 'Hello',
);

final reply = await chat.sendMessage(
  conversationId: conversationId,
  content: 'Reply',
  replyToMessageId: sent.id,
);
```

The SDK creates a `clientMessageId` for idempotent send behavior. For queued
messages, persist and reuse the same ID when retrying. The backend derives
`ThreadRootMessageId` from `ReplyToMessageId`; callers must not supply a
separate thread root.

## Share a Content post in Chat

```dart
await chat.sendPostShare(
  conversationId: conversationId,
  postId: postId,
);
```

This sends a `post_share` message with a versioned `postId` reference. The
recipient loads the current post via Content API with their own permission.
The backend validation patch included in the integration ZIP is required to
validate the reference before message persistence.

## Realtime

The current backend hub is `/hubs/realtime`. The client joins conversation
groups with `JoinConversation`, leaves with `LeaveConversation`, and sends
typing indicators through `StartTyping`/`StopTyping`. It listens to named
backend events such as `messageReceived`, `messageUpdated`, `reactionAdded`,
`conversationRead`, and `userTyping`.

Use the REST sync endpoint after reconnect to recover events missed while
offline. `getConversation()` returns `lastEventSequence`; initialize the sync
cursor from that value. The realtime client emits a local
`connectionReconnected` event after it rejoins conversation groups. SignalR
notifications alone are not a durable message store.

## Files and voice messages

Upload the file to the application's Storage service first. Then use the
returned `StoredFileId` with `attachFileToMessage` or `sendVoiceMessage`.
Never pass a device file path as a StoredFile ID.

See `BACKEND_COMPATIBILITY.md` for the exact API and realtime contract.
