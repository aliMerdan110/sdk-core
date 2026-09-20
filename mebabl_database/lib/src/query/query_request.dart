import 'query_filter.dart';
import 'query_sort.dart';

class QueryRequest {
  final String collectionId;
  final List<QueryFilter> filters;
  final List<QuerySort> sorts;
  final int offset;
  final int limit;
  final String? search;
  final List<String> select;

  const QueryRequest({
    required this.collectionId,
    this.filters = const [],
    this.sorts = const [],
    this.offset = 0,
    this.limit = 50,
    this.search,
    this.select = const [],
  });

  Map<String, dynamic> toJson() {
    if (collectionId.trim().isEmpty) {
      throw ArgumentError('collectionId cannot be empty.');
    }

    if (offset < 0) {
      throw ArgumentError('offset cannot be negative.');
    }

    if (limit < 1 || limit > 200) {
      throw ArgumentError('limit must be between 1 and 200.');
    }

    return {
      'collectionId': collectionId.trim(),
      'filters': filters.map((e) => e.toJson()).toList(),
      'sorts': sorts.map((e) => e.toJson()).toList(),
      'offset': offset,
      'limit': limit,
      'search': search?.trim(),
      'select': select.map((e) => e.trim()).toList(),
    };
  }
}
