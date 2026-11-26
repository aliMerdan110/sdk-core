import 'package:dio/dio.dart';

import '../../errors/mebabl_exception.dart';
import '../mebabl_auth_mode.dart';
import '../mebabl_http_client.dart';

/// Attaches a User JWT supplied by `mebabl_auth` to user-protected requests.
///
/// Refresh-token rotation remains the responsibility of `mebabl_auth`; this
/// interceptor only asks its provider for a valid access token.
class MebablAuthInterceptor extends Interceptor {
  final Future<String?> Function() getValidAccessToken;

  MebablAuthInterceptor({
    required this.getValidAccessToken,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final mode = options.extra[MebablHttpClient.authModeExtraKey];
    if (mode != MebablAuthMode.user) {
      handler.next(options);
      return;
    }

    try {
      final accessToken = await getValidAccessToken();
      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const MebablException(
          message: 'A signed-in user session is required.',
          statusCode: 401,
        );
      }

      options.headers['Authorization'] = 'Bearer $accessToken';
      handler.next(options);
    } catch (error) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          message: error is MebablException
              ? error.message
              : 'User authentication failed.',
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
