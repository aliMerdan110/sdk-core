import 'package:flutter_test/flutter_test.dart';
import 'package:mebabl_database/mebabl_database.dart';

void main() {
  group('QueryResult', () {
    test('parses valid JSON', () {
      final result = QueryResult.fromJson({
        'id': 'doc-1',
        'key': 'product-1',
        'data': {'name': 'Test Product', 'price': 100},
        'version': 2,
        'createdAt': '2026-01-01T00:00:00Z',
        'updatedAt': '2026-01-02T00:00:00Z',
      });

      expect(result.id, 'doc-1');
      expect(result.key, 'product-1');
      expect(result.data['name'], 'Test Product');
      expect(result.data['price'], 100);
      expect(result.version, 2);
      expect(result.updatedAt, isNotNull);
    });

    test('supports null updatedAt', () {
      final result = QueryResult.fromJson({
        'id': 'doc-1',
        'key': 'product-1',
        'data': {},
        'version': 1,
        'createdAt': '2026-01-01T00:00:00Z',
        'updatedAt': null,
      });

      expect(result.updatedAt, isNull);
    });

    test('rejects invalid data', () {
      expect(
        () => QueryResult.fromJson({
          'id': 'doc-1',
          'key': 'product-1',
          'data': 'invalid',
          'version': 1,
          'createdAt': '2026-01-01T00:00:00Z',
          'updatedAt': null,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
