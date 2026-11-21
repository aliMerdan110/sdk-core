# mebabl_storage

Flutter SDK for the **Project-scoped Storage V2** service in Mebabl Platform.

`mebabl_storage` provides object upload, authorized listing, URL resolution,
content download/streaming, and deletion. It uses `mebabl_core` for the
configured API client and User JWT. It does not create buckets or administer
Storage Security Rules; those are Project Console responsibilities.


### Uploaded file model naming

The upload response model is available under both `MebablStoredFile` and the
compatibility alias `StorageFile`. Both names refer to the same type:

```dart
final StorageFile file = StorageFile.fromJson(responseJson);
// Equivalent: final MebablStoredFile file = MebablStoredFile.fromJson(responseJson);
```

## Requirements

- Flutter `>=3.32.0`
- Dart `>=3.8.1 <4.0.0`
- `mebabl_core: ^1.2.0`
- Mebabl Platform API with Storage V2 deployed

## Installation

Add the package and the Core SDK to `pubspec.yaml`:

```yaml
dependencies:
  mebabl_core: ^1.2.0
  mebabl_storage: ^1.0.0
```

For local development, use a path dependency instead:

```yaml
dependencies:
  mebabl_storage:
    path: ../mebabl_storage
```

## Initialization

Initialize Core and the authentication provider first. Then create the service:

```dart
import 'package:mebabl_core/mebabl_core.dart';
import 'package:mebabl_storage/mebabl_storage.dart';

final core = await MebablCore.initialize();
final storage = MebablStorageService(core: core);
```

The exact Core initialization arguments depend on the app's existing
`mebabl_core` configuration. This package does not initialize Core a second
time and does not own token storage.

## Upload a file

```dart
final storedFile = await storage.uploadFile(
  filePath: selectedFile.path,
  path: 'post-drafts/$currentUserId/$draftId',
  // The SDK detects the MIME type from the file extension when omitted.
  contentType: 'image/jpeg',
  onSendProgress: (sent, total) {
    final progress = total == 0 ? 0.0 : sent / total;
    // Update the UI with progress.
  },
);

print(storedFile.id);
print(storedFile.path);
```

If `bucketId` is omitted, the API resolves the Project's active default
bucket. To upload to a named bucket, pass its GUID:

```dart
final storedFile = await storage.uploadFile(
  filePath: file.path,
  bucketId: configuredBucketId,
  path: 'documents/$currentUserId',
  contentType: 'application/pdf',
);
```

`path` is a relative **directory**. The backend appends the file name. Do not
include the file name in `path`. The current backend rejects a second upload to
an already occupied object path; it does not replace an existing object. Use a
new path, or delete an unreferenced old file before uploading a replacement.

## Upload bytes

Use bytes when the app is using a picker that returns memory data or when
targeting Flutter Web:

```dart
final storedFile = await storage.uploadBytes(
  bytes: pickedBytes,
  fileName: 'avatar.webp',
  path: 'profiles/$currentUserId',
  contentType: 'image/webp',
);
```

The SDK detects a MIME type from the filename when `contentType` is omitted; you may override it when the picker supplies a trusted type. The current backend limit is **50 MiB per object**. The API and the published
Storage Security Rules enforce the effective upload authorization and
constraints independently. The SDK's size check is only an early client-side
check. The current Backend validates the MIME type syntax but does not inspect
file signatures; therefore `contentTypes` rules currently validate the MIME
type declared by the client, not the actual file format. Add server-side file
signature validation before trusting uploaded content types in production.

## List objects

The SDK lists objects within a known bucket. The current SDK API does not
expose a public endpoint to enumerate all Project buckets; bucket management
and discovery are handled by the Developer Console.

```dart
final page = await storage.listObjects(
  bucketId: configuredBucketId,
  prefix: 'post-drafts/$currentUserId',
  page: 1,
  pageSize: 50,
);

for (final item in page.items) {
  print('${item.fileName}: ${item.size} bytes');
}

if (page.hasMore) {
  // Request the next page.
}
```

The backend authorizes the requested `list` prefix and filters each object
before including its metadata. `pageSize` must be between 1 and 100.

## Get URL and read content

```dart
final uri = await storage.getDownloadUrl(fileId: storedFile.id);

final bytes = await storage.downloadFile(fileId: storedFile.id);
```

For large files, stream the response instead of buffering it all in memory:

```dart
final content = await storage.openRead(fileId: storedFile.id);
print(content.contentType);
print(content.contentLength);

await for (final chunk in content.stream) {
  // Write each chunk to a file or feed it to a consumer.
}
```

Byte-range reads are supported by the API:

```dart
final firstChunk = await storage.downloadFile(
  fileId: storedFile.id,
  range: 'bytes=0-1048575',
);
```

### Public objects

The API's URL, content, and listing endpoints allow anonymous HTTP requests,
but anonymous access is **not automatically granted**. The Project must have
an enabled, published Storage Security Rules revision that grants the relevant
`get` or `list` operation with `principal: "public"`.

For a public object, avoid selecting the User JWT mode:

```dart
final publicUri = await storage.getDownloadUrl(
  fileId: publicFileId,
  authenticated: false,
);

final publicBytes = await storage.downloadFile(
  fileId: publicFileId,
  authenticated: false,
);
```

For private objects and authenticated-owner rules, leave `authenticated` at
its default `true`. In either case the server re-evaluates Storage Security
Rules when content is requested. A URL is not a bypass around those rules.

## Delete

```dart
await storage.delete(fileId: storedFile.id);
```

Deletion always uses the Application User JWT and is authorized by the
Storage `delete` operation. The backend also blocks deletion while a stored
file is referenced by a Post or Chat attachment. Detach or remove the content
reference first; do not attempt to bypass that integrity check.

## Security model

- Buckets belong to a **Project**, not to an individual Application.
- Applications in the same Project share the Project's buckets, subject to
  the Project's published Storage Security Rules.
- `get`, `list`, `create`, `update`, and `delete` are separate runtime
  operations. Policies may also use the supported `read` and `write` aliases.
- Upload and delete require an active Application User. Public reads/listing
  are possible only when explicit published rules grant them.
- Database Rules and Media Rules do not grant Storage access.
- Storage Rules do not grant access to a Post or MediaAsset by themselves.
- The SDK never accepts or exposes a `StorageKey` or `StorageProviderKey`.

## Current API contract

| Operation | HTTP endpoint | Authentication behavior |
|---|---|---|
| Upload | `POST /api/sdk/storage/upload` | Application User required |
| Resolve URL | `GET /api/sdk/storage/{fileId}/url` | Anonymous endpoint; Storage `get` policy applies |
| Read content | `GET /api/sdk/storage/{fileId}/content` | Anonymous endpoint; Storage `get` policy applies |
| List objects | `GET /api/sdk/storage/buckets/{bucketId}/objects` | Anonymous endpoint; Storage `list` policy applies |
| Delete | `DELETE /api/sdk/storage/{fileId}` | Application User required |

Upload uses multipart fields:

- `file` — required file part
- `path` — optional relative directory
- `bucketId` — optional Project bucket GUID; omitted means default bucket

The upload endpoint in the current Backend Storage V2 source returns the
`StoredFile` domain entity directly. This SDK intentionally maps only safe
metadata fields and ignores internal provider/storage keys. **Before production
release, the API should return a dedicated safe response DTO instead of
serializing the domain entity**, so internal fields are not sent to clients at
all. The DTO should contain only `id`, `bucketId`, `path`, `fileName`,
`contentType`, `size`, `createdAt`, and optionally `hash` and `version`.

## Error handling

Dio failures are mapped to `MebablException`, preserving the HTTP status,
response data, and request path where available. Common cases include:

- `401` — a User JWT is required or invalid.
- `403` — Storage Security Rules denied the operation, or the bucket is not
  available to the caller.
- `404` — the object or bucket does not exist.
- `409` — deletion is blocked by a content reference, when the API maps that
  integrity conflict to Conflict.
- `413` — upload exceeds the API's 50 MiB request limit.

A missing, unpublished, or disabled Storage policy denies SDK access by
default. Saving a policy draft does not publish it.

## Important scope boundary

This package is for **runtime object access**. Create/rename/enable/disable
buckets, edit Storage Security Rules, validate policy definitions, save drafts,
and publish revisions remain Developer Console operations under Project IAM.
There is no SDK endpoint in the current API contract to list Project buckets
or modify Storage policies.
