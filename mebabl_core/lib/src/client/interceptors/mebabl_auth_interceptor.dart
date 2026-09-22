import 'package:dio/dio.dart';

class MebablAuthInterceptor extends Interceptor {
  final Future<String?> Function() getValidAccessToken;

  MebablAuthInterceptor({
    required this.getValidAccessToken,
  });

  /// Endpoints that do not require a User JWT.
  ///
  /// Application-authenticated endpoints are also bypassed here because
  /// MebablApplicationAuthInterceptor is responsible for attaching the
  /// Application JWT to them.
  bool _isAuthenticationEndpoint(String path) {
    return path == '/api/application-auth/token' ||
        path == '/api/sdk/auth/register' ||
        path == '/api/sdk/auth/login' ||
        path == '/api/sdk/auth/forgot-password' ||
        path == '/api/sdk/auth/refresh' ||
        path == '/api/sdk/auth/reset-password' ||
        path == '/api/sdk/auth/verify-email';
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isAuthenticationEndpoint(options.path)) {
      handler.next(options);
      return;
    }

    try {
      final accessToken = await getValidAccessToken();

      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }

      handler.next(options);
    } catch (error) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
