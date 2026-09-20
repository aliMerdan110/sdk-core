import 'package:flutter_test/flutter_test.dart';
import 'package:mebabl_database/mebabl_database.dart';

void main() {
  test('QueryFilter serializes correctly', () {
    final filter = QueryFilter(
      field: 'category',
      operator: QueryOperator.equal,
      value: 'test',
    );

    final json = filter.toJson();

    expect(json['field'], 'category');
    expect(json['operator'], 'Equal');
    expect(json['value'], 'test');
  });

  test('all query operators serialize correctly', () {
    for (final operator in QueryOperator.values) {
      final filter = QueryFilter(
        field: 'price',
        operator: operator,
        value: 100,
      );

      final json = filter.toJson();

      expect(json['operator'], isA<String>());
      expect(json['operator'], isNotEmpty);
    }
  });
}
