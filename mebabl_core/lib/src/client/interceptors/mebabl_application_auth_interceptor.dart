import 'package:dio/dio.dart';

import '../../application_auth/application_auth_service.dart';
import '../../errors/mebabl_exception.dart';
import '../mebabl_auth_mode.dart';
import '../mebabl_http_client.dart';

/// Attaches the public Application JWT only when a request explicitly asks
/// for [MebablAuthMode.application].
class MebablApplicationAuthInterceptor extends Interceptor {
  static const String _retriedExtraKey = 'mebabl.applicationAuthRetried';

  final MebablApplicationAuthService applicationAuth;
  final Dio dio;

  MebablApplicationAuthInterceptor({
    required this.applicationAuth,
    required this.dio,
  });

  bool _requiresApplicationToken(RequestOptions options) {
    return options.extra[MebablHttpClient.authModeExtraKey] ==
        MebablAuthMode.application;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_requiresApplicationToken(options)) {
      handler.next(options);
      return;
    }

    try {
      final token = await applicationAuth.getValidApplicationToken();
      options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    } catch (error) {
      handler.reject(_asDioException(error, options));
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final shouldRetry = _requiresApplicationToken(options) &&
        err.response?.statusCode == 401 &&
        options.extra[_retriedExtraKey] != true &&
        options.data is! FormData;

    if (!shouldRetry) {
      handler.next(err);
      return;
    }

    final authorization = options.headers['Authorization']?.toString();
    final rejectedToken = authorization?.replaceFirst(
      RegExp(r'^Bearer\s+', caseSensitive: false),
      '',
    );

    try {
      final newToken = await applicationAuth.refreshAfterUnauthorized(
        rejectedToken: rejectedToken,
      );

      options.headers['Authorization'] = 'Bearer $newToken';
      options.extra[_retriedExtraKey] = true;

      final response = await dio.fetch<dynamic>(options);
      handler.resolve(response);
    } catch (retryError) {
      handler.next(_asDioException(retryError, options));
    }
  }

  DioException _asDioException(Object error, RequestOptions options) {
    if (error is DioException) return error;

    return DioException(
      requestOptions: options,
      error: error,
      message: error is MebablException
          ? error.message
          : 'Application authentication failed.',
      type: DioExceptionType.unknown,
    );
  }
}
