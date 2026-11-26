# Backend compatibility — `mebabl_media` 1.1.0

Aligned with the supplied Mebabl Platform Storage V2 backend source.

## Routes and authorization

| SDK operation | HTTP route | Authentication |
|---|---|---|
| Upload | `POST /api/sdk/media/upload` | Application User JWT |
| Library | `GET /api/sdk/media` | Application User JWT |
| Details | `GET /api/sdk/media/{mediaId}` | Application User JWT |
| Visibility | `PATCH /api/sdk/media/{mediaId}/visibility` | Application User JWT |
| Delete | `DELETE /api/sdk/media/{mediaId}` | Application User JWT |
| Original content | `GET /api/sdk/media/{mediaId}/content` | Optional JWT; Media + Storage rules always evaluated |
| Variant content | `GET /api/sdk/media/{mediaId}/variants/{variantKind}/content` | Optional JWT; Media + Storage rules always evaluated |
| HLS resource | `GET /api/sdk/media/{mediaId}/hls/{path}` | Optional JWT; Media + Storage rules always evaluated |

## Contract details

- Upload multipart fields are `file` and `visibility`. The form value uses `Private`, `Public`, or `Unlisted`.
- JSON `ChangeMediaVisibilityRequest.Visibility` uses the backend's default numeric enum representation: Private=1, Public=2, Unlisted=3.
- `MediaKind`: Image=1, Video=2.
- `MediaProcessingStatus`: PendingUpload=1, Uploaded=2, Queued=3, Processing=4, Ready=5, Failed=6, Rejected=7, DeletionPending=8.
- `MediaVariantKind`: Thumbnail=1, Preview=2, ImageSmall=10, ImageMedium=11, ImageLarge=12, Video360p=20, Video480p=21, Video720p=22, Video1080p=23, HlsMasterPlaylist=30.
- Image uploads are limited to 25 MiB; video uploads are limited to 512 MiB. The backend inspects file signatures and validates extension and supplied Content-Type.
- The backend creates MediaAsset records in the current Project's default Bucket. It evaluates Media rules for the logical asset and Storage rules independently for the underlying object and each derivative.
- Public/Unlisted anonymous content requires a published Media public-read grant **and** a published Storage `get` grant. Unlisted assets are addressable by known URL but are not included in public Media library listing.
- The package has no dependency on `mebabl_storage`; the Media pipeline owns its asset-to-object lifecycle on the server.

## Client behavior

- Upload, library, details, visibility changes, and delete always use the User JWT.
- Content methods default to `authenticated: true`. Set `authenticated: false` only when the asset is intended for anonymous delivery and both rule sets grant it.
- `resolveContentUrl` resolves backend-relative content URLs against `MebablCore.config.baseUrl`; it does not grant or bypass authorization.
- Numeric enum values are exposed raw and also mapped by typed getters such as `isImage`, `isReady`, `isUnlisted`, and `isThumbnail`.
