import 'media_asset.dart';

/// One page of the authenticated application's media library.
class MebablMediaLibraryPage {
  final int page;
  final int pageSize;
  final int totalCount;
  final List<MebablMediaAsset> items;

  const MebablMediaLibraryPage({
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.items,
  });

  int get totalPages =>
      totalCount == 0 || pageSize <= 0 ? 0 : (totalCount / pageSize).ceil();

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;

  factory MebablMediaLibraryPage.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    if (itemsJson is! List) {
      throw const FormatException(
        'The media response field "items" is invalid.',
      );
    }

    return MebablMediaLibraryPage(
      page: _requiredInt(json, 'page'),
      pageSize: _requiredInt(json, 'pageSize'),
      totalCount: _requiredInt(json, 'totalCount'),
      items: itemsJson
          .map((item) => MebablMediaAsset.fromJson(_asMap(item)))
          .toList(growable: false),
    );
  }
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  throw FormatException(
    'The media response field "$key" is missing or invalid.',
  );
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw const FormatException('A media library item is invalid.');
}
