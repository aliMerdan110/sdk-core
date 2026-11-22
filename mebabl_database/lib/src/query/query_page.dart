import 'query_result.dart';

/// A single page returned by a code-addressed Mebabl collection query.
class QueryPage {
  final String collectionCode;
  final List<QueryResult> items;
  final bool hasMore;
  final String? nextPageToken;
  final int? nextOffset;

  QueryPage({
    required this.collectionCode,
    required List<QueryResult> items,
    required this.hasMore,
    required this.nextPageToken,
    required this.nextOffset,
  }) : items = List.unmodifiable(items) {
    if (collectionCode.trim().isEmpty) {
      throw ArgumentError.value(collectionCode, 'collectionCode');
    }
    if (nextPageToken != null && nextOffset != null) {
      throw const FormatException(
        'A query page cannot contain both nextPageToken and nextOffset.',
      );
    }
    if (hasMore && nextPageToken == null && nextOffset == null) {
      throw const FormatException(
        'A query page with hasMore=true must include a continuation value.',
      );
    }
    if (nextOffset != null && nextOffset! < 0) {
      throw const FormatException('nextOffset cannot be negative.');
    }
  }

  factory QueryPage.fromJson(Map<String, dynamic> json) {
    final rawCollectionCode = json['collectionCode'];
    final rawItems = json['items'];
    final rawHasMore = json['hasMore'];
    final rawToken = json['nextPageToken'];
    final rawNextOffset = json['nextOffset'];

    if (rawCollectionCode is! String || rawCollectionCode.trim().isEmpty) {
      throw const FormatException('Query page collectionCode is invalid.');
    }
    if (rawItems is! List) {
      throw const FormatException('Query page items must be a JSON array.');
    }
    if (rawHasMore is! bool) {
      throw const FormatException('Query page hasMore must be a boolean.');
    }
    if (rawToken != null && rawToken is! String) {
      throw const FormatException('Query page nextPageToken must be a string or null.');
    }
    if (rawNextOffset != null && rawNextOffset is! int) {
      throw const FormatException('Query page nextOffset must be an integer or null.');
    }

    final parsedItems = rawItems.map((item) {
      if (item is! Map) {
        throw const FormatException('Every query page item must be a JSON object.');
      }
      return QueryResult.fromJson(Map<String, dynamic>.from(item));
    }).toList(growable: false);

    return QueryPage(
      collectionCode: rawCollectionCode,
      items: parsedItems,
      hasMore: rawHasMore,
      nextPageToken: rawToken as String?,
      nextOffset: rawNextOffset as int?,
    );
  }

  /// Converts an older array-only response into a terminal page.
  factory QueryPage.fromLegacyList({
    required String collectionCode,
    required List<dynamic> items,
  }) {
    return QueryPage(
      collectionCode: collectionCode,
      items: items.map((item) {
        if (item is! Map) {
          throw const FormatException('Every query result must be a JSON object.');
        }
        return QueryResult.fromJson(Map<String, dynamic>.from(item));
      }).toList(growable: false),
      hasMore: false,
      nextPageToken: null,
      nextOffset: null,
    );
  }

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get length => items.length;
}
