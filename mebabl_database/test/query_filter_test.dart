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

  test('all query operators serialize with supported value types', () {
    final cases = <QueryOperator, Object>{
      QueryOperator.equal: 'test',
      QueryOperator.notEqual: 100,
      QueryOperator.greaterThan: 100,
      QueryOperator.greaterThanOrEqual: 100,
      QueryOperator.lessThan: 100,
      QueryOperator.lessThanOrEqual: 100,
      QueryOperator.contains: 'test',
      QueryOperator.startsWith: 'test',
      QueryOperator.endsWith: 'test',
    };

    for (final entry in cases.entries) {
      final filter = QueryFilter(
        field: 'value',
        operator: entry.key,
        value: entry.value,
      );

      final json = filter.toJson();

      expect(json['operator'], isA<String>());
      expect(json['operator'], isNotEmpty);
      expect(json['value'], entry.value);
    }
  });

  test('string operators reject numeric values', () {
    for (final operator in <QueryOperator>[
      QueryOperator.contains,
      QueryOperator.startsWith,
      QueryOperator.endsWith,
    ]) {
      final filter = QueryFilter(field: 'name', operator: operator, value: 100);

      expect(() => filter.toJson(), throwsArgumentError);
    }
  });

  test('comparison operators reject non-numeric values', () {
    for (final operator in <QueryOperator>[
      QueryOperator.greaterThan,
      QueryOperator.greaterThanOrEqual,
      QueryOperator.lessThan,
      QueryOperator.lessThanOrEqual,
    ]) {
      final filter = QueryFilter(
        field: 'price',
        operator: operator,
        value: '100',
      );

      expect(() => filter.toJson(), throwsArgumentError);
    }
  });

  test('QueryFilter rejects non-finite numeric values', () {
    final filter = QueryFilter(
      field: 'price',
      operator: QueryOperator.equal,
      value: double.infinity,
    );

    expect(() => filter.toJson(), throwsArgumentError);
  });
}
