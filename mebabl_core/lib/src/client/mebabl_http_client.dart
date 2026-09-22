// lib/src/client/mebabl_http_client.dart

import 'package:dio/dio.dart';

import '../auth/token_storage.dart';
import '../config/mebabl_config.dart';
import '../errors/mebabl_exception.dart';

class MebablHttpClient {
  final MebablConfig config;
  final MebablTokenStorage tokenStorage;

  late final Dio _dio;

  MebablHttpClient({
    required this.config,
    MebablTokenStorage? tokenStorage,
  }) : tokenStorage = tokenStorage ?? MebablTokenStorage() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _normalizeBaseUrl(config.baseUrl),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: (response, handler) {
          print(
            '[Mebabl HTTP] RESPONSE '
            '${response.requestOptions.method} '
            '${response.requestOptions.uri} '
            '→ ${response.statusCode}',
          );

          print(
            '[Mebabl HTTP] RESPONSE DATA '
            '${response.data}',
          );

          handler.next(response);
        },
        onError: (error, handler) {
          print(
            '[Mebabl HTTP] ERROR '
            '${error.requestOptions.method} '
            '${error.requestOptions.uri} '
            '→ ${error.response?.statusCode}',
          );

          print(
            '[Mebabl HTTP] ERROR DATA '
            '${error.response?.data}',
          );

          print(
            '[Mebabl HTTP] ERROR MESSAGE '
            '${error.message}',
          );

          handler.next(error);
        },
      ),
    );
  }

  String _normalizeBaseUrl(String value) {
    return value.trim().replaceFirst(RegExp(r'/+$'), '');
  }

  Dio get dio => _dio;

  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  void removeInterceptor(Interceptor interceptor) {
    _dio.interceptors.remove(interceptor);
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['X-Application-Id'] = config.applicationId;
    options.headers['X-Api-Key'] = config.apiKey;
    options.headers['X-Platform-Id'] = config.platformId;

    print(
      '[Mebabl HTTP] REQUEST '
      '${options.method} '
      '${options.uri}',
    );

    print(
      '[Mebabl HTTP] REQUEST HEADERS '
      '${_safeHeaders(options.headers)}',
    );

    print(
      '[Mebabl HTTP] REQUEST BODY '
      '${options.data}',
    );

    handler.next(options);
  }

  Map<String, dynamic> _safeHeaders(Map<String, dynamic> headers) {
    final result = Map<String, dynamic>.from(headers);

    if (result.containsKey('Authorization')) {
      result['Authorization'] = 'Bearer ***';
    }

    if (result.containsKey('X-Api-Key')) {
      result['X-Api-Key'] = '***';
    }

    return result;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
          responseType: responseType,
        ),
      );
    } on DioException catch (error) {
      throw _mapException(error);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
          responseType: responseType,
        ),
      );
    } on DioException catch (error) {
      throw _mapException(error);
    }
  }

  Future<Response<T>> postMultipart<T>(
    String path, {
    required FormData data,
    Map<String, dynamic>? headers,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            ...?headers,
          },
        ),
      );
    } on DioException catch (error) {
      throw _mapException(error);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
          responseType: responseType,
        ),
      );
    } on DioException catch (error) {
      throw _mapException(error);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
          responseType: responseType,
        ),
      );
    } on DioException catch (error) {
      throw _mapException(error);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
          responseType: responseType,
        ),
      );
    } on DioException catch (error) {
      throw _mapException(error);
    }
  }

  Future<Response<T>> postUrl<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
  }) async {
    try {
      return await _dio.post<T>(
        url,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
          responseType: responseType,
        ),
      );
    } on DioException catch (error) {
      throw _mapException(error);
    }
  }

  MebablException _mapException(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    String message = 'An unexpected error occurred.';

    if (responseData is Map) {
      final serverMessage = responseData['message'];

      if (serverMessage is String && serverMessage.trim().isNotEmpty) {
        message = serverMessage;
      } else {
        final title = responseData['title'];

        if (title is String && title.trim().isNotEmpty) {
          message = title;
        }
      }
    } else if (error.message != null && error.message!.trim().isNotEmpty) {
      message = error.message!;
    }

    return MebablException(
      message: message,
      statusCode: statusCode,
      data: responseData,
    );
  }
}
