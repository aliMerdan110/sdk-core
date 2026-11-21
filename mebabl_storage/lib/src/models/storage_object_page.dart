import 'storage_object.dart';

/// One authorized page of objects within a project bucket.
class MebablStorageObjectPage {
  final int page;
  final int pageSize;
  final bool hasMore;
  final List<MebablStorageObject> items;

  const MebablStorageObjectPage({
    required this.page,
    required this.pageSize,
    required this.hasMore,
    required this.items,
  });

  factory MebablStorageObjectPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['Items'];
    if (rawItems is! List) {
      throw const FormatException(
        'The Storage response field "items" is invalid.',
      );
    }

    return MebablStorageObjectPage(
      page: _requiredInt(json, 'page'),
      pageSize: _requiredInt(json, 'pageSize'),
      hasMore: _requiredBool(json, 'hasMore'),
      items: rawItems
          .map((item) => MebablStorageObject.fromJson(_asMap(item)))
          .toList(growable: false),
    );
  }
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key] ?? json[_pascalCase(key)];
  if (value is int) return value;
  if (value is num) return value.toInt();
  throw FormatException(
    'The Storage response field "$key" is missing or invalid.',
  );
}

bool _requiredBool(Map<String, dynamic> json, String key) {
  final value = json[key] ?? json[_pascalCase(key)];
  if (value is bool) return value;
  throw FormatException(
    'The Storage response field "$key" is missing or invalid.',
  );
}

String _pascalCase(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw const FormatException('A Storage object item is invalid.');
}
