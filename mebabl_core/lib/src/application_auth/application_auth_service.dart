import 'dart:convert';

import '../client/mebabl_auth_mode.dart';
import '../client/mebabl_http_client.dart';
import '../config/mebabl_config.dart';
import '../errors/mebabl_exception.dart';
import 'application_token_storage.dart';

/// Obtains and caches the limited public Application JWT.
///
/// The public API key is sent to `/api/application-auth/token`. No API secret
/// is used or required by the Flutter SDK.
class MebablApplicationAuthService {
  static const String tokenEndpoint = '/api/application-auth/token';

  final MebablConfig config;
  final MebablHttpClient http;
  final MebablApplicationTokenStorage tokenStorage;
  final Duration clockSkew;

  Future<String>? _authenticationFuture;

  MebablApplicationAuthService({
    required this.config,
    required this.http,
    required this.tokenStorage,
    this.clockSkew = const Duration(seconds: 30),
  });

  Future<String> getValidApplicationToken() async {
    final storedToken = await tokenStorage.getToken();
    if (storedToken != null &&
        storedToken.isNotEmpty &&
        !_isTokenExpired(storedToken)) {
      return storedToken;
    }

    return _authenticateOnce();
  }

  /// Renews the token after a protected request returned 401.
  ///
  /// When several requests receive 401 together, requests that observe a
  /// different, already-renewed token reuse it rather than renewing again.
  Future<String> refreshAfterUnauthorized({String? rejectedToken}) async {
    final currentToken = await tokenStorage.getToken();

    if (currentToken != null &&
        currentToken.isNotEmpty &&
        currentToken != rejectedToken &&
        !_isTokenExpired(currentToken)) {
      return currentToken;
    }

    await tokenStorage.clear();
    return _authenticateOnce();
  }

  Future<String> _authenticateOnce() {
    final current = _authenticationFuture;
    if (current != null) return current;

    final future = _authenticate();
    _authenticationFuture = future;

    return future.whenComplete(() {
      if (identical(_authenticationFuture, future)) {
        _authenticationFuture = null;
      }
    });
  }

  Future<String> _authenticate() async {
    try {
      final response = await http.post<Map<String, dynamic>>(
        tokenEndpoint,
        data: {'apiKey': config.apiKey},
        authMode: MebablAuthMode.none,
      );

      final responseData = response.data;
      if (responseData == null) {
        throw const MebablException(
          message: 'Application authentication returned an empty response.',
        );
      }

      final accessToken = responseData['accessToken'];
      final applicationId = responseData['applicationId'];

      if (accessToken is! String || accessToken.trim().isEmpty) {
        throw const MebablException(
          message: 'Application authentication response has no access token.',
        );
      }

      if (applicationId is! String ||
          applicationId.toLowerCase() != config.applicationId.toLowerCase()) {
        throw const MebablException(
          message:
              'The returned Application ID does not match the SDK configuration.',
        );
      }

      await tokenStorage.saveToken(accessToken);
      return accessToken;
    } on MebablException {
      rethrow;
    } catch (error) {
      throw MebablException(
        message: 'Application authentication failed.',
        cause: error,
      );
    }
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(payload));
      final claims = jsonDecode(decoded);
      if (claims is! Map) return true;

      final expiration = claims['exp'];
      if (expiration is! num) return true;

      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        expiration.toInt() * 1000,
        isUtc: true,
      );

      return !DateTime.now().toUtc().add(clockSkew).isBefore(expiresAt);
    } catch (_) {
      // If the JWT cannot be inspected, obtain a fresh token rather than
      // trusting a malformed or unverifiable cached value.
      return true;
    }
  }

  Future<void> clear() => tokenStorage.clear();
}
