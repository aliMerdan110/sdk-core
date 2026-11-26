import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage dedicated to the limited public Application JWT.
class MebablApplicationTokenStorage {
  static const String _accessTokenKey =
      'mebabl_public_application_access_token';

  final FlutterSecureStorage _storage;

  MebablApplicationTokenStorage({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveToken(String accessToken) {
    if (accessToken.trim().isEmpty) {
      throw ArgumentError.value(
          accessToken, 'accessToken', 'Must not be empty.');
    }
    return _storage.write(key: _accessTokenKey, value: accessToken);
  }

  Future<String?> getToken() => _storage.read(key: _accessTokenKey);

  Future<void> clear() => _storage.delete(key: _accessTokenKey);
}
