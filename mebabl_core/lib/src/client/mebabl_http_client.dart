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
        baseUrl: config.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['X-Application-Id'] = config.applicationId;

    options.headers['X-Api-Key'] = config.apiKey;

    handler.next(options);
  }

  void _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) {
    handler.next(error);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
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

  // 
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
// 

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
      );
    } on DioException catch (error) {
      throw _mapException(error);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
      );
    } on DioException catch (error) {
      throw _mapException(error);
    }
  }

  MebablException _mapException(
    DioException error,
  ) {
    final statusCode = error.response?.statusCode;

    final responseData = error.response?.data;

    String message = 'An unexpected error occurred.';

    if (responseData is Map<String, dynamic>) {
      final serverMessage = responseData['message'];

      if (serverMessage is String && serverMessage.isNotEmpty) {
        message = serverMessage;
      } else {
        final title = responseData['title'];

        if (title is String && title.isNotEmpty) {
          message = title;
        }
      }
    } else if (error.message != null && error.message!.isNotEmpty) {
      message = error.message!;
    }

    return MebablException(
      message: message,
      statusCode: statusCode,
      data: responseData,
    );
  }
}
