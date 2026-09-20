import 'package:mebabl_core/mebabl_core.dart';

import 'document.dart';

class DocumentsService {
  final MebablCore core;

  DocumentsService({required this.core});

  Future<Document> create({
    required String collectionId,
    required String key,
    required Map<String, dynamic> data,
  }) async {
    _validateCollectionId(collectionId);
    _validateKey(key);

    final response = await core.http.post(
      '/api/sdk/data/collections/$collectionId/documents',
      data: {'key': key.trim(), 'data': data},
    );

    return Document.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<Document> get({
    required String collectionId,
    required String documentId,
  }) async {
    _validateCollectionId(collectionId);
    _validateDocumentId(documentId);

    final response = await core.http.get(
      '/api/sdk/data/collections/$collectionId/documents/$documentId',
    );

    return Document.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<List<Document>> list({required String collectionId}) async {
    _validateCollectionId(collectionId);

    final response = await core.http.get(
      '/api/sdk/data/collections/$collectionId/documents',
    );

    final data = response.data;

    if (data is! List) {
      throw FormatException('Documents response must be a JSON array.');
    }

    return data
        .map(
          (item) => Document.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<Document> update({
    required String collectionId,
    required String documentId,
    required String key,
    required Map<String, dynamic> data,
  }) async {
    _validateCollectionId(collectionId);
    _validateDocumentId(documentId);
    _validateKey(key);

    final response = await core.http.put(
      '/api/sdk/data/collections/$collectionId/documents/$documentId',
      data: {'key': key.trim(), 'data': data},
    );

    return Document.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> delete({
    required String collectionId,
    required String documentId,
  }) async {
    _validateCollectionId(collectionId);
    _validateDocumentId(documentId);

    await core.http.delete(
      '/api/sdk/data/collections/$collectionId/documents/$documentId',
    );
  }

  void _validateCollectionId(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError('collectionId cannot be empty.');
    }
  }

  void _validateDocumentId(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError('documentId cannot be empty.');
    }
  }

  void _validateKey(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError('Document key cannot be empty.');
    }

    if (value.trim().length > 200) {
      throw ArgumentError('Document key cannot exceed 200 characters.');
    }
  }
}
