# Mebabl Auth SDK

Authentication SDK package for the Mebabl platform, built on top of `mebabl_core`. It provides seamless user authentication, automatic token management, refresh token rotation, and robust HTTP request interceptors.

## Features

- 🔐 **Secure Login & Logout:** Simple methods to authenticate users and securely manage session tokens.
- 🔄 **Automatic Token Refresh:** Built-in interceptors to handle expired access tokens automatically using secure refresh token rotation.
- 👤 **Current User Profile Management:** Easily fetch and manage authenticated user details and states.
- 🛡️ **Clean Architecture Integration:** Implements flexible state management, API service handlers, and seamless dependency injection.

## Installation

Add the updated versions of `mebabl_core` and `mebabl_auth` to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter:
    sdk: flutter
  mebabl_core: ^1.0.4  # أو الإصدار المحدث الذي تستخدمه
  mebabl_auth: ^1.0.1  # أو الإصدار المحدث الذي تستخدمه