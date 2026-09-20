import 'query_operator.dart';

class QueryFilter {
  final String field;
  final QueryOperator operator;
  final dynamic value;

  const QueryFilter({required this.field, required this.operator, this.value});

  Map<String, dynamic> toJson() {
    if (field.trim().isEmpty) {
      throw ArgumentError('Query filter field cannot be empty.');
    }

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
