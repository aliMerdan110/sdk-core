import 'batch_write_document_operation.dart';

/// Result of one operation in a successfully committed batch.
class BatchWriteDocumentResult {
  final int index;
  final BatchWriteOperationType type;
  final String documentId;
  final int version;
  final bool isDeleted;

  const BatchWriteDocumentResult({
    required this.index,
    required this.type,
    required this.documentId,
    required this.version,
    required this.isDeleted,
  });

  factory BatchWriteDocumentResult.fromJson(Map<String, dynamic> json) {
    final index = _readInt(json['index'], 'index');
    final documentId = json['documentId'];
    final version = _readInt(json['version'], 'version');
    final isDeleted = json['isDeleted'];

    if (documentId is! String || documentId.trim().isEmpty) {
      throw const FormatException('Batch result documentId is invalid.');
    }
    if (version < 1) {
      throw const FormatException('Batch result version must be positive.');
    }
    if (isDeleted is! bool) {
      throw const FormatException('Batch result isDeleted must be a boolean.');
    }

    return BatchWriteDocumentResult(
      index: index,
      type: _readOperationType(json['type']),
      documentId: documentId,
      version: version,
      isDeleted: isDeleted,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'index': index,
    'type': type.name,
    'documentId': documentId,
    'version': version,
    'isDeleted': isDeleted,
  };

  static int _readInt(Object? value, String field) {
    if (value is! int) {
      throw FormatException('Batch result $field must be an integer.');
    }
    return value;
  }

  static BatchWriteOperationType _readOperationType(Object? value) {
    if (value is int) {
      switch (value) {
        case 1:
          return BatchWriteOperationType.create;
        case 2:
          return BatchWriteOperationType.update;
        case 3:
          return BatchWriteOperationType.delete;
      }
    }

    if (value is String) {
      switch (value.toLowerCase()) {
        case 'create':
          return BatchWriteOperationType.create;
        case 'update':
          return BatchWriteOperationType.update;
        case 'delete':
          return BatchWriteOperationType.delete;
      }
    }

    throw const FormatException('Batch result operation type is unsupported.');
  }
}
