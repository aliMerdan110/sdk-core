import 'dart:convert';

import 'package:mebabl_core/mebabl_core.dart';

import 'batch_write_document_operation.dart';
import 'batch_write_documents_response.dart';
import 'document.dart';

/// Accesses documents stored in a project-owned collection.
///
/// All operations are scoped by the authenticated project on the server.
/// [Document.version] is required for updates and deletes to prevent stale
/// clients from overwriting or removing newer data.
class DocumentsService {
  static const String _collectionsPath = '/api/sdk/data/collections';
  static const int _maximumKeyLength = 200;
  static const int maximumBatchOperations = 500;
  static const int maximumBatchPayloadBytes = 1024 * 1024;

  final MebablCore core;

  DocumentsService({required this.core});

  /// Creates a document with a caller-selected key.
  Future<Document> create({
    required String collectionId,
    required String key,
    required Map<String, dynamic> data,
  }) async {
    final collection = _normalizeId(collectionId, 'collectionId');
    final normalizedKey = _normalizeKey(key);
    _validateData(data);

    final response = await core.http.post(
      '$_collectionsPath/$collection/documents',
      data: <String, dynamic>{'key': normalizedKey, 'data': data},
    );

    return Document.fromJson(_readObject(response.data, 'create document'));
  }

  /// Gets a document by ID inside the specified collection.
  Future<Document> get({
    required String collectionId,
    required String documentId,
  }) async {
    final collection = _normalizeId(collectionId, 'collectionId');
    final document = _normalizeId(documentId, 'documentId');

    final response = await core.http.get(
      '$_collectionsPath/$collection/documents/$document',
    );

    return Document.fromJson(_readObject(response.data, 'get document'));
  }

  /// Lists documents in one collection.
  ///
  /// For large collections, prefer [QueryService] and its cursor pagination
  /// rather than loading the entire collection into memory.
  Future<List<Document>> list({required String collectionId}) async {
    final collection = _normalizeId(collectionId, 'collectionId');

    final response = await core.http.get(
      '$_collectionsPath/$collection/documents',
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

  /// Replaces a document using optimistic concurrency.
  ///
  /// The request succeeds only when [expectedVersion] equals the current
  /// document version. A successful update increments the server version.
  /// The backend returns HTTP 204, so this method does not return a document.
  Future<void> update({
    required String collectionId,
    required String documentId,
    required String key,
    required Map<String, dynamic> data,
    required int expectedVersion,
  }) async {
    final collection = _normalizeId(collectionId, 'collectionId');
    final document = _normalizeId(documentId, 'documentId');
    final normalizedKey = _normalizeKey(key);
    _validateData(data);
    _validateExpectedVersion(expectedVersion);

    await core.http.put(
      '$_collectionsPath/$collection/documents/$document',
      data: <String, dynamic>{
        'key': normalizedKey,
        'data': data,
        'expectedVersion': expectedVersion,
      },
    );
  }

  /// Soft-deletes a document only when its version still matches.
  Future<void> delete({
    required String collectionId,
    required String documentId,
    required int expectedVersion,
  }) async {
    final collection = _normalizeId(collectionId, 'collectionId');
    final document = _normalizeId(documentId, 'documentId');
    _validateExpectedVersion(expectedVersion);

    await core.http.delete(
      '$_collectionsPath/$collection/documents/$document',
      queryParameters: <String, dynamic>{'expectedVersion': expectedVersion},
    );
  }

  /// Executes create, update, and delete mutations as one atomic batch.
  ///
  /// The server commits all operations or rolls back all of them. If any
  /// operation fails validation, authorization, concurrency checks, or a
  /// database constraint, the returned Future fails and no partial result is
  /// returned. A batch is limited to 500 operations and 1 MiB of JSON data.
  Future<BatchWriteDocumentsResponse> batchWrite({
    required String collectionId,
    required List<BatchWriteDocumentOperation> operations,
  }) async {
    final collection = _normalizeId(collectionId, 'collectionId');
    _validateBatch(operations);

    final response = await core.http.post(
      '$_collectionsPath/$collection/documents/batch',
      data: <String, dynamic>{
        'operations': operations
            .map((operation) => operation.toJson())
            .toList(),
      },
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

    for (var index = 0; index < operations.length; index++) {
      final operation = operations[index];
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
    if (id.isEmpty) {
      throw ArgumentError.value(value, parameterName, 'Cannot be empty.');
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
