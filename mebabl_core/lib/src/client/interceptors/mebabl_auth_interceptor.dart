// lib/src/client/interceptors/mebabl_auth_interceptor.dart

import 'package:dio/dio.dart';

class MebablAuthInterceptor extends Interceptor {
  final Future<String?> Function() getValidAccessToken;

  MebablAuthInterceptor({
    required this.getValidAccessToken,
  });

  bool _isAuthenticationEndpoint(String path) {
    return path == '/api/application-auth/token' ||
        path == '/api/sdk/auth/register' ||
        path == '/api/sdk/auth/login' ||
        path == '/api/sdk/auth/refresh' ||
        path == '/api/sdk/auth/logout' ||
        path == '/api/sdk/auth/forgot-password' ||
        path == '/api/sdk/auth/reset-password' ||
        path == '/api/sdk/auth/verify-email' ||
        path == '/api/sdk/auth/resend-verification-email';
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isAuthenticationEndpoint(options.path)) {
      print(
        '[MebablAuthInterceptor] AUTH ENDPOINT BYPASS: '
        '${options.method} ${options.uri}',
      );

      handler.next(options);
      return;
    }

    try {
      final accessToken = await getValidAccessToken();

      print(
        '[MebablAuthInterceptor] REQUEST: '
        '${options.method} ${options.uri}',
      );

      print(
        '[MebablAuthInterceptor] TOKEN: '
        '${accessToken == null || accessToken.isEmpty ? 'NULL' : 'AVAILABLE'}',
      );

      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';

        print(
          '[MebablAuthInterceptor] AUTHORIZATION ATTACHED',
        );
      } else {
        print(
          '[MebablAuthInterceptor] NO ACCESS TOKEN',
        );
      }

      handler.next(options);
    } catch (error) {
      print(
        '[MebablAuthInterceptor] ERROR: $error',
      );

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
