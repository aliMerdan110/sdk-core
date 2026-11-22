import 'dart:convert';

import 'package:mebabl_core/mebabl_core.dart';

import '../collections/collections_service.dart';
import 'batch_write_document_operation.dart';
import 'batch_write_documents_response.dart';
import 'document.dart';

/// Accesses documents in project-scoped collections using stable collection
/// codes. Internal Collection GUIDs are never exposed to SDK callers.
///
/// Updates and deletes require the current document version and send it as a
/// strong ETag through `If-Match`.
class DocumentsService {
  static const int _maximumKeyLength = 200;
  static const int maximumBatchOperations = 500;
  static const int maximumBatchPayloadBytes = 1024 * 1024;

  final MebablCore core;

  DocumentsService({required this.core});

  String _collectionPath(String collectionCode) {
    final code = CollectionsService.normalizeCollectionCode(collectionCode);
    return '/api/sdk/data/collections/by-code/${Uri.encodeComponent(code)}';
  }

  /// Creates a document with a caller-selected key.
  Future<Document> create({
    required String collectionCode,
    required String key,
    required Map<String, dynamic> data,
  }) async {
    final path = _collectionPath(collectionCode);
    final normalizedKey = _normalizeKey(key);
    _validateData(data);

    final response = await core.http.post(
      '$path/documents',
      data: <String, dynamic>{'key': normalizedKey, 'data': data},
      authMode: MebablAuthMode.user,
    );

    return Document.fromJson(_readObject(response.data, 'create document'));
  }

  /// Gets a document by its backend document ID within a collection code.
  Future<Document> get({
    required String collectionCode,
    required String documentId,
  }) async {
    final path = _collectionPath(collectionCode);
    final document = _normalizeId(documentId, 'documentId');

    final response = await core.http.get(
      '$path/documents/${Uri.encodeComponent(document)}',
      authMode: MebablAuthMode.user,
    );

    return Document.fromJson(_readObject(response.data, 'get document'));
  }

  /// Lists documents in a collection allowed by the published `list` rule.
  Future<List<Document>> list({required String collectionCode}) async {
    final path = _collectionPath(collectionCode);

    final response = await core.http.get(
      '$path/documents',
      authMode: MebablAuthMode.user,
    );
    final raw = response.data;

    if (raw is! List) {
      throw const FormatException('Documents response must be a JSON array.');
    }

    return List<Document>.unmodifiable(
      raw.map(
        (item) => Document.fromJson(_readObject(item, 'document list item')),
      ),
    );
  }

  /// Replaces a document only when [expectedVersion] matches its current
  /// version. A successful update increments the server version.
  Future<void> update({
    required String collectionCode,
    required String documentId,
    required String key,
    required Map<String, dynamic> data,
    required int expectedVersion,
  }) async {
    final path = _collectionPath(collectionCode);
    final document = _normalizeId(documentId, 'documentId');
    final normalizedKey = _normalizeKey(key);
    _validateData(data);
    _validateExpectedVersion(expectedVersion);

    await core.http.put(
      '$path/documents/${Uri.encodeComponent(document)}',
      data: <String, dynamic>{'key': normalizedKey, 'data': data},
      headers: <String, dynamic>{'If-Match': '"$expectedVersion"'},
      authMode: MebablAuthMode.user,
    );
  }

  /// Soft-deletes a document only when [expectedVersion] still matches.
  Future<void> delete({
    required String collectionCode,
    required String documentId,
    required int expectedVersion,
  }) async {
    final path = _collectionPath(collectionCode);
    final document = _normalizeId(documentId, 'documentId');
    _validateExpectedVersion(expectedVersion);

    await core.http.delete(
      '$path/documents/${Uri.encodeComponent(document)}',
      headers: <String, dynamic>{'If-Match': '"$expectedVersion"'},
      authMode: MebablAuthMode.user,
    );
  }

  /// Executes create, update, and delete operations as one atomic batch.
  Future<BatchWriteDocumentsResponse> batchWrite({
    required String collectionCode,
    required List<BatchWriteDocumentOperation> operations,
  }) async {
    final path = _collectionPath(collectionCode);
    _validateBatch(operations);

    final response = await core.http.post(
      '$path/documents/batch',
      data: <String, dynamic>{
        'operations': operations
            .map((operation) => operation.toJson())
            .toList(growable: false),
      },
      authMode: MebablAuthMode.user,
    );

    return BatchWriteDocumentsResponse.fromJson(
      _readObject(response.data, 'batch write documents'),
    );
  }

  static void _validateBatch(List<BatchWriteDocumentOperation> operations) {
    if (operations.isEmpty || operations.length > maximumBatchOperations) {
      throw ArgumentError.value(
        operations.length,
        'operations.length',
        'Must contain between 1 and $maximumBatchOperations operations.',
      );
    }

    final documentIds = <String>{};
    final desiredKeys = <String>{};
    var payloadBytes = 0;

    for (final operation in operations) {
      final json = operation.toJson();

      final documentId = json['documentId'];
      if (documentId is String && !documentIds.add(documentId)) {
        throw ArgumentError(
          'Document $documentId is targeted more than once in the batch.',
        );
      }

      final key = json['key'];
      if (key is String && !desiredKeys.add(key)) {
        throw ArgumentError('The batch contains duplicate target key "$key".');
      }

      final data = json['data'];
      if (data is Map<String, dynamic>) {
        payloadBytes += utf8.encode(jsonEncode(data)).length;
        if (payloadBytes > maximumBatchPayloadBytes) {
          throw ArgumentError(
            'Aggregate batch data cannot exceed $maximumBatchPayloadBytes UTF-8 bytes.',
          );
        }
      }
    }
  }

  static String _normalizeId(String value, String parameterName) {
    final id = value.trim();
    if (id.isEmpty || id.contains(RegExp(r'[\x00-\x1F\x7F]'))) {
      throw ArgumentError.value(
        value,
        parameterName,
        'Must not be empty or contain control characters.',
      );
    }
    return id;
  }

  static String _normalizeKey(String value) {
    final key = value.trim();
    if (key.isEmpty) {
      throw ArgumentError.value(value, 'key', 'Cannot be empty.');
    }
    if (key.length > _maximumKeyLength ||
        key.contains(RegExp(r'[\x00-\x1F\x7F]'))) {
      throw ArgumentError.value(
        value,
        'key',
        'Must not exceed $_maximumKeyLength characters or contain control characters.',
      );
    }
    return key;
  }

  static void _validateData(Map<String, dynamic> data) {
    try {
      final encoded = jsonEncode(data);
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Document data must be a JSON object.');
      }
    } on JsonUnsupportedObjectError catch (error) {
      throw FormatException('Document data is not JSON serializable: $error');
    } on FormatException {
      rethrow;
    }
  }

  static void _validateExpectedVersion(int value) {
    if (value < 1) {
      throw ArgumentError.value(
        value,
        'expectedVersion',
        'Must be a positive integer.',
      );
    }
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
