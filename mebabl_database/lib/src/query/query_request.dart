import 'query_filter.dart';
import 'query_sort.dart';

/// Query options for one collection in the authenticated Mebabl project.
///
/// The project/application/user scope is derived by the backend from the
/// authenticated token and must never be supplied by this request.
class QueryRequest {
  static const int defaultPageSize = 50;
  static const int maximumPageSize = 100;
  static const int maximumOffset = 100000;
  static const int maximumFilters = 20;
  static const int maximumSorts = 5;
  static const int maximumSearchLength = 200;
  static const int maximumPageTokenLength = 4096;

  final String collectionId;
  final List<QueryFilter> filters;
  final List<QuerySort> sorts;
  final int offset;
  final int limit;
  final String? search;

  /// Reserved by the API contract. Field projection is not enabled by the
  /// current backend query response contract, so non-empty values are rejected.
  final List<String> select;

  /// Opaque continuation cursor returned by [QueryPage.nextPageToken].
  final String? pageToken;

  const QueryRequest({
    required this.collectionId,
    this.filters = const [],
    this.sorts = const [],
    this.offset = 0,
    this.limit = defaultPageSize,
    this.search,
    this.select = const [],
    this.pageToken,
  });

  QueryRequest copyWith({
    String? collectionId,
    List<QueryFilter>? filters,
    List<QuerySort>? sorts,
    int? offset,
    int? limit,
    String? search,
    List<String>? select,
    String? pageToken,
    bool clearPageToken = false,
  }) {
    return QueryRequest(
      collectionId: collectionId ?? this.collectionId,
      filters: filters ?? this.filters,
      sorts: sorts ?? this.sorts,
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
      search: search ?? this.search,
      select: select ?? this.select,
      pageToken: clearPageToken ? null : (pageToken ?? this.pageToken),
    );
  }

  Map<String, dynamic> toJson() {
    validate();

    return {
      'collectionId': collectionId.trim(),
      'filters': filters
          .map((filter) => filter.toJson())
          .toList(growable: false),
      'sorts': sorts.map((sort) => sort.toJson()).toList(growable: false),
      'offset': offset,
      'limit': limit,
      'search': search?.trim(),
      'select': select,
      if (pageToken != null) 'pageToken': pageToken,
    };
  }

  void validate() {
    if (collectionId.trim().isEmpty) {
      throw ArgumentError('collectionId cannot be empty.');
    }
    if (offset < 0 || offset > maximumOffset) {
      throw ArgumentError.value(
        offset,
        'offset',
        'Must be between 0 and $maximumOffset.',
      );
    }
    if (limit < 1 || limit > maximumPageSize) {
      throw ArgumentError.value(
        limit,
        'limit',
        'Must be between 1 and $maximumPageSize.',
      );
    }
    if (filters.length > maximumFilters) {
      throw ArgumentError(
        'A query cannot contain more than $maximumFilters filters.',
      );
    }
    if (sorts.length > maximumSorts) {
      throw ArgumentError(
        'A query cannot contain more than $maximumSorts sort fields.',
      );
    }
    if (search != null && search!.trim().length > maximumSearchLength) {
      throw ArgumentError(
        'search cannot exceed $maximumSearchLength characters.',
      );
    }
    if (select.isNotEmpty) {
      throw UnsupportedError(
        'Field projection is not supported by the current query response contract.',
      );
    }
    if (pageToken != null) {
      if (pageToken!.trim().isEmpty) {
        throw ArgumentError('pageToken cannot be empty.');
      }
      if (pageToken!.length > maximumPageTokenLength) {
        throw ArgumentError(
          'pageToken cannot exceed $maximumPageTokenLength characters.',
        );
      }
      if (offset != 0 || sorts.isNotEmpty) {
        throw ArgumentError(
          'pageToken requires offset=0 and the default sort.',
        );
      }
    }

    // Validate every nested value before the request reaches Dio.
    for (final filter in filters) {
      filter.validate();
    }
    for (final sort in sorts) {
      sort.validate();
    }
  }
}
