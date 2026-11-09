import 'package:mebabl_core/mebabl_core.dart';

import 'collection.dart';

/// Accesses collections in the authenticated application's Mebabl project.
///
/// Collection ownership is project-scoped. Applications registered under the
/// same project share its collections; the authenticated application is used
/// only to establish the caller's identity and permissions.
class CollectionsService {
  static const String _basePath = '/api/sdk/data/collections';
  static const int _maximumNameLength = 100;
  static const int _maximumDescriptionLength = 500;

  static final RegExp _controlCharacters = RegExp(r'[\x00-\x1F\x7F]');

  final MebablCore core;

  CollectionsService({required this.core});

  /// Creates a collection in the authenticated project.
  ///
  /// Project and application identifiers are intentionally omitted from the
  /// payload. The backend derives the project from the authenticated token.
  Future<Collection> create({required String name, String? description}) async {
    final payload = <String, dynamic>{
      'name': _normalizeName(name),
      'description': _normalizeDescription(description),
    };

    final response = await core.http.post(_basePath, data: payload);
    return Collection.fromJson(_readObject(response.data, 'create collection'));
  }

  /// Gets a collection only if it belongs to the authenticated project.
  Future<Collection> get({required String collectionId}) async {
    final id = _normalizeId(collectionId, 'collectionId');
    final response = await core.http.get('$_basePath/$id');

    return Collection.fromJson(_readObject(response.data, 'get collection'));
  }

  /// Lists collections visible to the authenticated user in the project.
  ///
  /// The returned list is unmodifiable so callers cannot alter the collection
  /// snapshot held by the SDK service.
  Future<List<Collection>> list() async {
    final response = await core.http.get(_basePath);
    final raw = response.data;

    if (raw is! List) {
      throw const FormatException('Collections response must be a JSON array.');
    }

    final collections = raw
        .map(
          (item) =>
              Collection.fromJson(_readObject(item, 'collection list item')),
        )
        .toList(growable: false);

    return List<Collection>.unmodifiable(collections);
  }

  /// Updates collection metadata in the authenticated project.
  ///
  /// The backend derives ownership from the authenticated context; this
  /// request never sends a project or application identifier.
  Future<Collection> update({
    required String collectionId,
    required String name,
    String? description,
  }) async {
    final id = _normalizeId(collectionId, 'collectionId');
    final payload = <String, dynamic>{
      'name': _normalizeName(name),
      'description': _normalizeDescription(description),
    };

    final response = await core.http.put('$_basePath/$id', data: payload);
    return Collection.fromJson(_readObject(response.data, 'update collection'));
  }

  /// Deletes a collection belonging to the authenticated project.
  Future<void> delete({required String collectionId}) async {
    final id = _normalizeId(collectionId, 'collectionId');
    await core.http.delete('$_basePath/$id');
  }

  static String _normalizeId(String value, String parameterName) {
    final id = value.trim();
    if (id.isEmpty || _controlCharacters.hasMatch(id)) {
      throw ArgumentError.value(
        value,
        parameterName,
        'Must not be empty or contain control characters.',
      );
    }
    return id;
  }

  static String _normalizeName(String value) {
    final name = value.trim();
    if (name.isEmpty) {
      throw ArgumentError.value(value, 'name', 'Cannot be empty.');
    }
    if (name.length > _maximumNameLength || _controlCharacters.hasMatch(name)) {
      throw ArgumentError.value(
        value,
        'name',
        'Must not exceed $_maximumNameLength characters or contain control characters.',
      );
    }
    return name;
  }

  static String? _normalizeDescription(String? value) {
    final description = value?.trim();
    if (description != null &&
        (description.length > _maximumDescriptionLength ||
            _controlCharacters.hasMatch(description))) {
      throw ArgumentError.value(
        value,
        'description',
        'Must not exceed $_maximumDescriptionLength characters or contain control characters.',
      );
    }
    return description;
  }

  static Map<String, dynamic> _readObject(Object? value, String context) {
    if (value is! Map) {
      throw FormatException('$context response must be a JSON object.');
    }

    try {
      return Map<String, dynamic>.from(value);
    } on TypeError {
      throw FormatException(
        '$context response must use string property names.',
      );
    }
  }
}
