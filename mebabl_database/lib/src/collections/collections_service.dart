import 'package:mebabl_core/mebabl_core.dart';

import 'collection.dart';

/// Discovers collections visible to the authenticated user in the project.
///
/// Collections are project-scoped and are materialized by the backend after
/// the first successful document write. SDK clients never create or address
/// collections using internal GUIDs.
class CollectionsService {
  static const String _catalogPath = '/api/sdk/data/collections/by-code';

  final MebablCore core;

  CollectionsService({required this.core});

  /// Lists materialized collections visible under the active Database Rules.
  ///
  /// A collection must have a published policy that grants collection
  /// discovery to the current user. Owner-only collections are intentionally
  /// not enumerated by this project-wide catalog endpoint.
  Future<List<Collection>> list() async {
    final response = await core.http.get(
      _catalogPath,
      authMode: MebablAuthMode.user,
    );

    final raw = response.data;
    if (raw is! List) {
      throw const FormatException('Collections response must be a JSON array.');
    }

    final collections = raw
        .map((item) => Collection.fromJson(_readObject(item, 'collection item')))
        .toList(growable: false);

    final seenCodes = <String>{};
    for (final collection in collections) {
      final normalized = normalizeCollectionCode(collection.code);
      if (!seenCodes.add(normalized)) {
        throw FormatException(
          'Collections response contains duplicate code "$normalized".',
        );
      }
    }

    return List<Collection>.unmodifiable(collections);
  }

  /// Gets a materialized collection by its stable code when the current user
  /// is allowed to discover it through the published collection rules.
  ///
  /// Owner-only collections are intentionally omitted from the global
  /// catalog; use their known [code] directly with documents or query APIs.
  Future<Collection> get({required String code}) async {
    final normalizedCode = normalizeCollectionCode(code);
    final collections = await list();

    for (final collection in collections) {
      if (normalizeCollectionCode(collection.code) == normalizedCode) {
        return collection;
      }
    }

    throw StateError(
      'Collection "$normalizedCode" was not found in the visible project catalog.',
    );
  }

  /// Validates and normalizes a public collection code.
  ///
  /// Codes are case-insensitive, start with a letter or number, and contain
  /// only letters, numbers, and underscores.
  static String normalizeCollectionCode(String value) {
    final code = value.trim().toLowerCase();
    if (code.isEmpty ||
        code.length > 100 ||
        !RegExp(r'^[a-z0-9][a-z0-9_]*$').hasMatch(code)) {
      throw ArgumentError.value(
        value,
        'code',
        'Must start with a letter or number and contain only letters, numbers, or underscores (maximum 100 characters).',
      );
    }
    return code;
  }

  static Map<String, dynamic> _readObject(Object? value, String context) {
    if (value is! Map) {
      throw FormatException('$context response must be a JSON object.');
    }

    try {
      return Map<String, dynamic>.from(value);
    } on TypeError {
      throw FormatException('$context response must use string property names.');
    }
  }
}
