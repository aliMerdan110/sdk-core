# Mebabl Posts Flutter SDK

`mebabl_posts` provides post creation and management for Flutter applications using the Mebabl Platform. It is designed for Android and reuses the shared `mebabl_core` HTTP client and User JWT configuration.

The package has **no direct dependency on `mebabl_media` or `mebabl_storage`**. An application can create text-only posts and read/update/delete posts with `mebabl_posts` alone. Upload images and videos with `mebabl_media`, then pass their `MediaAsset` IDs to `mediaAssetIds`. Upload other StoredFile attachments with `mebabl_storage`, then pass their IDs through the retained `storageFileIds` API field.

## Requirements

- Flutter 3.32.0 or later
- Dart 3.8.1 or later
- `mebabl_core` 1.2.0 or later
- An initialized Mebabl application
- A signed-in application user with the relevant post permissions

## Installation

For a local SDK workspace:

```yaml
dependencies:
  mebabl_core: ^1.2.0
  mebabl_posts:
    path: ../mebabl_posts
```

`mebabl_auth` is normally included by the host application to manage user sign-in and provide the User JWT to Core. It is not duplicated or bundled by this package.

## Initialization

Initialize Core and configure user authentication first. Then create the post service:

```dart
import 'package:flutter/widgets.dart';
import 'package:mebabl_core/mebabl_core.dart';
import 'package:mebabl_auth/mebabl_auth.dart';
import 'package:mebabl_posts/mebabl_posts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final core = await MebablCore.initialize();
  final auth = MebablAuthService(core: core);
  await auth.initialize();

  final posts = MebablPostService(core: core);
  runApp(MyApp(posts: posts));
}
```

`MebablAuthService` registers its User JWT provider with `MebablCore`. All post requests select `MebablAuthMode.user` explicitly. The user must be signed in and have the required permissions.

## Create a text-only post

```dart
final post = await posts.create(
  text: 'Hello from my application',
);

print(post.id);
```

## Create a post with images or videos

Upload each image or video with the optional `mebabl_media` package, then pass the resulting `MediaAsset` IDs. The posts package does not import or depend on `mebabl_media`. In an application that includes both packages, create the media service with the same Core instance:

```dart
import 'package:mebabl_media/mebabl_media.dart';

final media = MebablMediaService(core: core);

final uploadedImage = await media.uploadFile(
  filePath: imagePath,
);

final uploadedVideo = await media.uploadFile(
  filePath: videoPath,
);

final post = await posts.create(
  text: 'A post with media',
  mediaAssetIds: [uploadedImage.id, uploadedVideo.id],
);
```

The server requires MediaAssets to belong to the current application, be available and not deleted, and have a processing status of `Ready`. It also checks that the current user can read each asset. Upload completion does not necessarily mean media processing is finished; fetch the media details until the status is `Ready` before creating a post.

For general files stored through Project Storage V2, upload with `mebabl_storage` and attach the returned StoredFile ID. The Posts package does not depend on the Storage package; both services only share `MebablCore`:

```dart
import 'package:mebabl_storage/mebabl_storage.dart';

final storage = MebablStorageService(core: core);
final uploadedDocument = await storage.uploadFile(
  filePath: documentPath,
  path: 'post-attachments',
);

final post = await posts.create(
  text: 'A post with a document',
  storageFileIds: [uploadedDocument.id],
);
```

The JSON property remains named `storageFileIds` for backend compatibility. When both ID lists are sent, the backend orders StoredFile attachments before MediaAsset attachments. The backend verifies ownership and evaluates Storage `get` rules before attaching a StoredFile.

## Read posts

```dart
final post = await posts.get(postId: postId);

final firstPage = await posts.list(
  page: 1,
  pageSize: 20,
);
```

The current API returns a JSON array for the list operation. It does not return a total count or total-pages envelope. The SDK therefore returns `List<MebablPost>` and does not invent pagination metadata.

Each post includes ordered attachments. `MebablPostAttachment` exposes `storageFileId` for StoredFile-backed attachments and `mediaAssetId` for MediaAsset records. The convenience getter `isStoredFile` identifies Storage-backed attachments; `isLegacyStorageFile` remains as a deprecated alias. The `isPublic` field is compatibility metadata only and does not grant access. The `url` returned by the backend is usually a relative path. Resolve it with:

```dart
final uri = attachment.resolveUri(core.config.baseUrl);
// Or:
final uri2 = posts.resolveAttachmentUrl(attachment.url);
```

Private MediaAsset and StoredFile content require a User JWT. Public or Unlisted MediaAsset delivery can be anonymous only when both Media Rules and Storage Rules allow it. StoredFile content follows Storage Rules. A plain `Image.network(uri.toString())` or a player that does not send authorization headers will not automatically use the Mebabl token. Use `mebabl_media` content methods or `mebabl_storage` download methods for protected bytes/streams, and set `authenticated: false` only when the resource is explicitly allowed to anonymous readers.

## Update post text

```dart
final updated = await posts.updateText(
  postId: postId,
  text: 'Updated post text',
);
```

The current backend update contract changes the text only. It does not add, remove, or reorder attachments. The server also rejects an update that would leave a post with neither text nor attachments.

## Delete a post

```dart
await posts.delete(postId: postId);
```

The backend performs a soft delete. Only the post owner with the `posts.delete` permission can delete it.

## API routes used

| Operation | Method | Route |
|---|---|---|
| Create | POST | `/api/sdk/content/posts` |
| Get one | GET | `/api/sdk/content/posts/{postId}` |
| List | GET | `/api/sdk/content/posts?page={page}&pageSize={pageSize}` |
| Update text | PUT | `/api/sdk/content/posts/{postId}` |
| Delete | DELETE | `/api/sdk/content/posts/{postId}` |

All post create, get, list, update, and delete routes require the `ApplicationUser` authorization policy and use the User JWT. Attachment content is served by separate Media or Storage endpoints, each of which evaluates its own rules.

## Permissions

The backend checks these permissions:

| Operation | Permission |
|---|---|
| Create | `posts.create` |
| Get/list | `posts.read` |
| Update | `posts.update` |
| Delete | `posts.delete` |

Permission checks and application/user ownership validation remain authoritative on the server. SDK-side validation is only an early developer convenience.

## Error handling

HTTP failures are normalized by `mebabl_core` into `MebablException`:

```dart
try {
  await posts.create(text: 'Hello');
} on MebablException catch (error) {
  if (error.isUnauthorized) {
    // The user session is missing or expired.
  } else if (error.isForbidden) {
    // The user does not have the required post permission.
  } else if (error.isValidationError) {
    // The post body or attachment references were rejected.
  } else if (error.isNotFound) {
    // The post does not exist or is not visible to this user.
  }
}
```

## Scope

This package implements only operations exposed by the current `SdkContentController`: create, get, list, update text, and delete. It does not add comments, reactions, likes, feeds, attachment mutation, or other endpoints that are not present in that controller.
