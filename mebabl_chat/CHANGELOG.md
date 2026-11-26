## 1.3.0


## 1.2.0



## 1.1.1

## 1.2.0

- Add conversation title updates and participant admin management.
- Add message read-receipt retrieval.
- Support `shareLastSeenStatus` in chat privacy updates.
- Preserve unspecified archive, pin, and mute values when updating conversation preferences.
- Parse inbox participant summaries and last-message previews returned by the integrated backend.

- Use PUT for message editing to match the shared MebablCore HTTP client.
- Match Chat search query bounds (3–128 characters).
- Listen to the complete set of Chat realtime event names present in the backend source.
- Add backend DTO contract tests for conversation, message page, sync, and post-share payloads.

## 1.1.0

- Align REST paths and JSON payloads with the current `SdkChatController` contract.
- Add `post_share` structured message payload support.
- Parse the backend's named SignalR events and sync response shape.
- Align read receipts, delivery receipts, forwarding, conversation creation, and privacy preferences.

## 1.0.0

- Initial Chat SDK package.
- Typed conversations, participants, messages, attachments, reactions, cursor pages, and sync results.
- REST operations for conversations, messages, threads, search, delivery/read cursors, reactions, pins, and forwarding.
- Authenticated SignalR client with automatic reconnect and conversation rejoin.

## 1.1.1

- Align REST payloads and response parsing with the supplied `SdkChatController`.
- Use PUT for message edits; the integration backend patch keeps PATCH compatibility.
- Parse the current conversation/message page and sync DTO shapes.
- Expose `lastEventSequence` on conversation details and recover missed changes after SignalR reconnect.
- Add schema-versioned `post_share` messages and backend validation guidance.
- Add model tests for conversation cursors, sync tombstones, message payloads, and named realtime events.
