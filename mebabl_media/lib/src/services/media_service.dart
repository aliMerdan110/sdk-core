import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:mebabl_core/mebabl_core.dart';

import '../models/media_asset.dart';
import '../models/media_content_stream.dart';
import '../models/media_library_page.dart';
import '../models/media_upload_result.dart';
import '../models/media_visibility.dart';
import '../models/media_visibility_result.dart';

/// Reports the number of bytes sent and the total request bytes.
typedef MebablMediaUploadProgressCallback =
    void Function(int sentBytes, int totalBytes);

/// Optionally customizes the JSON enum representation for a non-default API.
/// The current Mebabl Backend uses numeric System.Text.Json enum values.
typedef MebablMediaVisibilityJsonEncoder =
    Object Function(MebablMediaVisibility visibility);

/// Media operations for an Mebabl application.
///
/// Upload, library, details, visibility changes, and deletion require an
/// authenticated Application User. Content endpoints may be requested with
/// or without a User JWT; the backend still evaluates Media Rules and Storage
/// Rules for every original, variant, and HLS resource.
class MebablMediaService {
  static const String basePath = '/api/sdk/media';
  static const int maximumImageSizeBytes = 25 * 1024 * 1024;
  static const int maximumVideoSizeBytes = 512 * 1024 * 1024;

  static final RegExp _guidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  final MebablCore core;
  final MebablMediaVisibilityJsonEncoder? visibilityJsonEncoder;

  const MebablMediaService({required this.core, this.visibilityJsonEncoder});

  /// Uploads an image or video from a local file path.
  ///
  /// Supported formats are validated by the server using file signatures:
  /// JPEG, PNG, GIF, WebP, MP4, MOV, and WebM. Server-side limits are 25 MB
  /// for images and 512 MB for videos.
  Future<MebablMediaUploadResult> uploadFile({
    required String filePath,
    String? fileName,
    MebablMediaVisibility visibility = MebablMediaVisibility.private,
    MebablMediaUploadProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    if (filePath.trim().isEmpty) {
      throw ArgumentError.value(
        filePath,
        'filePath',
        'A file path is required.',
      );
    }

    final resolvedName = _resolveFileName(filePath, fileName);
    final multipartFile = await MultipartFile.fromFile(
      filePath,
      filename: resolvedName,
    );

    return _upload(
      file: multipartFile,
      visibility: visibility,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
    );
  }

  /// Uploads image or video bytes. This is useful with image-picker and
  /// file-picker packages, and avoids requiring this package to own a picker.
  Future<MebablMediaUploadResult> uploadBytes({
    required List<int> bytes,
    required String fileName,
    MebablMediaVisibility visibility = MebablMediaVisibility.private,
    MebablMediaUploadProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    if (bytes.isEmpty) {
      throw ArgumentError.value(bytes, 'bytes', 'The uploaded file is empty.');
    }
    final normalizedFileName = fileName.trim();
    _validateFileName(normalizedFileName);

    final multipartFile = MultipartFile.fromBytes(
      bytes,
      filename: normalizedFileName,
    );

    return _upload(
      file: multipartFile,
      visibility: visibility,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
    );
  }

  /// Returns one page from the current user's media library.
  Future<MebablMediaLibraryPage> list({
    int page = 1,
    int pageSize = 24,
    String? kind,
    String? status,
    String? visibility,
    CancelToken? cancelToken,
  }) async {
    if (page < 1) {
      throw ArgumentError.value(page, 'page', 'Must be at least 1.');
    }
    if (pageSize < 1 || pageSize > 100) {
      throw ArgumentError.value(
        pageSize,
        'pageSize',
        'Must be between 1 and 100.',
      );
    }

    final query = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      if (_hasValue(kind)) 'kind': kind!.trim(),
      if (_hasValue(status)) 'status': status!.trim(),
      if (_hasValue(visibility)) 'visibility': visibility!.trim(),
    };

    final response = await core.http.get<Map<String, dynamic>>(
      basePath,
      queryParameters: query,
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );

    return MebablMediaLibraryPage.fromJson(_requireMap(response.data));
  }

  /// Gets full metadata for one media asset.
  Future<MebablMediaAsset> get({
    required String mediaId,
    CancelToken? cancelToken,
  }) async {
    final id = _requireId(mediaId);
    final response = await core.http.get<Map<String, dynamic>>(
      '$basePath/$id',
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
    return MebablMediaAsset.fromJson(_requireMap(response.data));
  }

  /// Changes an asset to Private, Public, or Unlisted visibility.
  ///
  /// The current backend's JSON enum values are 1, 2, and 3 respectively.
  Future<MebablMediaVisibilityResult> changeVisibility({
    required String mediaId,
    required MebablMediaVisibility visibility,
    CancelToken? cancelToken,
  }) async {
    final id = _requireId(mediaId);
    final response = await core.http.patch<Map<String, dynamic>>(
      '$basePath/$id/visibility',
      data: {
        'visibility':
            visibilityJsonEncoder?.call(visibility) ?? visibility.jsonValue,
      },
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
    return MebablMediaVisibilityResult.fromJson(_requireMap(response.data));
  }

  /// Deletes an asset. The backend may reject deletion while an asset is
  /// attached to a post; the API's 409 response is exposed as MebablException.
  Future<void> delete({
    required String mediaId,
    CancelToken? cancelToken,
  }) async {
    final id = _requireId(mediaId);
    await core.http.delete<void>(
      '$basePath/$id',
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
  }

  /// Downloads the original file into memory.
  ///
  /// Prefer [openOriginalContent] for large video files to avoid buffering the
  /// entire response in memory.
  Future<Uint8List> downloadOriginal({
    required String mediaId,
    String? range,
    bool authenticated = true,
    CancelToken? cancelToken,
  }) {
    final id = _requireId(mediaId);
    return _downloadBytes(
      '$basePath/$id/content',
      range: range,
      authenticated: authenticated,
      cancelToken: cancelToken,
    );
  }

  /// Downloads one processed derivative into memory.
  Future<Uint8List> downloadVariant({
    required String mediaId,
    required String variantKind,
    String? range,
    bool authenticated = true,
    CancelToken? cancelToken,
  }) {
    final id = _requireId(mediaId);
    final kind = _requirePathSegment(variantKind, 'variantKind');
    return _downloadBytes(
      '$basePath/$id/variants/$kind/content',
      range: range,
      authenticated: authenticated,
      cancelToken: cancelToken,
    );
  }

  /// Downloads an HLS playlist or segment resource into memory.
  ///
  /// [relativePath] is the path inside the media asset's HLS directory, such
  /// as `master.m3u8` or a segment path. Parent-directory traversal is rejected.
  Future<Uint8List> downloadHlsResource({
    required String mediaId,
    required String relativePath,
    bool authenticated = true,
    CancelToken? cancelToken,
  }) {
    final id = _requireId(mediaId);
    final hlsPath = _encodeRelativePath(relativePath);
    return _downloadBytes(
      '$basePath/$id/hls/$hlsPath',
      authenticated: authenticated,
      cancelToken: cancelToken,
    );
  }

  /// Opens the original file as a stream for large video playback/downloads.
  Future<MebablMediaContentStream> openOriginalContent({
    required String mediaId,
    String? range,
    bool authenticated = true,
    CancelToken? cancelToken,
  }) {
    final id = _requireId(mediaId);
    return _openStream(
      '$basePath/$id/content',
      range: range,
      authenticated: authenticated,
      cancelToken: cancelToken,
    );
  }

  /// Opens one processed derivative as a stream.
  Future<MebablMediaContentStream> openVariantContent({
    required String mediaId,
    required String variantKind,
    String? range,
    bool authenticated = true,
    CancelToken? cancelToken,
  }) {
    final id = _requireId(mediaId);
    final kind = _requirePathSegment(variantKind, 'variantKind');
    return _openStream(
      '$basePath/$id/variants/$kind/content',
      range: range,
      authenticated: authenticated,
      cancelToken: cancelToken,
    );
  }

  /// Opens an HLS playlist or segment as a stream.
  Future<MebablMediaContentStream> openHlsResource({
    required String mediaId,
    required String relativePath,
    bool authenticated = true,
    CancelToken? cancelToken,
  }) {
    final id = _requireId(mediaId);
    final hlsPath = _encodeRelativePath(relativePath);
    return _openStream(
      '$basePath/$id/hls/$hlsPath',
      authenticated: authenticated,
      cancelToken: cancelToken,
    );
  }

  Future<MebablMediaUploadResult> _upload({
    required MultipartFile file,
    required MebablMediaVisibility visibility,
    required MebablMediaUploadProgressCallback? onSendProgress,
    required CancelToken? cancelToken,
  }) async {
    if (file.length <= 0) {
      throw ArgumentError('The uploaded file is empty.');
    }
    _validateUploadSize(file.filename ?? '', file.length);

    final formData = FormData.fromMap({
      'file': file,
      'visibility': visibility.formValue,
    });

    try {
      final response = await core.http.dio.post<Map<String, dynamic>>(
        '$basePath/upload',
        data: formData,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        options: Options(
          contentType: Headers.multipartFormDataContentType,
          extra: {MebablHttpClient.authModeExtraKey: MebablAuthMode.user},
        ),
      );

      return MebablMediaUploadResult.fromJson(_requireMap(response.data));
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<Uint8List> _downloadBytes(
    String path, {
    String? range,
    bool authenticated = true,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await core.http.dio.get<List<int>>(
        path,
        cancelToken: cancelToken,
        options: _contentOptions(
          authenticated: authenticated,
          responseType: ResponseType.bytes,
          headers: range == null ? null : {'Range': _validateRange(range)},
        ),
      );

      final data = response.data;
      if (data == null) return Uint8List(0);
      return Uint8List.fromList(data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<MebablMediaContentStream> _openStream(
    String path, {
    String? range,
    bool authenticated = true,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await core.http.dio.get<ResponseBody>(
        path,
        cancelToken: cancelToken,
        options: _contentOptions(
          authenticated: authenticated,
          responseType: ResponseType.stream,
          headers: range == null ? null : {'Range': _validateRange(range)},
          receiveTimeout: Duration.zero,
        ),
      );

      final body = response.data;
      if (body == null) {
        throw MebablException(
          message: 'The media endpoint returned an empty stream.',
          statusCode: response.statusCode,
          requestPath: path,
        );
      }

      return MebablMediaContentStream(
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

  Options _contentOptions({
    required bool authenticated,
    required ResponseType responseType,
    Map<String, dynamic>? headers,
    Duration? receiveTimeout,
  }) {
    return Options(
      responseType: responseType,
      headers: headers,
      receiveTimeout: receiveTimeout,
      extra: {
        if (authenticated)
          MebablHttpClient.authModeExtraKey: MebablAuthMode.user,
      },
    );
  }

  /// Resolves a backend-relative original/variant/HLS URL against Core's API URL.
  ///
  /// For public or unlisted content, the resulting URL can be used directly by
  /// a player without a User JWT, provided both Media Rules and Storage Rules
  /// grant the request. Private content still requires an authenticated client.
  Uri resolveContentUrl(String contentUrl) {
    final normalized = contentUrl.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        contentUrl,
        'contentUrl',
        'A media content URL is required.',
      );
    }

    final uri = Uri.parse(normalized);
    if (!uri.hasScheme && uri.hasAuthority) {
      throw ArgumentError.value(
        contentUrl,
        'contentUrl',
        'Protocol-relative media URLs are not supported.',
      );
    }
    if (uri.hasScheme) {
      if (uri.scheme != 'http' && uri.scheme != 'https') {
        throw ArgumentError.value(
          contentUrl,
          'contentUrl',
          'Only HTTP and HTTPS media URLs are supported.',
        );
      }
      return uri;
    }

    return Uri.parse(core.config.baseUrl).resolve(normalized);
  }

  void _validateUploadSize(String fileName, int size) {
    final extension = fileName.contains('.')
        ? fileName.substring(fileName.lastIndexOf('.')).toLowerCase()
        : '';
    const imageExtensions = {'.jpg', '.jpeg', '.png', '.gif', '.webp'};
    const videoExtensions = {'.mp4', '.mov', '.webm'};

    if (imageExtensions.contains(extension)) {
      if (size > maximumImageSizeBytes) {
        throw ArgumentError('Image uploads cannot exceed 25 MB.');
      }
      return;
    }

    if (videoExtensions.contains(extension)) {
      if (size > maximumVideoSizeBytes) {
        throw ArgumentError('Video uploads cannot exceed 512 MB.');
      }
      return;
    }

    throw ArgumentError.value(
      fileName,
      'fileName',
      'Supported media extensions are .jpg, .jpeg, .png, .gif, .webp, .mp4, .mov, and .webm.',
    );
  }

  String _resolveFileName(String filePath, String? suppliedName) {
    final candidate = suppliedName?.trim().isNotEmpty == true
        ? suppliedName!.trim()
        : filePath.replaceAll('\\', '/').split('/').last;
    _validateFileName(candidate);
    return candidate;
  }

  void _validateFileName(String value) {
    if (value.trim().isEmpty ||
        value.length > 255 ||
        value.contains('/') ||
        value.contains('\\') ||
        value == '.' ||
        value == '..' ||
        value.codeUnits.any((unit) => unit < 32 || unit == 127)) {
      throw ArgumentError.value(value, 'fileName', 'The file name is invalid.');
    }
  }

  String _requireId(String value) {
    final normalized = value.trim();
    if (!_guidPattern.hasMatch(normalized) ||
        normalized.toLowerCase() == '00000000-0000-0000-0000-000000000000') {
      throw ArgumentError.value(
        value,
        'mediaId',
        'A valid media GUID is required.',
      );
    }
    return normalized;
  }

  String _requirePathSegment(String value, String fieldName) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized == '.' || normalized == '..') {
      throw ArgumentError.value(
        value,
        fieldName,
        'A valid path segment is required.',
      );
    }
    return Uri.encodeComponent(normalized);
  }

  String _encodeRelativePath(String value) {
    final normalized = value.trim().replaceAll('\\', '/');
    if (normalized.isEmpty ||
        normalized.startsWith('/') ||
        normalized.length > 512) {
      throw ArgumentError.value(
        value,
        'relativePath',
        'The HLS path is invalid.',
      );
    }

    final segments = normalized.split('/');
    if (segments.any(
      (segment) => segment.isEmpty || segment == '.' || segment == '..',
    )) {
      throw ArgumentError.value(
        value,
        'relativePath',
        'The HLS path is invalid.',
      );
    }

    return segments.map(Uri.encodeComponent).join('/');
  }

  String _validateRange(String value) {
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

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

  Map<String, dynamic> _requireMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException(
      'The media endpoint returned an invalid response.',
    );
  }

  MebablException _mapDioException(DioException error) {
    final nested = error.error;
    if (nested is MebablException) return nested;

    final data = error.response?.data;
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

  String? _extractMessage(Object? data) {
    if (data is! Map) return null;
    for (final key in const ['message', 'title', 'error']) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  String _fallbackMessage(DioException error, int? statusCode) {
    if (statusCode != null) {
      if (statusCode == 429) {
        return 'Too many requests. Please try again later.';
      }
      if (statusCode >= 500) {
        return 'The server could not complete the media request.';
      }
      return 'The media request failed with status $statusCode.';
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout => 'The connection timed out.',
      DioExceptionType.sendTimeout => 'Sending the media request timed out.',
      DioExceptionType.receiveTimeout => 'Receiving media content timed out.',
      DioExceptionType.connectionError =>
        'Could not connect to the Mebabl server.',
      DioExceptionType.cancel => 'The media request was cancelled.',
      DioExceptionType.badCertificate =>
        'The server certificate could not be trusted.',
      DioExceptionType.badResponse =>
        'The server returned an invalid media response.',
      DioExceptionType.transformTimeout =>
        'Processing the media response timed out.',
      DioExceptionType.unknown =>
        'A network or unexpected media error occurred.',
    };
  }
}
