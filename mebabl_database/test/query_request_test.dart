import 'package:flutter_test/flutter_test.dart';
import 'package:mebabl_database/mebabl_database.dart';

void main() {
  test('QueryRequest serializes query constraints without collection identity', () {
    final request = QueryRequest(
      collectionCode: 'products',
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

    expect(json.containsKey('collectionId'), isFalse);
    expect(json.containsKey('collectionCode'), isFalse);
    expect(json['offset'], 10);
    expect(json['limit'], 25);
    expect(json['search'], 'product');
    expect(json['select'], isEmpty);
    expect(json['filters'], isA<List>());
    expect(json['sorts'], isA<List>());
    expect(request.normalizedCollectionCode, 'products');
  });

  test('QueryRequest has correct defaults', () {
    const request = QueryRequest(collectionCode: 'products');

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
      collectionCode: 'products',
      select: ['name', 'price'],
    );

    expect(() => request.toJson(), throwsUnsupportedError);
  });

  test('QueryRequest enforces the backend page size limit', () {
    const request = QueryRequest(collectionCode: 'products', limit: 101);

    expect(() => request.toJson(), throwsArgumentError);
  });

  test('QueryRequest rejects collection codes with GUID-style separators', () {
    const request = QueryRequest(collectionCode: 'products-collection');

    expect(() => request.toJson(), throwsArgumentError);
  });
}
