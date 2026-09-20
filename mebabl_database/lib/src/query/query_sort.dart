enum QuerySortDirection { asc, desc }

class QuerySort {
  final String field;
  final QuerySortDirection direction;

  const QuerySort({
    required this.field,
    this.direction = QuerySortDirection.asc,
  });

  Map<String, dynamic> toJson() {
    if (field.trim().isEmpty) {
      throw ArgumentError('Query sort field cannot be empty.');
    }

    return {'field': field.trim(), 'direction': direction.name};
  }
}
