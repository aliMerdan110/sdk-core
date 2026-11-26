# Mebabl Media Flutter SDK

`mebabl_media` provides image and video asset operations for Flutter applications using the Mebabl Platform. It is designed for Android and works with the shared `mebabl_core` HTTP client and the User JWT supplied by `mebabl_auth`.

## Requirements

- Flutter 3.32.0 or later
- Dart 3.8.1 or later
- `mebabl_core` 1.2.0 or later
- An initialized Mebabl application
- A signed-in application user for upload, metadata, library, visibility, and delete operations
- Public/unlisted media delivery can be anonymous only when both Media Rules and Storage Rules grant access

## Installation

For a local SDK workspace:

```yaml
dependencies:
  mebabl_core: ^1.2.0
  mebabl_auth: ^1.1.0
  mebabl_media:
    path: ../mebabl_media
```

When published to a package registry, replace the path dependency with the published version.

## Initialization

Initialize Core and Auth first. The media service reuses both; it does not create another HTTP client, token store, or authentication flow.

```dart
import 'package:flutter/widgets.dart';
import 'package:mebabl_core/mebabl_core.dart';
import 'package:mebabl_auth/mebabl_auth.dart';
import 'package:mebabl_media/mebabl_media.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final core = await MebablCore.initialize();
  final auth = MebablAuthService(core: core);
  await auth.initialize();

  final media = MebablMediaService(core: core);
  runApp(MyApp(media: media));
}
```

The user must be signed in before calling upload, library, details, visibility, delete, or content methods. The Core auth interceptor attaches the current User JWT to these requests.

## Upload an image or video from a local path

```dart
final result = await media.uploadFile(
  filePath: pickedFile.path!,
  visibility: MebablMediaVisibility.private,
  onSendProgress: (sent, total) {
    final progress = total <= 0 ? 0.0 : sent / total;
    // Update your UI with progress (0.0 to 1.0).
  },
);

print(result.id);
print(result.status);
```

## Upload bytes

```dart
final result = await media.uploadBytes(
  bytes: imageBytes,
  fileName: 'profile.webp',
  visibility: MebablMediaVisibility.public,
);
```

The SDK submits multipart form fields named `file` and `visibility`, matching `POST /api/sdk/media/upload`.

The upload endpoint binds `visibility` from multipart form text (`Private`, `Public`, or `Unlisted`). For the JSON visibility-update endpoint, the SDK sends the backend's numeric enum values: `Private = 1`, `Public = 2`, and `Unlisted = 3`. The optional `visibilityJsonEncoder` is only needed when integrating with a customized API that uses a different JSON representation.

### Server validation limits

- Images: maximum 25 MB.
- Videos: maximum 512 MB.
- Supported image formats: JPEG, PNG, GIF, WebP.
- Supported video formats: MP4, MOV, WebM.

The server detects media type from file content and validates the extension and content type. Client-side checks are convenience checks only; server validation remains authoritative.

## Media library

```dart
final page = await media.list(
  page: 1,
  pageSize: 24,
  kind: 'Video', // Optional API enum name or numeric value as a string.
  status: 'Ready',
  visibility: 'Private',
);

for (final asset in page.items) {
  print('${asset.id}: ${asset.originalFileName}');
}

if (page.hasNextPage) {
  // Request page + 1.
}
```

## Get details and wait for processing

An upload can be accepted before image/video processing is finished. Fetch the details endpoint to observe the status and generated variants:

```dart
final asset = await media.get(mediaId: result.id);

if (asset.isReady) {
  for (final variant in asset.variants) {
    final routeKind = variant.knownKindName ?? variant.kind.toString();
    print('$routeKind: ${media.resolveContentUrl(variant.contentUrl)}');
  }
}
```

`kind`, `visibility`, `status`, and variant `kind` preserve the original JSON enum value. The current Backend uses numeric enums; the SDK maps the known backend values through helpers such as `asset.isImage`, `asset.isVideo`, `asset.isReady`, `asset.isUnlisted`, and `variant.isThumbnail`. Raw values remain available through `name` and `numericValue`.

## Manage visibility and deletion

```dart
await media.changeVisibility(
  mediaId: result.id,
  visibility: MebablMediaVisibility.public,
);

await media.delete(mediaId: result.id);
```

The backend may return `409 Conflict` when an asset cannot be deleted, for example when it is still attached to content. HTTP errors are raised as `MebablException` from `mebabl_core`.

## Read media content

For private media, keep the default authenticated request. Public and Unlisted media can be requested anonymously; the server still evaluates the published Media Rules and Storage Rules:

```dart
// Private content (User JWT sent).
final privateBytes = await media.downloadOriginal(mediaId: asset.id);

// Public or Unlisted content (no User JWT sent).
final publicBytes = await media.downloadOriginal(
  mediaId: publicAssetId,
  authenticated: false,
);

final thumbnailBytes = await media.downloadVariant(
  mediaId: asset.id,
  variantKind: 'Thumbnail',
  authenticated: false, // only when both rule sets grant anonymous read
);
```

For large video content, use a stream to avoid allocating the entire response in memory:

```dart
final content = await media.openOriginalContent(
  mediaId: asset.id,
  authenticated: true, // set false for content allowed to anonymous readers
);
print(content.contentType);
print(content.contentLength);

await for (final chunk in content.stream) {
  // Consume or write each chunk.
}
```

HTTP byte ranges are supported by the SDK for original and variant content:

```dart
final firstChunk = await media.downloadOriginal(
  mediaId: asset.id,
  range: 'bytes=0-1048575',
);
```

HLS playlists and child resources use the same optional authentication behavior. Public and Unlisted playback can use anonymous requests when Media Rules and Storage Rules both allow access:

```dart
final playlist = await media.downloadHlsResource(
  mediaId: asset.id,
  relativePath: 'master.m3u8',
  authenticated: false,
);
```

The SDK returns the playlist bytes/stream; it does not include a video-player UI or a third-party player dependency. Player integration can be added as a separate package after the required playback/auth-header contract is finalized.

## API routes used

| Operation | Method | Route |
|---|---|---|
| Upload | POST | `/api/sdk/media/upload` |
| Library | GET | `/api/sdk/media` |
| Details | GET | `/api/sdk/media/{mediaId}` |
| Visibility | PATCH | `/api/sdk/media/{mediaId}/visibility` |
| Delete | DELETE | `/api/sdk/media/{mediaId}` |
| Original content | GET | `/api/sdk/media/{mediaId}/content` |
| Variant content | GET | `/api/sdk/media/{mediaId}/variants/{variantKind}/content` |
| HLS resource | GET | `/api/sdk/media/{mediaId}/hls/{path}` |

All management and metadata routes require the `ApplicationUser` authorization policy. Original, variant, and HLS content routes are marked `AllowAnonymous`; anonymous delivery is still denied unless the active Media Rules grant public reads and the independent Storage Rules grant object `get`. Private delivery should send the User JWT.

## Error handling

```dart
try {
  await media.uploadFile(filePath: pickedFile.path!);
} on MebablException catch (error) {
  if (error.isUnauthorized) {
    // The user session is missing or expired and could not be refreshed.
  } else if (error.isForbidden) {
    // Media permission was denied.
  } else if (error.isValidationError) {
    // The file or request did not pass server validation.
  } else if (error.isConflict) {
    // The operation conflicts with the current media state.
  }
}
```
