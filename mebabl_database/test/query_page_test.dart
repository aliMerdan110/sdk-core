import 'package:flutter_test/flutter_test.dart';
import 'package:mebabl_database/mebabl_database.dart';

void main() {
  test('QueryPage parses the collection-code response contract', () {
    final page = QueryPage.fromJson({
      'collectionCode': 'products',
      'items': [
        {
          'id': '00000000-0000-0000-0000-000000000001',
          'key': 'product-1',
          'data': {'name': 'Product'},
          'version': 2,
          'createdAt': '2026-01-01T00:00:00Z',
          'updatedAt': '2026-01-02T00:00:00Z',
        }
      ],
      'hasMore': false,
      'nextPageToken': null,
      'nextOffset': null,
    });

    expect(page.collectionCode, 'products');
    expect(page.items.single.key, 'product-1');
    expect(page.items.single.version, 2);
    expect(page.hasMore, isFalse);
  });

  test('QueryPage rejects legacy collectionId response', () {
    expect(
      () => QueryPage.fromJson({
        'collectionId': '00000000-0000-0000-0000-000000000001',
        'items': [],
        'hasMore': false,
      }),
      throwsFormatException,
    );
  });
}
