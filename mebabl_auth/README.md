# mebabl_auth

Flutter user-authentication package for Mebabl Platform. Requires
`mebabl_core: ^1.2.0`.

## Initialize

```dart
await MebablCore.initialize();
final auth = MebablAuthService(core: MebablCore.instance);
await auth.initialize();
```

## Register and sign in

Registration creates a user session on the backend and returns both tokens.
No separate login call is required after successful registration.

```dart
final result = await auth.register(
  email: 'user@example.com',
  username: 'user',
  password: 'strong-password',
);

// Or sign in an existing user.
final login = await auth.login(
  email: 'user@example.com',
  password: 'strong-password',
);
```

The service stores the access/refresh-token pair in Core's secure storage and
hydrates `currentUser` using `/api/sdk/auth/me` when that request is available.

## Session

```dart
final user = auth.currentUser;
final changes = auth.authStateChanges;
final events = auth.authStateEvents;
final isSignedIn = await auth.isAuthenticated();
await auth.reload();
await auth.logout();
```

## Password and email operations

```dart
await auth.forgotPassword(email: 'user@example.com');
await auth.resetPassword(token: token, newPassword: 'new-password');
await auth.verifyEmail(token: token);
await auth.resendVerificationEmail();
await auth.changePassword(
  currentPassword: 'old-password',
  newPassword: 'new-password',
);
```

## Authentication routing

The service explicitly selects Core's `MebablAuthMode` for each request:

- Application JWT: register, login, forgot password.
- No JWT: refresh, reset password, verify email.
- User JWT: current user, logout, change password, resend verification email.

`MebablCore` obtains the public Application JWT using the configured API key.
No API secret is stored in this Flutter package.

## Notes

- Refresh-token rotation is performed through `/api/sdk/auth/refresh`.
- Concurrent automatic refresh requests share one in-flight operation.
- A definitive `401` from refresh clears the local user session. Network and
  server errors do not automatically erase stored credentials.
- `dispose()` removes this service's User JWT provider and closes its state
  stream. It does not delete persisted tokens.
