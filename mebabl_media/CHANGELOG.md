## 1.1.0

- Added `Unlisted` media visibility.
- Aligned JSON visibility updates with backend numeric enum values (Private=1, Public=2, Unlisted=3).
- Added numeric enum mapping for MediaKind, MediaProcessingStatus, and MediaVariantKind.
- Added optional anonymous content requests for public and unlisted media.
- Added `resolveContentUrl` for backend-relative media URLs.
- Enforced the backend's 25 MiB image and 512 MiB video upload limits client-side.
- Preserved explicit Media Rules and Storage Rules enforcement on the server.

## 1.0.0

- Initial Media SDK release.
