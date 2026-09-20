import 'package:mebabl_core/mebabl_core.dart';

import 'query_request.dart';
import 'query_result.dart';

class QueryService {
  final MebablCore core;

  QueryService({required this.core});

  Future<List<QueryResult>> execute(QueryRequest request) async {
    if (request.collectionId.trim().isEmpty) {
      throw ArgumentError('collectionId cannot be empty.');
    }

    if (request.offset < 0) {
      throw ArgumentError('offset cannot be negative.');
    }

    if (request.limit < 1 || request.limit > 200) {
      throw ArgumentError('limit must be between 1 and 200.');
    }

    final response = await core.http.post(
      '/api/sdk/data/query',
      data: request.toJson(),
    );

    final data = response.data;

    if (data is! List) {
      throw FormatException('Query response must be a JSON array.');
    }

    return data
        .map(
          (item) =>
              QueryResult.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }
}
