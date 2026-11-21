# Backend compatibility — Storage V2

This package is aligned with the `Mebabl.Platform.StorageV2` source supplied
for this task. The runtime endpoints used are:

| SDK method | Backend route | Request/auth |
|---|---|---|
| `uploadFile`, `uploadBytes` | `POST /api/sdk/storage/upload` | multipart `file`, optional `path`, optional `bucketId`; Application User policy |
| `getDownloadUrl` | `GET /api/sdk/storage/{fileId}/url` | `AllowAnonymous`; evaluator checks Storage `get` |
| `downloadFile`, `openRead` | `GET /api/sdk/storage/{fileId}/content` | `AllowAnonymous`; evaluator checks Storage `get` |
| `listObjects` | `GET /api/sdk/storage/buckets/{bucketId}/objects` | `AllowAnonymous`; evaluator checks Storage `list` for the requested prefix and every returned object |
| `delete` | `DELETE /api/sdk/storage/{fileId}` | Application User policy; evaluator checks Storage `delete` |

Contract details confirmed in the supplied backend source:

- Upload maximum is 50 MiB.
- Omitted `bucketId` resolves the active Project default bucket.
- The upload `path` is a relative directory; the backend appends `fileName`.
- Listing uses page numbers and page sizes from 1 to 100 and returns
  `items`, `page`, `pageSize`, and `hasMore`.
- A listed item contains `id`, `bucketId`, `path`, `fileName`, `contentType`,
  `size`, `createdAt`, and `contentUrl`.
- The content endpoint enables HTTP range processing.
- Deletion is blocked while a stored file remains referenced by Post or Chat
  attachment rows.
- Bucket administration and Storage Rules management are Developer Console
  operations, not SDK runtime endpoints.

## Backend change recommended before production

The current `POST /api/sdk/storage/upload` action returns the `StoredFile`
domain entity directly. The entity includes internal `StorageProviderKey` and
`StorageKey` properties. The SDK model ignores those properties, but the HTTP
response still serializes them. Update the API to return a dedicated response
DTO containing only safe metadata. The recommended DTO fields are:

- `id`
- `bucketId`
- `path`
- `fileName`
- `contentType`
- `size`
- `createdAt`
- optionally `hash` and `version`

This package remains tolerant of the current entity-shaped response and the
recommended DTO as long as those public fields retain their names.

## Content type validation note

The Storage upload handler currently validates the syntax of the multipart
`ContentType`, then passes that declared type into Storage Rules. It does not
inspect file signatures in the code supplied for this task. Therefore
`contentTypes` constraints currently filter the client-declared MIME type, not
a cryptographically or structurally verified file format. Treat MIME rules as
a policy filter, not a malware or file-format validation boundary. For
production, add server-side signature/type detection (and malware scanning if
needed) before treating a file as a trusted image, video, archive, or document.
