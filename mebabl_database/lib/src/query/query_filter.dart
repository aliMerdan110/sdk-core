import 'query_operator.dart';

/// A scalar JSON filter applied to a document field.
class QueryFilter {
  final String field;
  final QueryOperator operator;
  final Object? value;

  const QueryFilter({
    required this.field,
    required this.operator,
    required this.value,
  });

  void validate() {
    final normalizedField = field.trim();
    if (normalizedField.isEmpty ||
        normalizedField.length > 128 ||
        normalizedField.contains(RegExp(r'[\x00-\x1F]'))) {
      throw ArgumentError('Query filter field is invalid.');
    }

    // Copy the nullable property to a local variable so Dart's flow analysis
    // can promote it safely after the type checks below.
    final filterValue = value;

    if (filterValue != null &&
        filterValue is! String &&
        filterValue is! num &&
        filterValue is! bool) {
      throw ArgumentError('Query filter values must be scalar JSON values.');
    }

    if (filterValue is double && !filterValue.isFinite) {
      throw ArgumentError('Query filter numeric values must be finite.');
    }

    switch (operator) {
      case QueryOperator.greaterThan:
      case QueryOperator.greaterThanOrEqual:
      case QueryOperator.lessThan:
      case QueryOperator.lessThanOrEqual:
        if (filterValue is! num) {
          throw ArgumentError('Comparison operators require a numeric value.');
        }
        break;

      case QueryOperator.contains:
      case QueryOperator.startsWith:
      case QueryOperator.endsWith:
        if (filterValue is! String) {
          throw ArgumentError('String operators require a string value.');
        }

        final normalizedValue = filterValue.trim();
        if (normalizedValue.isEmpty || normalizedValue.length > 256) {
          throw ArgumentError('String operators require 1 to 256 characters.');
        }
        break;

      case QueryOperator.equal:
      case QueryOperator.notEqual:
        break;
    }
  }

  Map<String, dynamic> toJson() {
    validate();
    return {
      'field': field.trim(),
      'operator': _operatorToApiValue(operator),
      'value': value,
    };
  }

  String _operatorToApiValue(QueryOperator value) {
    switch (value) {
      case QueryOperator.equal:
        return 'Equal';
      case QueryOperator.notEqual:
        return 'NotEqual';
      case QueryOperator.greaterThan:
        return 'GreaterThan';
      case QueryOperator.greaterThanOrEqual:
        return 'GreaterThanOrEqual';
      case QueryOperator.lessThan:
        return 'LessThan';
      case QueryOperator.lessThanOrEqual:
        return 'LessThanOrEqual';
      case QueryOperator.contains:
        return 'Contains';
      case QueryOperator.startsWith:
        return 'StartsWith';
      case QueryOperator.endsWith:
        return 'EndsWith';
    }
  }
}
