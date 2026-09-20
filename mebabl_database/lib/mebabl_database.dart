import 'package:mebabl_core/mebabl_core.dart';

import 'src/collections/collections_service.dart';
import 'src/documents/documents_service.dart';
import 'src/query/query_service.dart';

export 'src/collections/collection.dart';
export 'src/collections/collections_service.dart';

export 'src/documents/document.dart';
export 'src/documents/documents_service.dart';

export 'src/query/query_filter.dart';
export 'src/query/query_operator.dart';
export 'src/query/query_request.dart';
export 'src/query/query_result.dart';
export 'src/query/query_service.dart';
export 'src/query/query_sort.dart';

class MebablDatabaseService {
  final MebablCore core;

  late final CollectionsService collections;
  late final DocumentsService documents;
  late final QueryService query;

  MebablDatabaseService({required this.core}) {
    collections = CollectionsService(core: core);

    documents = DocumentsService(core: core);

    query = QueryService(core: core);
  }
}
