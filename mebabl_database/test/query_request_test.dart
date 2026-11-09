import 'package:flutter_test/flutter_test.dart';
import 'package:mebabl_database/mebabl_database.dart';

void main() {
  test('QueryRequest serializes supported query options', () {
    final request = QueryRequest(
      collectionId: 'collection-1',
      filters: [
        QueryFilter(
          field: 'category',
          operator: QueryOperator.equal,
          value: 'test',
        ),
      ],
      sorts: [
        QuerySort(field: 'createdAt', direction: QuerySortDirection.desc),
      ],
      offset: 10,
      limit: 25,
      search: 'product',
    );

    final json = request.toJson();

    expect(json['collectionId'], 'collection-1');
    expect(json['offset'], 10);
    expect(json['limit'], 25);
    expect(json['search'], 'product');
    expect(json['select'], isEmpty);
    expect(json['filters'], isA<List>());
    expect(json['sorts'], isA<List>());
  });

  test('QueryRequest has correct defaults', () {
    const request = QueryRequest(collectionId: 'collection-1');

    expect(request.offset, 0);
    expect(request.limit, 50);
    expect(request.filters, isEmpty);
    expect(request.sorts, isEmpty);
    expect(request.select, isEmpty);
    expect(request.search, isNull);
    expect(request.pageToken, isNull);
  });

  test('QueryRequest rejects unsupported field projection', () {
    const request = QueryRequest(
      collectionId: 'collection-1',
      select: ['name', 'price'],
    );

    expect(() => request.toJson(), throwsUnsupportedError);
  });

  test('QueryRequest enforces the backend page size limit', () {
    const request = QueryRequest(collectionId: 'collection-1', limit: 101);

    expect(() => request.toJson(), throwsArgumentError);
  });
}
