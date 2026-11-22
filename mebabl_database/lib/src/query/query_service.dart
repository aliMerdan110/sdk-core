import 'package:mebabl_core/mebabl_core.dart';

import '../collections/collections_service.dart';
import 'query_page.dart';
import 'query_request.dart';

/// Executes project-scoped queries using stable collection codes.
class QueryService {
  final MebablCore core;

  QueryService({required this.core});

  Future<QueryPage> execute(QueryRequest request) async {
    request.validate();
    final code = request.normalizedCollectionCode;
    final response = await core.http.post(
      '/api/sdk/data/collections/by-code/${Uri.encodeComponent(code)}/query',
      data: request.toJson(),
      authMode: MebablAuthMode.user,
    );

    final data = response.data;
    if (data is List) {
      return QueryPage.fromLegacyList(collectionCode: code, items: data);
    }
    if (data is! Map) {
      throw const FormatException('Query response must be a JSON page object.');
    }

    final page = QueryPage.fromJson(Map<String, dynamic>.from(data));
    if (page.collectionCode.toLowerCase() != code) {
      throw const FormatException(
        'Query response collectionCode does not match the requested collection.',
      );
    }
    return page;
  }

  Future<QueryPage> executeNext({
    required QueryRequest request,
    required QueryPage previousPage,
  }) {
    final code = CollectionsService.normalizeCollectionCode(request.collectionCode);
    if (code != previousPage.collectionCode.toLowerCase()) {
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
      return execute(request.copyWith(offset: nextOffset, clearPageToken: true));
    }

    throw const FormatException(
      'The query response indicates more data but contains no continuation value.',
    );
  }
}
