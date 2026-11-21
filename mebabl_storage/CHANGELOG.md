## 1.1.2

- Export the `StorageFile` compatibility type alias for uploaded-file metadata.
- Make `createdAt` optional when constructing file metadata locally.
- Keep `MebablStoredFile` as the canonical model name.

## 1.0.0

- Initial Project-scoped Storage SDK for Mebabl Platform Storage V2.
- Upload files from paths or bytes, with progress and cancellation support.
- List authorized objects, resolve content URLs, download or stream content, and delete files.
- Support authenticated and anonymous reads as evaluated by published Storage Security Rules.
- Keep provider keys and physical storage keys out of SDK models.
