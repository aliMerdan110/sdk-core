# Backend compatibility — `mebabl_posts` 1.0.1

Aligned with `SdkContentController` and the supplied Storage V2 / Media backend source.

## Routes

| SDK operation | HTTP route | Permission |
|---|---|---|
| Create | `POST /api/sdk/content/posts` | `posts.create` |
| Get | `GET /api/sdk/content/posts/{postId}` | `posts.read` |
| List | `GET /api/sdk/content/posts?page={page}&pageSize={pageSize}` | `posts.read` |
| Update text | `PUT /api/sdk/content/posts/{postId}` | `posts.update` |
| Delete | `DELETE /api/sdk/content/posts/{postId}` | `posts.delete` |

All post routes require the Application User JWT. The list endpoint returns an array of PostDto records rather than a pagination envelope.

## Create contract

The request supports `text`, `storageFileIds`, and `mediaAssetIds`. IDs must be GUIDs. The backend places StoredFile attachments first, then MediaAsset attachments.

- `mediaAssetIds` is the preferred path for images/videos. Each asset must belong to the current Project and Application, be Ready, pass Media read rules, and pass Storage `get` authorization for its original object.
- `storageFileIds` is the retained API field for StoredFile-backed attachments. Current Storage V2 StoredFile records are accepted when they belong to the current Project, Application, and user and pass Storage `get` authorization.
- The package intentionally has no dependency on `mebabl_media` or `mebabl_storage`; the app uploads through those services and passes only IDs to Posts.

## Attachment response

`PostAttachmentDto` contains `id`, `storageFileId`, `type`, `order`, `name`, `path`, `contentType`, `size`, `isPublic`, `createdAt`, `url`, and optional `mediaAssetId`. The `isPublic` value is compatibility metadata, not an authorization grant. Attachment content requests are independently authorized by Media Rules and/or Storage Rules.
