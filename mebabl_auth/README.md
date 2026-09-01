# Mebabl Auth SDK

Authentication SDK package for the Mebabl platform, built on top of `mebabl_core`. It provides seamless user authentication, automatic token management, refresh token rotation, and HTTP request interceptors.

## Features

- 🔐 **Secure Login & Logout:** Simple methods to authenticate users and securely clear session tokens.
- 🔄 **Automatic Token Refresh:** Built-in interceptors to handle expired access tokens automatically using refresh tokens.
- 👤 **Current User Profile:** Easily fetch authenticated user details.
- 🛡️ **Clean Architecture Integration:** Implements `MebablAuthProvider` for flexible state management and dependency injection.

## Installation

Add `mebabl_auth` to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter:
    sdk: flutter
  mebabl_core: ^1.0.0
  mebabl_auth: ^1.0.0