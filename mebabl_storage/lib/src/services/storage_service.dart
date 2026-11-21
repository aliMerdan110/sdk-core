import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:mebabl_core/mebabl_core.dart';

import '../models/storage_content_stream.dart';
import '../models/storage_object_page.dart';
import '../models/stored_file.dart';

/// Reports the number of bytes sent and the total request bytes.
typedef MebablStorageUploadProgressCallback =
    void Function(int sentBytes, int totalBytes);

/// Project-scoped object storage operations for an authenticated Mebabl app.
///
/// Upload and delete always use the Application User JWT. Object listing,
/// content URL resolution, and content retrieval can be requested with or
/// without a User JWT; the backend evaluates the published Storage Security
/// Rules for every operation. This SDK never decides whether an object is
/// public and never sends storage provider keys or physical storage keys.
class MebablStorageService {
  static const String basePath = '/api/sdk/storage';
  static const int maximumUploadBytes = 50 * 1024 * 1024;
  static const int maximumFileNameLength = 255;
  static const int maximumPathLength = 1024;
  static const int maximumPageSize = 100;

  final MebablCore core;

  const MebablStorageService({required this.core});

  /// Uploads a local file into the selected project bucket.
  ///
  /// [path] is a bucket-relative directory, not a complete object path. The
  /// backend appends [fileName] to it. When [bucketId] is omitted, the
  /// project's default bucket is used.
  ///
  /// Uploads are limited to 50 MiB by the current Storage V2 API. The server
  /// validates the actual content and Storage Security Rules independently.
  Future<MebablStoredFile> uploadFile({
    required String filePath,
    String? fileName,
    String? bucketId,
    String? path,
    String? contentType,
    MebablStorageUploadProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    final normalizedFilePath = filePath.trim();
    if (normalizedFilePath.isEmpty) {
      throw ArgumentError.value(
        filePath,
        'filePath',
        'A file path is required.',
      );
    }

    final resolvedName = _resolveFileName(normalizedFilePath, fileName);
    final normalizedPath = _normalizeDirectoryPath(path);
    final normalizedBucketId = _normalizeOptionalGuid(bucketId, 'bucketId');
    final normalizedContentType =
        _resolveContentType(resolvedName, contentType);

    final multipartFile = await MultipartFile.fromFile(
      normalizedFilePath,
      filename: resolvedName,
      contentType: MediaType.parse(normalizedContentType),
    );
    _validateFileSize(multipartFile.length);

    return _upload(
      file: multipartFile,
      bucketId: normalizedBucketId,
      path: normalizedPath,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
    );
  }

  /// Uploads bytes without requiring a file-picker dependency.
  ///
  /// This method is suitable for Flutter Web and in-memory generated files.
  Future<MebablStoredFile> uploadBytes({
    required List<int> bytes,
    required String fileName,
    String? bucketId,
    String? path,
    String? contentType,
    MebablStorageUploadProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    if (bytes.isEmpty) {
      throw ArgumentError.value(bytes, 'bytes', 'The uploaded file is empty.');
    }
    _validateFileSize(bytes.length);

    final normalizedName = _validateFileName(fileName);
    final normalizedPath = _normalizeDirectoryPath(path);
    final normalizedBucketId = _normalizeOptionalGuid(bucketId, 'bucketId');
    final normalizedContentType =
        _resolveContentType(normalizedName, contentType);

    final multipartFile = MultipartFile.fromBytes(
      bytes,
      filename: normalizedName,
      contentType: MediaType.parse(normalizedContentType),
    );

    return _upload(
      file: multipartFile,
      bucketId: normalizedBucketId,
      path: normalizedPath,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
    );
  }

  /// Lists objects the caller is authorized to enumerate in [bucketId].
  ///
  /// [prefix] is a bucket-relative directory prefix. The backend applies the
  /// Storage `list` operation to the requested prefix and checks each
  /// returned object independently, so unauthorized object metadata is not
  /// included in the page. Public listing requires a published `public`
  /// Storage rule; pass [authenticated] as false to avoid explicitly selecting
  /// the User JWT mode.
  Future<MebablStorageObjectPage> listObjects({
    required String bucketId,
    String? prefix,
    int page = 1,
    int pageSize = 50,
    bool authenticated = true,
    CancelToken? cancelToken,
  }) async {
    final id = _requireGuid(bucketId, 'bucketId');
    if (page < 1) {
      throw ArgumentError.value(page, 'page', 'Page must be at least 1.');
    }
    if (pageSize < 1 || pageSize > maximumPageSize) {
      throw ArgumentError.value(
        pageSize,
        'pageSize',
        'Page size must be between 1 and $maximumPageSize.',
      );
    }

    final normalizedPrefix = _normalizePrefix(prefix);
    try {
      final response = await core.http.dio.get<Object?>(
        '$basePath/buckets/$id/objects',
        queryParameters: {
          if (normalizedPrefix.isNotEmpty) 'prefix': normalizedPrefix,
          'page': page,
          'pageSize': pageSize,
        },
        cancelToken: cancelToken,
        options: _options(authenticated: authenticated),
      );

      return MebablStorageObjectPage.fromJson(_requireMap(response.data));
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  /// Requests the canonical content URL after the server authorizes `get`.
  ///
  /// The URL is resolved against [MebablCore]'s configured base URL. A URL is
  /// not a permanent authorization grant: the content endpoint re-evaluates
  /// Storage Security Rules when it is requested.
  Future<Uri> getDownloadUrl({
    required String fileId,
    bool authenticated = true,
    CancelToken? cancelToken,
  }) async {
    final id = _requireGuid(fileId, 'fileId');
    try {
      final response = await core.http.dio.get<Object?>(
        '$basePath/$id/url',
        cancelToken: cancelToken,
        options: _options(authenticated: authenticated),
      );
      final data = _requireMap(response.data);
      final rawUrl = data['url'];
      if (rawUrl is! String || rawUrl.trim().isEmpty) {
        throw const FormatException('The Storage URL response is invalid.');
      }
      return resolveUrl(rawUrl);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  /// Resolves a relative API content URL against the configured API base URL.
  Uri resolveUrl(String contentUrl) {
    final normalized = contentUrl.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        contentUrl,
        'contentUrl',
        'A content URL is required.',
      );
    }

    final uri = Uri.parse(normalized);
    if (uri.hasScheme) {
      if (uri.scheme != 'http' && uri.scheme != 'https') {
        throw ArgumentError.value(
          contentUrl,
          'contentUrl',
          'Only HTTP and HTTPS content URLs are supported.',
        );
      }
      return uri;
    }

    return Uri.parse(core.config.baseUrl).resolve(normalized);
  }

  /// Downloads an object into memory.
  ///
  /// Use [openRead] for large files to avoid buffering the entire response.
  /// [range] accepts HTTP byte ranges such as `bytes=0-1023`.
  Future<Uint8List> downloadFile({
    required String fileId,
    String? range,
    bool authenticated = true,
    CancelToken? cancelToken,
  }) async {
    final id = _requireGuid(fileId, 'fileId');
    final normalizedRange = _validateRange(range);

    try {
      final response = await core.http.dio.get<List<int>>(
        '$basePath/$id/content',
        cancelToken: cancelToken,
        options: _options(
          authenticated: authenticated,
          responseType: ResponseType.bytes,
          headers: normalizedRange == null
              ? null
              : {'Range': normalizedRange},
        ),
      );

      final data = response.data;
      return data == null ? Uint8List(0) : Uint8List.fromList(data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  /// Opens the object content as a stream for large files.
  Future<MebablStorageContentStream> openRead({
    required String fileId,
    String? range,
    bool authenticated = true,
    CancelToken? cancelToken,
  }) async {
    final id = _requireGuid(fileId, 'fileId');
    final normalizedRange = _validateRange(range);

    try {
      final response = await core.http.dio.get<ResponseBody>(
        '$basePath/$id/content',
        cancelToken: cancelToken,
        options: _options(
          authenticated: authenticated,
          responseType: ResponseType.stream,
          receiveTimeout: Duration.zero,
          headers: normalizedRange == null
              ? null
              : {'Range': normalizedRange},
        ),
      );

      final body = response.data;
      if (body == null) {
        throw MebablException(
          message: 'The Storage endpoint returned an empty stream.',
          statusCode: response.statusCode,
          requestPath: '$basePath/$id/content',
        );
      }

      return MebablStorageContentStream(
        stream: body.stream,
        contentType: response.headers.value(Headers.contentTypeHeader),
        contentLength: int.tryParse(
          response.headers.value(Headers.contentLengthHeader) ?? '',
        ),
        contentRange: response.headers.value('content-range'),
        statusCode: response.statusCode ?? 200,
      );
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  /// Deletes an object using the Application User JWT.
  ///
  /// The backend rejects deletion while an object is referenced by a Post or
  /// Chat attachment. Such conflicts are returned as [MebablException] and
  /// should be handled by the caller rather than bypassed in the SDK.
  Future<void> delete({
    required String fileId,
    CancelToken? cancelToken,
  }) async {
    final id = _requireGuid(fileId, 'fileId');
    try {
      await core.http.dio.delete<void>(
        '$basePath/$id',
        cancelToken: cancelToken,
        options: _options(authenticated: true),
      );
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<MebablStoredFile> _upload({
    required MultipartFile file,
    required String? bucketId,
    required String path,
    required MebablStorageUploadProgressCallback? onSendProgress,
    required CancelToken? cancelToken,
  }) async {
    final formFields = <String, dynamic>{'file': file};
    if (path.isNotEmpty) formFields['path'] = path;
    if (bucketId != null) formFields['bucketId'] = bucketId;

    final formData = FormData.fromMap(formFields);
    try {
      final response = await core.http.dio.post<Object?>(
        '$basePath/upload',
        data: formData,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        options: _options(
          authenticated: true,
          contentType: Headers.multipartFormDataContentType,
        ),
      );

      return MebablStoredFile.fromJson(_requireMap(response.data));
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Options _options({
    required bool authenticated,
    ResponseType? responseType,
    Map<String, dynamic>? headers,
    String? contentType,
    Duration? receiveTimeout,
  }) {
    return Options(
      responseType: responseType,
      headers: headers,
      contentType: contentType,
      receiveTimeout: receiveTimeout,
      extra: {
        if (authenticated)
          MebablHttpClient.authModeExtraKey: MebablAuthMode.user,
      },
    );
  }

  String _resolveFileName(String filePath, String? suppliedName) {
    final candidate = suppliedName?.trim().isNotEmpty == true
        ? suppliedName!.trim()
        : filePath.replaceAll('\\', '/').split('/').last;
    return _validateFileName(candidate);
  }

  String _validateFileName(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty ||
        normalized.length > maximumFileNameLength ||
        normalized.contains('/') ||
        normalized.contains('\\') ||
        normalized == '.' ||
        normalized == '..' ||
        normalized.codeUnits.any((unit) => unit < 32 || unit == 127)) {
      throw ArgumentError.value(value, 'fileName', 'The file name is invalid.');
    }
    return normalized;
  }

  String _normalizeDirectoryPath(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    final candidate = value.trim().replaceAll('\\', '/');
    if (candidate.length > maximumPathLength ||
        candidate.contains('\u0000') ||
        candidate.startsWith('/') ||
        candidate.startsWith('~/') ||
        (candidate.length >= 2 &&
            RegExp(r'^[A-Za-z]:').hasMatch(candidate))) {
      throw ArgumentError.value(value, 'path', 'The Storage path is invalid.');
    }

    final segments = candidate
        .split('/')
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (segments.isEmpty ||
        segments.any((segment) =>
            segment == '.' ||
            segment == '..' ||
            segment.codeUnits.any((unit) => unit < 32 || unit == 127))) {
      throw ArgumentError.value(value, 'path', 'The Storage path is invalid.');
    }

    final normalized = segments.join('/');
    if (normalized.length + 1 > maximumPathLength) {
      throw ArgumentError.value(value, 'path', 'The Storage path is too long.');
    }
    return normalized;
  }

  String _normalizePrefix(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    final rawCandidate = value.trim().replaceAll('\\', '/');
    if (rawCandidate.length > maximumPathLength ||
        rawCandidate.contains('\u0000') ||
        rawCandidate.startsWith('/') ||
        rawCandidate.startsWith('~') ||
        (rawCandidate.length >= 2 &&
            RegExp(r'^[A-Za-z]:').hasMatch(rawCandidate))) {
      throw ArgumentError.value(
        value,
        'prefix',
        'The Storage prefix is invalid.',
      );
    }

    final candidate = rawCandidate.replaceAll(RegExp(r'/+$'), '');
    if (candidate.isEmpty) {
      throw ArgumentError.value(
        value,
        'prefix',
        'The Storage prefix is invalid.',
      );
    }

    final segments = candidate
        .split('/')
        .map((segment) => segment.trim())
        .toList();
    if (segments.any((segment) =>
        segment.isEmpty ||
        segment == '.' ||
        segment == '..' ||
        segment.codeUnits.any((unit) => unit < 32 || unit == 127))) {
      throw ArgumentError.value(
        value,
        'prefix',
        'The Storage prefix is invalid.',
      );
    }
    return segments.join('/');
  }

  String? _normalizeOptionalGuid(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return null;
    return _requireGuid(value, fieldName);
  }

  String _requireGuid(String value, String fieldName) {
    final normalized = value.trim();
    final guidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (!guidPattern.hasMatch(normalized)) {
      throw ArgumentError.value(value, fieldName, 'A valid GUID is required.');
    }
    return normalized;
  }

  String _resolveContentType(String fileName, String? supplied) {
    if (supplied != null && supplied.trim().isNotEmpty) {
      return _normalizeContentType(supplied);
    }
    final detected = lookupMimeType(fileName) ?? 'application/octet-stream';
    return _normalizeContentType(detected);
  }

  String _normalizeContentType(String value) {
    final normalized = value.trim().toLowerCase();
    if (!RegExp(
      r'^[a-z0-9!#$&^_.+-]+/[a-z0-9!#$&^_.+-]+$',
    ).hasMatch(normalized)) {
      throw ArgumentError.value(
        value,
        'contentType',
        'A valid MIME content type is required, e.g. image/jpeg.',
      );
    }
    return normalized;
  }

  void _validateFileSize(int size) {
    if (size <= 0 || size > maximumUploadBytes) {
      throw ArgumentError.value(
        size,
        'fileSize',
        'Storage uploads must be between 1 byte and 50 MiB.',
      );
    }
  }

  String? _validateRange(String? value) {
    if (value == null) return null;
    final normalized = value.trim();
    if (!RegExp(r'^bytes=\d*-\d*$').hasMatch(normalized) ||
        normalized == 'bytes=-') {
      throw ArgumentError.value(
        value,
        'range',
        'Use a valid HTTP byte range, e.g. bytes=0-1023.',
      );
    }
    return normalized;
  }

  Map<String, dynamic> _requireMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException(
      'The Storage endpoint returned an invalid response.',
    );
  }

  MebablException _mapDioException(DioException error) {
    final nested = error.error;
    if (nested is MebablException) return nested;

    final data = _decodeErrorData(error.response?.data);
    final statusCode = error.response?.statusCode;
    final message =
        _extractMessage(data) ?? _fallbackMessage(error, statusCode);

    return MebablException(
      message: message,
      statusCode: statusCode,
      data: data,
      code: error.type.name,
      requestPath: error.requestOptions.path,
      cause: nested ?? error,
    );
  }

  Object? _decodeErrorData(Object? data) {
    final text = data is List<int>
        ? utf8.decode(data, allowMalformed: true)
        : data is String
            ? data
            : null;
    if (text == null) return data;
    try {
      return jsonDecode(text);
    } on FormatException {
      return text;
    }
  }

  String? _extractMessage(Object? data) {
    if (data is! Map) return null;
    for (final key in const ['message', 'title', 'error', 'detail']) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  String _fallbackMessage(DioException error, int? statusCode) {
    if (statusCode != null) {
      if (statusCode == 401) {
        return 'Authentication is required for this Storage operation.';
      }
      if (statusCode == 403) {
        return 'Storage Security Rules denied this operation.';
      }
      if (statusCode == 404) {
        return 'The Storage object or bucket was not found.';
      }
      if (statusCode == 409) {
        return 'Cannot delete a file still referenced by content.';
      }
      if (statusCode == 413) {
        return 'The Storage upload exceeds the 50 MiB limit.';
      }
      if (statusCode == 429) {
        return 'Too many Storage requests. Please try again later.';
      }
      if (statusCode >= 500) {
        return 'The server could not complete the Storage request.';
      }
      return 'The Storage request failed with status $statusCode.';
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout =>
        'The connection to Mebabl timed out.',
      DioExceptionType.sendTimeout => 'Sending the Storage request timed out.',
      DioExceptionType.receiveTimeout =>
        'Receiving the Storage response timed out.',
      DioExceptionType.connectionError =>
        'Could not connect to the Mebabl server.',
      DioExceptionType.cancel => 'The Storage request was cancelled.',
      DioExceptionType.badCertificate =>
        'The server certificate could not be trusted.',
      DioExceptionType.badResponse =>
        'The server returned an invalid Storage response.',
      DioExceptionType.transformTimeout =>
        'Processing the Storage response timed out.',
      DioExceptionType.unknown =>
        'A network or unexpected Storage error occurred.',
    };
  }
}
