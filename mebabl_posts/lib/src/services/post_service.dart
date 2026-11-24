import 'package:dio/dio.dart';
import 'package:mebabl_core/mebabl_core.dart';

import '../models/post.dart';
import '../models/post_create_request.dart';
import '../models/post_visibility.dart';

final RegExp _guidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Post operations for an authenticated Mebabl application user.
///
/// This service reuses [MebablCore]'s HTTP client and User JWT interceptor.
/// It has no direct dependency on `mebabl_media` or `mebabl_storage`: callers
/// pass MediaAsset or StoredFile IDs produced by those independent services.
class MebablPostService {
  static const String basePath = '/api/sdk/content/posts';
  static const int maximumTextLength = 10000;
  static const int maximumPageSize = 100;

  final MebablCore core;

  const MebablPostService({required this.core});

  /// Creates a post containing text, attachments, or both.
  ///
  /// Use [mediaAssetIds] for image/video assets created by `mebabl_media`.
  /// Use [storageFileIds] for StoredFile attachments created by `mebabl_storage`
  /// or retained from older integrations. If both are provided, the backend
  /// places StoredFile attachments before MediaAsset attachments.
  Future<MebablPost> create({
    String? text,
    Iterable<String> storageFileIds = const [],
    Iterable<String> mediaAssetIds = const [],
    String visibility = MebablPostVisibility.public,
    CancelToken? cancelToken,
  }) async {
    final normalizedText = _normalizeText(text);
    final request = MebablPostCreateRequest(
      text: normalizedText,
      storageFileIds: storageFileIds,
      mediaAssetIds: mediaAssetIds,
      visibility: MebablPostVisibility.validate(visibility),
    );

    if ((normalizedText == null) &&
        request.storageFileIds.isEmpty &&
        request.mediaAssetIds.isEmpty) {
      throw ArgumentError(
        'A post must contain text or at least one attachment.',
      );
    }

    final response = await core.http.post<Map<String, dynamic>>(
      basePath,
      data: request.toJson(),
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );

    return MebablPost.fromJson(_requireMap(response.data));
  }

  /// Gets one post by its ID.
  Future<MebablPost> get({
    required String postId,
    CancelToken? cancelToken,
  }) async {
    final id = _requireId(postId);
    final response = await core.http.get<Map<String, dynamic>>(
      '$basePath/$id',
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );

    return MebablPost.fromJson(_requireMap(response.data));
  }

  /// Gets one page of posts.
  ///
  /// The current backend returns a JSON array, not a pagination envelope.
  /// Page size is clamped by the backend to the range 1..100; this SDK
  /// validates the same range and returns only the records in this page.
  Future<List<MebablPost>> list({
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async {
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

    final response = await core.http.get<List<dynamic>>(
      basePath,
      queryParameters: {'page': page, 'pageSize': pageSize},
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );

    final rawPosts = response.data;
    if (rawPosts == null) {
      throw const FormatException(
        'The posts endpoint returned an empty response.',
      );
    }

    return rawPosts
        .map((item) => MebablPost.fromJson(_requireMap(item)))
        .toList(growable: false);
  }

  /// Updates the text of an existing post.
  ///
  /// The current API does not add, remove, or reorder attachments during an
  /// update. Passing null or blank text is permitted only when the post still
  /// has at least one attachment; the backend enforces that rule.
  Future<MebablPost> updateText({
    required String postId,
    required String? text,
    String? visibility,
    CancelToken? cancelToken,
  }) async {
    final id = _requireId(postId);
    final normalizedText = _normalizeText(text);

    final response = await core.http.put<Map<String, dynamic>>(
      '$basePath/$id',
      data: {
        'text': normalizedText,
        if (visibility != null)
          'visibility': MebablPostVisibility.validate(visibility),
      },
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );

    return MebablPost.fromJson(_requireMap(response.data));
  }

  /// Deletes a post.
  ///
  /// The backend performs a soft delete and allows deletion only by the post
  /// owner with the `posts.delete` permission.
  Future<void> delete({
    required String postId,
    CancelToken? cancelToken,
  }) async {
    final id = _requireId(postId);
    await core.http.delete<void>(
      '$basePath/$id',
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
  }

  /// Resolves a relative attachment URL using this application's API base URL.
  Uri resolveAttachmentUrl(String attachmentUrl) {
    final normalized = attachmentUrl.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        attachmentUrl,
        'attachmentUrl',
        'An attachment URL is required.',
      );
    }

    final uri = Uri.parse(normalized);
    if (uri.hasScheme) return uri;
    return Uri.parse(core.config.baseUrl).resolve(normalized);
  }

  String? _normalizeText(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim();
    if (normalized.length > maximumTextLength) {
      throw ArgumentError.value(
        value,
        'text',
        'Post text cannot exceed $maximumTextLength characters.',
      );
    }
    return normalized;
  }

  String _requireId(String value) {
    final normalized = value.trim();
    if (!_guidPattern.hasMatch(normalized) ||
        normalized.toLowerCase() == '00000000-0000-0000-0000-000000000000') {
      throw ArgumentError.value(
        value,
        'postId',
        'A valid post GUID is required.',
      );
    }
    return normalized;
  }

  Map<String, dynamic> _requireMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException(
      'The posts endpoint returned an invalid response.',
    );
  }
}
