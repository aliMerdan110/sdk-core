import '../client/mebabl_http_client.dart';
import '../config/mebabl_config.dart';
import '../errors/mebabl_exception.dart';
import 'application_token_storage.dart';

class MebablApplicationAuthService {
  final MebablConfig config;
  final MebablHttpClient http;
  final MebablApplicationTokenStorage tokenStorage;

  MebablApplicationAuthService({
    required this.config,
    required this.http,
    required this.tokenStorage,
  });

  Future<String> getValidApplicationToken() async {
    final token = await tokenStorage.getToken();

    if (token != null && token.isNotEmpty) {
      return token;
    }

    return authenticate();
  }

  Future<String> authenticate() async {
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
        message: 'Invalid application authentication response.',
      );
    }

    final accessToken = data['accessToken']?.toString();

    if (accessToken == null || accessToken.isEmpty) {
      throw const MebablException(
        message:
            'Application authentication response does not contain an access token.',
      );
    }

    await tokenStorage.saveToken(accessToken);

    return accessToken;
  }

  Future<void> clear() {
    return tokenStorage.clear();
  }
}
