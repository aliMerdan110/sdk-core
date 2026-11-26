import 'package:dio/dio.dart';

import '../auth/token_storage.dart';
import '../config/mebabl_config.dart';
import '../errors/mebabl_exception.dart';
import 'mebabl_auth_mode.dart';

/// Shared Dio client used by the Mebabl SDK packages.
///
/// Every request defaults to [MebablAuthMode.none]. Callers must explicitly
/// choose `application` or `user` for protected endpoints. This prevents an
/// Application JWT from being sent to user endpoints, or vice versa.
class MebablHttpClient {
  static const String authModeExtraKey = 'mebabl.authMode';

  final MebablConfig config;
  final MebablTokenStorage tokenStorage;
  late final Dio _dio;

  MebablHttpClient({
    required this.config,
    MebablTokenStorage? tokenStorage,
    Dio? dio,
  }) : tokenStorage = tokenStorage ?? MebablTokenStorage() {
    _dio = dio ?? Dio();
    _dio.options
      ..baseUrl = config.baseUrl
      ..connectTimeout = const Duration(seconds: 15)
      ..receiveTimeout = const Duration(seconds: 30)
      ..sendTimeout = const Duration(seconds: 30)
      ..headers.addAll(const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      });

    // Never inherit a static Authorization header from an injected Dio client.
    _dio.options.headers.remove('Authorization');

    // These are public application/platform identifiers, not credentials.
    _dio.options.headers['X-Application-Id'] = config.applicationId;
    _dio.options.headers['X-Platform-Id'] = config.platformId;
  }

  Dio get dio => _dio;

  void addInterceptor(Interceptor interceptor) {
    if (!_dio.interceptors.contains(interceptor)) {
      _dio.interceptors.add(interceptor);
    }
  }

  void removeInterceptor(Interceptor interceptor) {
    _dio.interceptors.remove(interceptor);
  }

  Options _buildOptions({
    required MebablAuthMode authMode,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
    String? contentType,
    Map<String, dynamic>? extra,
  }) {
    return Options(
      headers: headers,
      responseType: responseType,
      contentType: contentType,
      extra: {
        ...?extra,
        authModeExtraKey: authMode,
      },
    );
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
    MebablAuthMode authMode = MebablAuthMode.none,
    CancelToken? cancelToken,
  }) {
    return _execute<T>(() => _dio.get<T>(
          path,
          queryParameters: queryParameters,
          cancelToken: cancelToken,
          options: _buildOptions(
            authMode: authMode,
            headers: headers,
            responseType: responseType,
          ),
        ));
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
    MebablAuthMode authMode = MebablAuthMode.none,
    CancelToken? cancelToken,
  }) {
    return _execute<T>(() => _dio.post<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          cancelToken: cancelToken,
          options: _buildOptions(
            authMode: authMode,
            headers: headers,
            responseType: responseType,
          ),
        ));
  }

  Future<Response<T>> postMultipart<T>(
    String path, {
    required FormData data,
    Map<String, dynamic>? headers,
    MebablAuthMode authMode = MebablAuthMode.none,
    CancelToken? cancelToken,
  }) {
    return _execute<T>(() => _dio.post<T>(
          path,
          data: data,
          cancelToken: cancelToken,
          options: _buildOptions(
            authMode: authMode,
            contentType: 'multipart/form-data',
            headers: headers,
          ),
        ));
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
    MebablAuthMode authMode = MebablAuthMode.none,
    CancelToken? cancelToken,
  }) {
    return _execute<T>(() => _dio.put<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          cancelToken: cancelToken,
          options: _buildOptions(
            authMode: authMode,
            headers: headers,
            responseType: responseType,
          ),
        ));
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
    MebablAuthMode authMode = MebablAuthMode.none,
    CancelToken? cancelToken,
  }) {
    return _execute<T>(() => _dio.patch<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          cancelToken: cancelToken,
          options: _buildOptions(
            authMode: authMode,
            headers: headers,
            responseType: responseType,
          ),
        ));
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
    MebablAuthMode authMode = MebablAuthMode.none,
    CancelToken? cancelToken,
  }) {
    return _execute<T>(() => _dio.delete<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          cancelToken: cancelToken,
          options: _buildOptions(
            authMode: authMode,
            headers: headers,
            responseType: responseType,
          ),
        ));
  }

  /// Sends a POST request to an absolute or relative URL.
  ///
  /// This is useful for an external upload target. Authentication is still
  /// `none` unless the caller explicitly selects another mode.
  Future<Response<T>> postUrl<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
    MebablAuthMode authMode = MebablAuthMode.none,
    CancelToken? cancelToken,
  }) {
    return _execute<T>(() => _dio.post<T>(
          url,
          data: data,
          queryParameters: queryParameters,
          cancelToken: cancelToken,
          options: _buildOptions(
            authMode: authMode,
            headers: headers,
            responseType: responseType,
          ),
        ));
  }

  Future<Response<T>> _execute<T>(
    Future<Response<T>> Function() operation,
  ) async {
    try {
      return await operation();
    } on DioException catch (error) {
      throw _mapException(error);
    }
  }

  MebablException _mapException(DioException error) {
    final nested = error.error;
    if (nested is MebablException) return nested;

    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;
    final message = _extractServerMessage(responseData) ??
        _defaultMessage(error, statusCode);

    return MebablException(
      message: message,
      statusCode: statusCode,
      data: responseData,
      code: error.type.name,
      requestPath: error.requestOptions.path,
      cause: nested,
    );
  }

  String? _extractServerMessage(dynamic responseData) {
    if (responseData is Map) {
      final message = responseData['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }

      final title = responseData['title'];
      if (title is String && title.trim().isNotEmpty) {
        return title.trim();
      }
    }

    return null;
  }

  String _defaultMessage(DioException error, int? statusCode) {
    if (statusCode != null) {
      if (statusCode == 429) {
        return 'Too many requests. Please try again later.';
      }
      if (statusCode >= 500) {
        return 'The server could not complete the request.';
      }
      return 'The request failed with status $statusCode.';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'The connection timed out.';
      case DioExceptionType.sendTimeout:
        return 'Sending the request timed out.';
      case DioExceptionType.receiveTimeout:
        return 'Receiving the response timed out.';
      case DioExceptionType.connectionError:
        return 'Could not connect to the Mebabl server.';
      case DioExceptionType.cancel:
        return 'The request was cancelled.';
      case DioExceptionType.badCertificate:
        return 'The server certificate could not be trusted.';
      case DioExceptionType.badResponse:
        return 'The server returned an invalid response.';
      case DioExceptionType.unknown:
        return 'A network or unexpected communication error occurred.';
      default:
        return 'A network or unexpected communication error occurred.';
    }
  }

  void close({bool force = false}) {
    _dio.close(force: force);
  }
}
