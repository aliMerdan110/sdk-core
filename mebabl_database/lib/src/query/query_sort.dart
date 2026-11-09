enum QuerySortDirection { asc, desc }

/// Sorts a query by one of the fields supported by the current backend.
class QuerySort {
  static const supportedFields = <String>{
    'createdat',
    'updatedat',
    'key',
    'version',
  };

  final String field;
  final QuerySortDirection direction;

  const QuerySort({
    required this.field,
    this.direction = QuerySortDirection.asc,
  });

  void validate() {
    final normalized = field.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw ArgumentError('Query sort field cannot be empty.');
    }
    if (!supportedFields.contains(normalized)) {
      throw ArgumentError(
        'Unsupported sort field "$field". Supported fields: createdAt, updatedAt, key, version.',
      );
    }
  }

  Map<String, dynamic> toJson() {
    validate();
    return {'field': field.trim(), 'direction': direction.name};
  }
}
