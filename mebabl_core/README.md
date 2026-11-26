# mebabl_core 1.2.0

Core infrastructure for the Mebabl Flutter SDK.

## Configuration asset

Create `assets/mebabl.json` with public client configuration only:

```json
{
  "applicationId": "YOUR_APPLICATION_ID",
  "platformId": "YOUR_PLATFORM_ID",
  "platform": "android",
  "packageName": "com.example.app",
  "apiKey": "YOUR_PUBLIC_API_KEY",
  "baseUrl": "https://api.example.com"
}
```

Do not put `apiSecret`, trusted application credentials, or other server-side
secrets in a Flutter application. The public API key is used only to obtain a
limited `application_public` JWT from `POST /api/application-auth/token`.

Add the asset to `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/mebabl.json
```

## Initialize Core

```dart
import 'package:mebabl_core/mebabl_core.dart';

final core = await MebablCore.initialize();
```

Concurrent initialization calls share the same initialization operation.

## Explicit request authentication

Requests default to no automatic JWT. Select the policy required by the API:

```dart
// ApplicationPublic policy: register, login, forgot password.
await core.http.post(
  '/api/sdk/auth/login',
  data: {
    'email': 'user@example.com',
    'password': 'password',
  },
  authMode: MebablAuthMode.application,
);

// No JWT: refresh, reset password, verify email.
await core.http.post(
  '/api/sdk/auth/refresh',
  data: {'refreshToken': refreshToken},
  authMode: MebablAuthMode.none,
);

// ApplicationUser policy: me, logout, change password.
await core.http.get(
  '/api/sdk/auth/me',
  authMode: MebablAuthMode.user,
);
```

The `mebabl_auth` package should implement `MebablAuthProvider` and register it
once initialized:

```dart
core.addAuthProvider(authProvider);
```

Core attaches the User JWT only to requests marked `MebablAuthMode.user`.
`mebabl_auth` remains responsible for user registration, login, refresh-token
rotation, logout, and user session lifecycle.

## Token storage

- `MebablApplicationTokenStorage` stores the public Application JWT.
- `MebablTokenStorage` stores the User access and refresh tokens.

The two token types use separate secure-storage keys. `MebablCore.reset()`
resets the in-memory singleton only; it does not erase persisted tokens.

## Errors

HTTP failures are converted to `MebablException`. Use `statusCode` and its
classification getters (`isUnauthorized`, `isConflict`, `isRateLimited`,
`isServerError`, and others) rather than comparing the `message` string.
Request and response bodies are not printed by Core.
