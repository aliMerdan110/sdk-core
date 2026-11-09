import 'package:mebabl_core/mebabl_core.dart';

import 'query_page.dart';
import 'query_request.dart';

/// Executes project-scoped database queries and follows their page cursors.
class QueryService {
  final MebablCore core;

  QueryService({required this.core});

  /// Executes the first page or the page identified by [request.pageToken].
  Future<QueryPage> execute(QueryRequest request) async {
    final response = await core.http.post(
      '/api/sdk/data/query',
      data: request.toJson(),
    );

    final data = response.data;
    if (data is List) {
      // Compatibility with older backend deployments that returned a bare array.
      return QueryPage.fromLegacyList(
        collectionId: request.collectionId,
        items: data,
      );
    }
    if (data is! Map) {
      throw const FormatException('Query response must be a JSON page object.');
    }

    return QueryPage.fromJson(Map<String, dynamic>.from(data));
  }

  /// Fetches the next page while preserving the original query constraints.
  /// Cursor pagination is used for the default order; custom sorts continue
  /// through the backend's nextOffset compatibility path.
  Future<QueryPage> executeNext({
    required QueryRequest request,
    required QueryPage previousPage,
  }) {
    if (request.collectionId != previousPage.collectionId) {
      throw ArgumentError(
        'The page does not belong to the requested collection.',
      );
    }
    if (!previousPage.hasMore) {
      throw StateError('There are no more query pages to fetch.');
    }

    final token = previousPage.nextPageToken;
    if (token != null) {
      return execute(request.copyWith(offset: 0, pageToken: token));
    }

    final nextOffset = previousPage.nextOffset;
    if (nextOffset != null) {
      return execute(
        request.copyWith(offset: nextOffset, clearPageToken: true),
      );
    }

    throw const FormatException(
      'The query response indicates more data but contains no continuation value.',
    );
  }
}
