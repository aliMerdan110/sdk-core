import 'batch_write_document_result.dart';

/// Response returned only after the server commits the entire atomic batch.
class BatchWriteDocumentsResponse {
  final String collectionCode;
  final List<BatchWriteDocumentResult> results;

  const BatchWriteDocumentsResponse({
    required this.collectionCode,
    required this.results,
  });

  factory BatchWriteDocumentsResponse.fromJson(Map<String, dynamic> json) {
    final collectionCode = json['collectionCode'];
    final rawResults = json['results'];

    if (collectionCode is! String || collectionCode.trim().isEmpty) {
      throw const FormatException('Batch response collectionCode is invalid.');
    }
    if (rawResults is! List) {
      throw const FormatException('Batch response results must be an array.');
    }

    final results = rawResults.map((item) {
      if (item is! Map) {
        throw const FormatException('Each batch result must be an object.');
      }
      try {
        return BatchWriteDocumentResult.fromJson(Map<String, dynamic>.from(item));
      } on TypeError {
        throw const FormatException('Batch result property names must be strings.');
      }
    }).toList(growable: false);

    for (var i = 0; i < results.length; i++) {
      if (results[i].index != i) {
        throw const FormatException(
          'Batch results must preserve the original operation order.',
        );
      }
    }

    return BatchWriteDocumentsResponse(
      collectionCode: collectionCode,
      results: List<BatchWriteDocumentResult>.unmodifiable(results),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'collectionCode': collectionCode,
        'results': results.map((result) => result.toJson()).toList(),
      };
}
