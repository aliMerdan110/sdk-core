import 'dart:convert';

import '../client/mebabl_http_client.dart';
import '../config/mebabl_config.dart';
import '../errors/mebabl_exception.dart';
import 'application_token_storage.dart';

class MebablApplicationAuthService {
  final MebablConfig config;
  final MebablHttpClient http;
  final MebablApplicationTokenStorage tokenStorage;

  Future<String>? _authenticateFuture;

  MebablApplicationAuthService({
    required this.config,
    required this.http,
    required this.tokenStorage,
  });

  Future<String> getValidApplicationToken() async {
    final token = await tokenStorage.getToken();

    if (token != null && token.isNotEmpty && !_isTokenExpired(token)) {
      return token;
    }

    return _authenticateOnce();
  }

  Future<String> _authenticateOnce() {
    final existing = _authenticateFuture;

    if (existing != null) {
      return existing;
    }

    final future = authenticate();

    _authenticateFuture = future;

    return future.whenComplete(() {
      if (identical(_authenticateFuture, future)) {
        _authenticateFuture = null;
      }
    });
  }

  Future<String> authenticate() async {
    try {
      final response = await http.post<Map<String, dynamic>>(
        '/api/application-auth/token',
        data: {
          'apiKey': config.apiKey,
          'apiSecret': config.apiSecret,
        },
      );

      final data = response.data;

      if (data == null) {
        throw const MebablException(
          message:
              'Application authentication failed: the server returned an empty response.',
        );
      }

      final accessToken = data['accessToken']?.toString();

      if (accessToken == null || accessToken.isEmpty) {
        throw const MebablException(
          message:
              'Application authentication failed: the server response does not contain an access token.',
        );
      }

      await tokenStorage.saveToken(accessToken);

      return accessToken;
    } catch (error) {
      if (error is MebablException) {
        rethrow;
      }

      throw MebablException(
        message:
            'Application authentication failed. Unable to obtain an application access token.',
        data: error,
      );
    }
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');

      if (parts.length != 3) {
        return true;
      }

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);

      final decoded = utf8.decode(
        base64Url.decode(normalized),
      );

      final data = jsonDecode(decoded);

      if (data is! Map<String, dynamic>) {
        return true;
      }

      final exp = data['exp'];

      if (exp is! num) {
        return true;
      }

      final expiry = DateTime.fromMillisecondsSinceEpoch(
        exp.toInt() * 1000,
        isUtc: true,
      );

      return !DateTime.now().toUtc().isBefore(expiry);
    } catch (_) {
      return true;
    }
  }

  Future<void> clear() {
    return tokenStorage.clear();
  }
}
