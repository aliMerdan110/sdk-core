# Changelog

## 1.1.0

- Updated the dependency to `mebabl_core ^1.2.0`.
- Applied explicit Application, User, and unauthenticated request modes to all SDK auth endpoints.
- Removed the legacy interceptor registration flow and registered the service as Core's User JWT provider.
- Implemented shared refresh-token rotation with a concurrency guard and stale-token recheck.
- Kept local credentials after network and server failures; clear the session after a definitive refresh-token `401`.
- Added current-user state events while retaining the existing `authStateChanges` stream.
- Added required-field validation for login and refresh responses.
- Added tests for request/response models and user parsing.
