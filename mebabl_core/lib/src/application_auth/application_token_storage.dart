import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MebablApplicationTokenStorage {
  static const String _accessTokenKey = 'mebabl_application_access_token';

  final FlutterSecureStorage _storage;

  MebablApplicationTokenStorage({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveToken(String accessToken) {
    return _storage.write(
      key: _accessTokenKey,
      value: accessToken,
    );
  }

  Future<String?> getToken() {
    return _storage.read(
      key: _accessTokenKey,
    );
  }

  Future<void> clear() {
    return _storage.delete(
      key: _accessTokenKey,
    );
  }
}
