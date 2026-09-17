import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
    await Future.wait([
      _storage.write(
        key: _accessTokenKey,
        value: accessToken,
      ),
      _storage.write(
        key: _refreshTokenKey,
        value: refreshToken,
      ),
    ]);
  }

  Future<String?> getAccessToken() {
    return _storage.read(
      key: _accessTokenKey,
    );
  }

  Future<String?> getRefreshToken() {
    return _storage.read(
      key: _refreshTokenKey,
    );
  }

  Future<void> saveAccessToken(String accessToken) {
    return _storage.write(
      key: _accessTokenKey,
      value: accessToken,
    );
  }

  Future<void> saveRefreshToken(String refreshToken) {
    return _storage.write(
      key: _refreshTokenKey,
      value: refreshToken,
    );
  }

  Future<bool> hasSession() async {
    final refreshToken = await getRefreshToken();

    return refreshToken != null && refreshToken.isNotEmpty;
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }
}
