import 'package:dio/dio.dart';

import '../../application_auth/application_auth_service.dart';

class MebablApplicationAuthInterceptor extends Interceptor {
  final MebablApplicationAuthService applicationAuth;

  MebablApplicationAuthInterceptor({
    required this.applicationAuth,
  });

  bool _requiresApplicationToken(String path) {
    return path == '/api/sdk/auth/register' ||
        path == '/api/sdk/auth/login' ||
        path == '/api/sdk/auth/forgot-password';
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_requiresApplicationToken(options.path)) {
      handler.next(options);
      return;
    }

    try {
      final token = await applicationAuth.getValidApplicationToken();

      options.headers['Authorization'] = 'Bearer $token';

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
