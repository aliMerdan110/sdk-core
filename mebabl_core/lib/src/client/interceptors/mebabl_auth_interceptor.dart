import 'package:dio/dio.dart';

class MebablAuthInterceptor extends Interceptor {
  // دالة تُمرر من الخارج لجلب التوكن الصالح دون الحاجة لمعرفة تفاصيل الـ Auth
  final Future<String?> Function() getValidAccessToken;

  MebablAuthInterceptor({
    required this.getValidAccessToken,
  });

  bool _isAuthenticationEndpoint(String path) {
    return path == '/api/application-auth/token' ||
        path == '/api/sdk/auth/login' ||
        path == '/api/sdk/auth/refresh';
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // مسارات المصادقة لا تحتاج إلى توكن
      if (_isAuthenticationEndpoint(options.path)) {
        handler.next(options);
        return;
      }

      final accessToken = await getValidAccessToken();

      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }

      handler.next(options);
    } catch (e) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: e,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
