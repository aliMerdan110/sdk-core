import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage for the user session managed by `mebabl_auth`.
///
/// Application tokens use a separate storage class and a separate key.
class MebablTokenStorage {
  static const String _accessTokenKey = 'mebabl_access_token';
  static const String _refreshTokenKey = 'mebabl_refresh_token';

  final FlutterSecureStorage _storage;

  MebablTokenStorage({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (accessToken.trim().isEmpty || refreshToken.trim().isEmpty) {
      throw ArgumentError('Access token and refresh token must not be empty.');
    }

    try {
      // Write sequentially. If either write fails, remove both values so a
      // partially updated pair cannot be mistaken for a valid session.
      await _storage.write(
        key: _accessTokenKey,
        value: accessToken,
      );
      await _storage.write(
        key: _refreshTokenKey,
        value: refreshToken,
      );
    } catch (_) {
      try {
        await clear();
      } catch (_) {
        // Preserve the original secure-storage write failure.
      }
      rethrow;
    }
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveAccessToken(String accessToken) {
    if (accessToken.trim().isEmpty) {
      throw ArgumentError.value(
          accessToken, 'accessToken', 'Must not be empty.');
    }
    return _storage.write(key: _accessTokenKey, value: accessToken);
  }

  Future<void> saveRefreshToken(String refreshToken) {
    if (refreshToken.trim().isEmpty) {
      throw ArgumentError.value(
          refreshToken, 'refreshToken', 'Must not be empty.');
    }
    return _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<bool> hasSession() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return accessToken != null &&
        accessToken.isNotEmpty &&
        refreshToken != null &&
        refreshToken.isNotEmpty;
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
